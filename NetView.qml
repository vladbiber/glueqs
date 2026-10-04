import Quickshell
import QtQuick
import "ListSync.js" as ListSync

// Wifi and bluetooth: quick switches, the current connection, the networks
// around and the bluetooth devices. Used by the bar popup and the NETWORK
// settings page; the state lives in NetStatus so both show the same thing.
Column {
    id: root
    property bool active: false
    property bool wide: false
    width: parent ? parent.width : 380
    spacing: 14

    property bool held: false
    function hold(on) {
        if (on && !held) { NetStatus.acquire(); held = true; }
        else if (!on && held) { NetStatus.release(); held = false; }
    }
    onActiveChanged: hold(active)
    Component.onCompleted: hold(active)
    Component.onDestruction: hold(false)

    ListModel { id: netModel }
    ListModel { id: btModel }
    readonly property var nets: NetStatus.nets
    readonly property var devs: NetStatus.btDevs
    onNetsChanged: ListSync.sync(netModel, NetStatus.wifiEnabled ? nets : [], "ssid")
    onDevsChanged: ListSync.sync(btModel, NetStatus.btPowered ? devs : [], "mac")
    Connections {
        target: NetStatus
        function onWifiEnabledChanged() { ListSync.sync(netModel, NetStatus.wifiEnabled ? root.nets : [], "ssid") }
        function onBtPoweredChanged() { ListSync.sync(btModel, NetStatus.btPowered ? root.devs : [], "mac") }
    }

    component Label: Text { color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
    component Chip: Rectangle {
        property string text: ""
        property bool hot: false
        implicitWidth: ct.implicitWidth + 10; implicitHeight: 16; radius: 5
        color: hot ? Qt.alpha(Theme.red, 0.16) : "transparent"
        border.color: hot ? Qt.alpha(Theme.red, 0.6) : Theme.blockBorder
        Text { id: ct; anchors.centerIn: parent; text: parent.text; color: parent.hot ? Theme.red : Theme.muted
               font.family: Theme.uiFont; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 0.5 }
    }
    component SectionHead: Item {
        id: sh
        property string title: ""
        property string note: ""
        property bool spinning: false
        property bool canScan: true
        signal scan()
        width: root.width; height: 24
        DotText { id: st; anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                  text: sh.title; px: 1.3; gap: 1; color: Theme.red }
        Label { anchors { left: st.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: sh.note }
        Rectangle {
            visible: sh.canScan
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: scanRow.implicitWidth + 18; height: 24; radius: 12
            color: sma.containsMouse ? Theme.hover : "transparent"
            border.color: sh.spinning ? Theme.red : Theme.blockBorder
            Row {
                id: scanRow
                anchors.centerIn: parent
                spacing: 6
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "refresh"; px: 0.9; gap: 0.6
                    color: sh.spinning ? Theme.red : Theme.fg
                    RotationAnimation on rotation { running: sh.spinning; from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        onRunningChanged: if (!running) parent.rotation = 0 }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: sh.spinning ? "SCANNING" : "SCAN"
                       color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 0.6 }
            }
            MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sh.scan() }
        }
    }
    // three dots chasing each other, for anything in progress
    component Busy: Row {
        spacing: 3
        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                width: 5; height: 5; radius: 2.5; color: Theme.red
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: true
                    PauseAnimation { duration: index * 140 }
                    NumberAnimation { from: 0.2; to: 1; duration: 280 }
                    NumberAnimation { from: 1; to: 0.2; duration: 280 }
                    PauseAnimation { duration: (2 - index) * 140 }
                }
            }
        }
    }
    // a row slides and fades in the first time it shows up
    component Appear: Item {
        id: ap
        opacity: 0
        transform: Translate { id: tr; x: 18 }
        Component.onCompleted: { inA.restart(); }
        ParallelAnimation {
            id: inA
            NumberAnimation { target: ap; property: "opacity"; to: 1; duration: Theme.ms(300); easing.type: Easing.OutCubic }
            NumberAnimation { target: tr; property: "x"; to: 0; duration: Theme.ms(380); easing.type: Easing.OutCubic }
        }
    }

    // ---------- quick switches ----------
    Row {
        id: tiles
        width: root.width
        spacing: 8
        readonly property real w: (width - spacing * 2) / 3
        QuickTile {
            width: tiles.w
            icon: NetStatus.wifiConnected ? (NetStatus.wifiSignal > 66 ? "wifi3" : NetStatus.wifiSignal > 33 ? "wifi2" : "wifi1") : "wifi3"
            label: "WIFI"
            on: NetStatus.wifiEnabled
            busy: NetStatus.busySsid !== ""
            sub: !NetStatus.wifiEnabled ? "off" : NetStatus.wifiConnected ? NetStatus.ssid : "not connected"
            onClicked: NetStatus.setWifi(!NetStatus.wifiEnabled)
        }
        QuickTile {
            width: tiles.w
            icon: "bt"
            label: "BLUETOOTH"
            on: NetStatus.btPowered
            busy: NetStatus.btBusy !== ""
            sub: !NetStatus.btPowered ? "off" : NetStatus.btConnected > 0 ? NetStatus.btConnected + " connected" : "on"
            onClicked: NetStatus.setBt(!NetStatus.btPowered)
        }
        QuickTile {
            width: tiles.w
            icon: "plane"
            label: "AIRPLANE"
            on: NetStatus.airplane
            sub: NetStatus.airplane ? "radios off" : "radios on"
            onClicked: NetStatus.setAirplane(!NetStatus.airplane)
        }
    }

    // ---------- current connection ----------
    Rectangle {
        id: hero
        width: root.width
        height: Math.max(124, heroCol.implicitHeight + 28)
        radius: Theme.cardRadius + 2
        color: Theme.card
        border.color: NetStatus.wifiConnected ? Qt.alpha(Theme.red, 0.55) : Theme.blockBorder
        clip: true
        Behavior on border.color { ColorAnimation { duration: Theme.ms(300) } }

        // a soft accent glow behind the mark while connected
        Rectangle {
            anchors.centerIn: radar
            width: Math.min(radar.width, hero.height - 16); height: width; radius: width / 2
            color: Theme.red
            opacity: NetStatus.wifiConnected ? 0.10 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(400) } }
        }
        Radar {
            id: radar
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            level: !NetStatus.wifiConnected ? 0 : NetStatus.wifiSignal > 75 ? 4 : NetStatus.wifiSignal > 50 ? 3 : NetStatus.wifiSignal > 25 ? 2 : 1
            off: !NetStatus.wifiEnabled
            pulsing: root.active && NetStatus.wifiEnabled && (!NetStatus.wifiConnected || NetStatus.busySsid !== "" || NetStatus.wifiScanning)
        }
        Column {
            id: heroCol
            anchors { left: radar.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 8
            Row {
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7; height: 7; radius: 3.5
                    color: NetStatus.wifiConnected ? Theme.red : Theme.faint
                    SequentialAnimation on opacity {
                        running: NetStatus.wifiConnected && root.active; loops: Animation.Infinite
                        onRunningChanged: if (!running) parent.opacity = 1
                        NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !NetStatus.wifiEnabled ? "WIFI IS OFF"
                        : NetStatus.busySsid !== "" ? "CONNECTING"
                        : NetStatus.wifiConnected ? "CONNECTED" : "NOT CONNECTED"
                    font.letterSpacing: 1; font.weight: Font.DemiBold
                    color: NetStatus.wifiConnected ? Theme.fg : Theme.muted
                }
            }
            DotText {
                text: (NetStatus.busySsid !== "" ? NetStatus.busySsid
                       : NetStatus.wifiConnected ? NetStatus.ssid
                       : NetStatus.wifiEnabled && NetStatus.wifiScanning ? "SEARCHING"
                       : NetStatus.wifiEnabled ? "NO CONNECTION" : "OFFLINE").toUpperCase()
                maxWidth: parent.width
                px: root.wide ? 2.6 : 2; gap: 1
            }
            Flow {
                width: parent.width
                spacing: 5
                visible: NetStatus.wifiConnected
                Chip { text: NetStatus.wifiSignal + "%"; hot: true }
                Chip { visible: NetStatus.band !== ""; text: NetStatus.band }
                Chip { visible: NetStatus.chan > 0; text: "CH " + NetStatus.chan }
                Chip { visible: NetStatus.ip !== ""; text: NetStatus.ip }
            }
            Row {
                spacing: 6
                visible: NetStatus.wifiConnected && NetStatus.busySsid === ""
                GwButton { small: true; label: "DISCONNECT"; onClicked: NetStatus.disconnect() }
                GwButton { small: true; label: "FORGET"; danger: true; onClicked: NetStatus.forget(NetStatus.ssid) }
            }
        }
    }

    // ---------- networks ----------
    SectionHead {
        title: "NETWORKS"
        note: NetStatus.wifiEnabled ? netModel.count + " around" : "wifi is off"
        canScan: NetStatus.wifiEnabled
        spinning: NetStatus.wifiScanning
        onScan: NetStatus.rescan()
    }

    Column {
        width: root.width
        spacing: 4
        Repeater {
            model: netModel
            delegate: Appear {
                id: nrow
                required property string ssid
                required property int signal
                required property bool secured
                required property bool inUse
                required property bool saved
                required property string band
                required property int index
                readonly property bool busy: NetStatus.busySsid === ssid
                readonly property bool asking: NetStatus.passSsid === ssid
                readonly property bool hasStatus: NetStatus.statusSsid === ssid && NetStatus.status !== ""
                                                   && NetStatus.status !== "CONNECTED" && !busy
                // the popup shows the strongest few; the settings page all of them
                visible: root.wide || index < 7 || inUse
                width: root.width
                height: visible ? card.height : 0

                Rectangle {
                    id: card
                    width: parent.width
                    height: 44 + (nrow.asking ? 46 : 0) + (nrow.hasStatus && !nrow.asking ? 18 : 0)
                    Behavior on height { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
                    clip: true
                    radius: Theme.cardRadius
                    color: nrow.inUse ? Qt.alpha(Theme.red, 0.10) : nma.containsMouse || nrow.asking ? Theme.hover : Theme.card
                    border.color: nrow.inUse || nrow.asking ? Theme.red : nrow.busy ? Qt.alpha(Theme.red, 0.5) : Theme.blockBorder
                    Behavior on color { ColorAnimation { duration: Theme.ms(160) } }

                    MouseArea {
                        id: nma
                        width: parent.width; height: 44
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (!nrow.inUse && !nrow.busy) {
                            if (nrow.asking) NetStatus.cancelPassword();
                            else { NetStatus.connect(nrow.ssid, ""); if (NetStatus.passSsid === nrow.ssid) pass.forceActiveFocus(); }
                        }
                    }

                    // signal: four dot columns rising
                    Row {
                        id: bars
                        x: 14; y: 22 - height / 2
                        spacing: 3
                        Repeater {
                            model: 4
                            delegate: Column {
                                id: bcol
                                required property int index
                                anchors.bottom: parent.bottom
                                spacing: 2
                                Repeater {
                                    model: bcol.index + 1
                                    delegate: Rectangle {
                                        width: 4; height: 4; radius: Theme.dotShape === "square" ? 0 : 2
                                        color: nrow.signal > bcol.index * 25 + 5
                                               ? (nrow.inUse ? Theme.red : Theme.fg) : Theme.faint
                                    }
                                }
                            }
                        }
                    }
                    DotText {
                        id: name
                        x: 54; y: 22 - height / 2
                        text: nrow.ssid.toUpperCase()
                        maxWidth: card.width - 54 - tail.width - 24
                        px: 1.4; gap: 1
                    }
                    Row {
                        id: tail
                        anchors { right: parent.right; rightMargin: 12 }
                        y: 22 - height / 2
                        spacing: 8
                        Chip { anchors.verticalCenter: parent.verticalCenter; text: nrow.band; visible: root.wide || nrow.band !== "2.4G" }
                        Chip { anchors.verticalCenter: parent.verticalCenter; text: "SAVED"; visible: nrow.saved && !nrow.inUse }
                        DotIcon { anchors.verticalCenter: parent.verticalCenter; visible: nrow.secured; name: "lock"; px: 0.9; gap: 0.7; color: Theme.muted }
                        Busy { anchors.verticalCenter: parent.verticalCenter; visible: nrow.busy }
                        DotIcon { anchors.verticalCenter: parent.verticalCenter; visible: nrow.inUse; name: "check"; px: 1.1; gap: 0.7; color: Theme.red }
                    }

                    // the password, right under the network that asked for it
                    Rectangle {
                        visible: nrow.asking
                        x: 12; y: 46
                        width: card.width - 24; height: 34
                        radius: 8
                        color: Theme.surface
                        border.color: pass.activeFocus ? Theme.red : Theme.blockBorder
                        DotIcon { id: lk; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                  name: "lock"; px: 1; gap: 0.8; color: Theme.red }
                        TextInput {
                            id: pass
                            anchors { left: lk.right; leftMargin: 10; right: goBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            echoMode: showPass.on ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13
                            clip: true
                            onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                            Keys.onEscapePressed: NetStatus.cancelPassword()
                            Keys.onReturnPressed: if (text !== "") NetStatus.connect(nrow.ssid, text)
                            Keys.onEnterPressed: if (text !== "") NetStatus.connect(nrow.ssid, text)
                            Text { visible: parent.text === ""; text: "password for " + nrow.ssid; color: Theme.muted; font: parent.font }
                        }
                        Text {
                            id: showPass
                            property bool on: false
                            anchors { right: goBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            visible: pass.text !== ""
                            text: on ? "HIDE" : "SHOW"
                            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 9; font.letterSpacing: 0.6
                            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: showPass.on = !showPass.on }
                        }
                        Rectangle {
                            id: goBtn
                            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                            width: 74; height: 26; radius: 6
                            color: pass.text !== "" ? Theme.red : Theme.hover
                            Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
                            Text { anchors.centerIn: parent; text: "CONNECT"; color: pass.text !== "" ? Theme.onAccent : Theme.muted
                                   font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.6 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: if (pass.text !== "") NetStatus.connect(nrow.ssid, pass.text) }
                        }
                    }
                    Text {
                        visible: nrow.hasStatus
                        x: 54; y: nrow.asking ? 84 : 40
                        text: NetStatus.status === "PASSWORD" ? "" : NetStatus.status.toLowerCase()
                        color: Theme.red; font.family: Theme.uiFont; font.pixelSize: 10
                    }
                }
            }
        }
    }

    // ---------- bluetooth ----------
    SectionHead {
        title: "BLUETOOTH"
        note: !NetStatus.btPowered ? "bluetooth is off" : NetStatus.btScanning ? "looking for devices" : btModel.count + " devices"
        canScan: NetStatus.btPowered
        spinning: NetStatus.btScanning
        onScan: NetStatus.btScan()
    }

    Label {
        visible: NetStatus.btPowered && btModel.count === 0
        text: NetStatus.btScanning ? "searching…" : "No devices yet. Put one in pairing mode and press SCAN."
    }

    Grid {
        id: btGrid
        width: root.width
        columns: root.wide ? 2 : 1
        spacing: 6
        readonly property real cw: (width - (columns - 1) * spacing) / columns
        Repeater {
            model: btModel
            delegate: Appear {
                id: brow
                required property string mac
                required property string name
                required property string icon
                required property bool paired
                required property bool connected
                required property int battery
                readonly property bool busy: NetStatus.btBusy === mac
                width: btGrid.cw
                height: 54

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cardRadius
                    color: brow.connected ? Qt.alpha(Theme.red, 0.10) : bma.containsMouse ? Theme.hover : Theme.card
                    border.color: brow.connected ? Theme.red : Theme.blockBorder
                    Behavior on color { ColorAnimation { duration: Theme.ms(160) } }

                    Rectangle {
                        id: ib
                        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                        width: 36; height: 36; radius: 10
                        color: brow.connected ? Theme.red : Theme.surface
                        Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                        DotIcon { anchors.centerIn: parent; name: NetStatus.btIcon(brow.icon); px: 1.3; gap: 0.8
                                  color: brow.connected ? Theme.onAccent : Theme.fg }
                    }
                    Column {
                        anchors { left: ib.right; leftMargin: 10; right: bact.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        DotText { text: brow.name.toUpperCase(); maxWidth: parent.width; px: 1.1; gap: 0.9 }
                        Row {
                            spacing: 6
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: brow.busy ? "working…" : brow.connected ? "connected" : brow.paired ? "paired" : "new · click to pair"
                                color: brow.connected ? Theme.red : Theme.muted
                                font.pixelSize: 10
                            }
                            // battery as five dots
                            Row {
                                visible: brow.battery >= 0
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Repeater {
                                    model: 5
                                    delegate: Rectangle {
                                        required property int index
                                        width: 4; height: 4; radius: 2
                                        color: brow.battery > index * 20 ? (brow.battery <= 20 ? Theme.red : Theme.fg) : Theme.faint
                                    }
                                }
                            }
                            Label { visible: brow.battery >= 0; anchors.verticalCenter: parent.verticalCenter; text: brow.battery + "%"; font.pixelSize: 10 }
                        }
                    }
                    Row {
                        id: bact
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Busy { anchors.verticalCenter: parent.verticalCenter; visible: brow.busy }
                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: brow.paired && !brow.busy
                            name: "x"; px: 1; gap: 0.7
                            color: xma.containsMouse ? Theme.red : Theme.muted
                            MouseArea { id: xma; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true
                                        onClicked: NetStatus.btForget({ mac: brow.mac }) }
                        }
                    }
                    MouseArea {
                        id: bma
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetStatus.btToggle({ mac: brow.mac, paired: brow.paired, connected: brow.connected })
                    }
                }
            }
        }
    }
}

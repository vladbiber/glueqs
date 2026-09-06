import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

// Network manager: wifi toggle + scan + connect (with password), bluetooth toggle + devices.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 310
    implicitHeight: 430
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
        visible && passSsid !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "net"

    property var nets: []
    property var btDevs: []
    property string busySsid: ""
    property string passSsid: ""
    property string status: ""

    onVisibleChanged: {
        if (visible) {
            passSsid = ""; status = ""; passInput.text = "";
            scan.running = true;
            btScan.running = true;
        }
    }

    // ---- wifi scan ----
    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                for (const line of text.split("\n")) {
                    if (!line.trim()) continue;
                    // first 3 fields never contain colons; SSID may (escaped as "\:")
                    const i1 = line.indexOf(":");
                    const i2 = line.indexOf(":", i1 + 1);
                    const i3 = line.indexOf(":", i2 + 1);
                    if (i3 < 0) continue;
                    const ssid = line.slice(i3 + 1).replace(/\\:/g, ":").trim();
                    if (!ssid) continue;
                    const sec = line.slice(i2 + 1, i3);
                    const e = {
                        inUse: line.slice(0, i1) === "*",
                        signal: parseInt(line.slice(i1 + 1, i2)) || 0,
                        secured: sec !== "" && sec !== "--",
                        ssid: ssid
                    };
                    if (!(ssid in seen) || e.signal > seen[ssid].signal || e.inUse)
                        seen[ssid] = e;
                }
                const list = Object.values(seen);
                list.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                root.nets = list.slice(0, 6);
            }
        }
    }
    Timer {
        running: root.visible; repeat: true; interval: 10000
        onTriggered: { scan.running = true; btScan.running = true; }
    }

    // ---- wifi connect ----
    Process {
        id: connectProc
        property string ssid: ""
        property bool hadPassword: false
        stderr: StdioCollector { id: connErr }
        onExited: (code, st) => {
            root.busySsid = "";
            if (code === 0) {
                root.status = "CONNECTED";
                root.passSsid = "";
            } else {
                const err = connErr.text.toLowerCase();
                if (!hadPassword && (err.includes("secrets") || err.includes("password")
                                     || err.includes("802.1x") || err.includes("no network"))) {
                    root.passSsid = ssid;
                    root.status = "PASSWORD?";
                    passInput.text = "";
                    passInput.forceActiveFocus();
                } else {
                    root.status = "FAILED";
                }
            }
            scan.running = true;
        }
    }
    function connect(ssid, password) {
        busySsid = ssid;
        status = "CONNECTING.";
        connectProc.ssid = ssid;
        connectProc.hadPassword = password !== "";
        connectProc.command = password === ""
            ? ["nmcli", "dev", "wifi", "connect", ssid]
            : ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        connectProc.running = true;
    }

    // ---- bluetooth ----
    Process {
        id: btScan
        command: ["sh", "-c",
            "timeout 2 bluetoothctl devices 2>/dev/null | sed 's/^/P /';" +
            "timeout 2 bluetoothctl devices Connected 2>/dev/null | sed 's/^/C /'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const m = line.match(/^([PC]) Device (\S+) (.*)$/);
                    if (!m) continue;
                    if (!(m[2] in map)) map[m[2]] = { mac: m[2], name: m[3], connected: false };
                    if (m[1] === "C") map[m[2]].connected = true;
                }
                root.btDevs = Object.values(map).slice(0, 4);
            }
        }
    }
    function btAction(dev) {
        Quickshell.execDetached(["sh", "-c",
            "timeout 10 bluetoothctl " + (dev.connected ? "disconnect " : "connect ") + dev.mac]);
        btRefresh.restart();
    }
    Timer { id: btRefresh; interval: 3000; onTriggered: btScan.running = true }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        TextInput {
            id: passInput
            width: 1; height: 1; opacity: 0
            Keys.onEscapePressed: { root.passSsid = ""; root.status = ""; }
            Keys.onReturnPressed: if (text !== "") root.connect(root.passSsid, text)
            Keys.onEnterPressed: if (text !== "") root.connect(root.passSsid, text)
        }

        Column {
            anchors { fill: parent; margins: 16 }
            spacing: 8

            Item {
                width: parent.width; height: 18
                DotText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "WIFI"; px: 1.4; gap: 1
                }
                DotToggle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    on: NetStatus.wifiEnabled
                    onToggled: {
                        Quickshell.execDetached(["nmcli", "radio", "wifi",
                            NetStatus.wifiEnabled ? "off" : "on"]);
                        rescanSoon.restart();
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.nets
                    delegate: Rectangle {
                        id: wrow
                        required property var modelData
                        width: parent.width; height: 30
                        radius: 6
                        color: wma.containsMouse ? "#1c1c1c" : "transparent"
                        border.color: modelData.inUse ? Theme.red : "transparent"
                        border.width: 1

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            DotIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: wrow.modelData.signal > 66 ? "wifi3"
                                    : wrow.modelData.signal > 33 ? "wifi2" : "wifi1"
                                px: 1.2; gap: 0.9
                                color: wrow.modelData.inUse ? Theme.fg : Theme.mid
                            }
                            DotText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: wrow.modelData.ssid.toUpperCase()
                                // icon, spacing, lock and margins come off the row
                                maxWidth: wrow.width - 8 - 22 - 8 - 22 - 10
                                px: 1.2; gap: 1
                                color: wrow.modelData.inUse
                                       || root.busySsid === wrow.modelData.ssid ? Theme.fg : Theme.mid
                            }
                            DotIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: wrow.modelData.secured
                                name: "lock"; px: 1; gap: 0.9
                                color: Theme.dim
                            }
                        }
                        MouseArea {
                            id: wma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (!wrow.modelData.inUse && root.busySsid === "")
                                root.connect(wrow.modelData.ssid, "")
                        }
                    }
                }
            }

            // password entry (appears when a network needs one)
            Rectangle {
                visible: root.passSsid !== ""
                width: parent.width; height: 30
                radius: 6
                color: "#161616"
                border.color: Theme.red
                Row {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 5
                    DotIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"; px: 1.2; gap: 1; color: Theme.red
                    }
                    Repeater {
                        model: passInput.text.length
                        delegate: Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6; height: 6; radius: 3
                            color: Theme.fg
                        }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 13
                        color: Theme.fg
                        SequentialAnimation on opacity {
                            running: root.passSsid !== ""; loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }
                }
            }

            Item { width: 1; height: 6 }

            Item {
                width: parent.width; height: 18
                DotText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "BLUETOOTH"; px: 1.4; gap: 1
                }
                DotToggle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    on: NetStatus.btPowered
                    onToggled: {
                        Quickshell.execDetached(["sh", "-c",
                            "timeout 5 bluetoothctl power " + (NetStatus.btPowered ? "off" : "on")]);
                        rescanSoon.restart();
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.btDevs
                    delegate: Rectangle {
                        id: brow
                        required property var modelData
                        width: parent.width; height: 28
                        radius: 6
                        color: bma.containsMouse ? "#1c1c1c" : "transparent"
                        border.color: modelData.connected ? Theme.red : "transparent"
                        border.width: 1
                        DotText {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: {
                                const n = brow.modelData.name.toUpperCase();
                                return n.length > 20 ? n.slice(0, 19) + "." : n;
                            }
                            px: 1.2; gap: 1
                            color: brow.modelData.connected ? Theme.fg : Theme.mid
                        }
                        MouseArea {
                            id: bma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.btAction(brow.modelData)
                        }
                    }
                }
            }

            DotText {
                visible: root.status !== ""
                text: root.status
                px: 1.1; gap: 1
                color: root.status === "FAILED" ? Theme.red : Theme.mid
            }
        }
    }

    Timer {
        id: rescanSoon
        interval: 1500
        onTriggered: { scan.running = true; btScan.running = true; NetStatus.refresh(); }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 5000
        onTriggered: { Popups.open = "net"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/net-" + root.screen.name + ".png"))
    }
}

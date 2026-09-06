import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Settings: centered modal with a sidebar of tabs
// (BAR / CLOCK / AUDIO / WEATHER / WALLPAPER / THEME / ABOUT).
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 560
    implicitHeight: 512
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
        visible && locEditing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "settings"

    readonly property int tab: Popups.settingsTab
    property bool locEditing: false
    readonly property var tabs: ["BAR", "CLOCK", "AUDIO", "WEATHER", "WALLPAPER", "THEME", "ABOUT"]

    onVisibleChanged: if (!visible) locEditing = false

    // ---- wallpapers ----
    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    function shortDir(p) {
        return (p.startsWith(homeDir) ? "~" + p.slice(homeDir.length) : p).toUpperCase();
    }

    // ---- widget order/zone management ----
    readonly property var widgetNames: ({
        settings: "SETTINGS", launcher: "LAUNCHER", workspaces: "WORKSPACES",
        weather: "WEATHER", clock: "CLOCK", media: "MEDIA", netspeed: "NET SPEED",
        network: "WIFI BT", volume: "VOLUME", battery: "BATTERY", power: "POWER",
        tray: "TRAY", notifs: "NOTIFICATIONS"
    })
    readonly property var widgetKeys: ({
        launcher: "showLauncher", workspaces: "showWorkspaces", weather: "showWeather",
        clock: "showClock", media: "showMedia", netspeed: "showNetSpeed",
        network: "showNetwork", volume: "showVolume", battery: "showBattery",
        power: "showPower", tray: "showTray", notifs: "showNotifs"
    })
    readonly property var zoneKeys: ["barLeft", "barCenter", "barRight"]
    readonly property var orderRows: {
        const out = [];
        for (let z = 0; z < 3; z++)
            for (const id of Settings.s[zoneKeys[z]].split(",").filter(x => x !== ""))
                out.push({ id: id, zone: z });
        return out;
    }
    function zoneList(z) { return Settings.s[zoneKeys[z]].split(",").filter(x => x !== "") }
    function saveZone(z, arr) { Settings.s[zoneKeys[z]] = arr.join(",") }
    function moveWidget(id, zone, dir) {
        const arr = zoneList(zone);
        const i = arr.indexOf(id);
        const j = i + dir;
        if (i < 0 || j < 0 || j >= arr.length) return;
        arr[i] = arr[j];
        arr[j] = id;
        saveZone(zone, arr);
    }
    function cycleZone(id, zone) {
        const next = (zone + 1) % 3;
        saveZone(zone, zoneList(zone).filter(x => x !== id));
        const arr = zoneList(next);
        arr.push(id);
        saveZone(next, arr);
    }

    component ToggleRow: Item {
        property string label: ""
        property string key: ""
        width: parent.width
        height: 26
        DotText {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: parent.label
            px: 1.1; gap: 1
            color: Settings.s[parent.key] ? Theme.fg : Theme.mid
        }
        DotToggle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            on: Settings.s[parent.key] ?? false
            onToggled: Settings.s[parent.key] = !Settings.s[parent.key]
        }
    }

    component SliderRow: Item {
        id: srow
        property string label: ""
        property string valueText: ""
        property real value: 0
        signal moved(real v)
        width: parent.width
        height: 30
        DotText {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: srow.label
            px: 1.1; gap: 1
        }
        DotText {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: srow.valueText
            px: 1; gap: 1; color: Theme.mid
        }
        DotSlider {
            anchors { right: parent.right; rightMargin: 64; verticalCenter: parent.verticalCenter }
            dots: 16
            value: srow.value
            onMoved: v => srow.moved(v)
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"
            px: 1.6; gap: 1
            color: sxArea.containsMouse ? Theme.red : Theme.dim
            MouseArea {
                id: sxArea
                anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true
                onClicked: Popups.open = ""
            }
        }

        Row {
            anchors { fill: parent; margins: 18 }
            spacing: 18

            // sidebar
            Column {
                width: 118
                spacing: 4
                DotText { text: "SETTINGS"; px: 1.4; gap: 1 }
                Item { width: 1; height: 8 }
                Repeater {
                    model: root.tabs
                    delegate: Rectangle {
                        id: tabRow
                        required property string modelData
                        required property int index
                        readonly property bool active: root.tab === index
                        width: parent.width; height: 30
                        radius: 6
                        color: tma.containsMouse ? "#1c1c1c" : active ? "#1a1a1a" : "transparent"
                        border.color: active ? Theme.red : "transparent"
                        border.width: 1
                        DotText {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: tabRow.modelData
                            px: 1.1; gap: 1
                            color: tabRow.active ? Theme.fg : Theme.mid
                        }
                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Popups.settingsTab = tabRow.index
                        }
                    }
                }
            }

            Rectangle { width: 1; height: parent.height; color: Theme.blockBorder }

            // content
            Item {
                id: tabArea
                width: parent.width - 118 - 1 - 36
                height: parent.height

                // BAR
                Column {
                    visible: root.tab === 0
                    width: parent.width
                    spacing: 6

                    Item {
                        width: parent.width; height: 26
                        DotText {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "POSITION"
                            px: 1.1; gap: 1
                        }
                        Row {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 4
                            Repeater {
                                model: ["top", "bottom", "left", "right"]
                                delegate: Rectangle {
                                    required property string modelData
                                    readonly property bool active: Settings.s.barPosition === modelData
                                    width: 52; height: 22; radius: 6
                                    color: pcma.containsMouse ? "#1c1c1c" : "transparent"
                                    border.color: active ? Theme.red : Theme.blockBorder
                                    border.width: 1
                                    DotText {
                                        anchors.centerIn: parent
                                        text: parent.modelData.toUpperCase()
                                        px: 0.8; gap: 0.8
                                        color: parent.active ? Theme.fg : Theme.mid
                                    }
                                    MouseArea {
                                        id: pcma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: Settings.s.barPosition = parent.modelData
                                    }
                                }
                            }
                        }
                    }
                    ToggleRow { label: "SOLID BLACK BG"; key: "barSolid" }
                    Item { width: 1; height: 4 }
                    DotText {
                        text: "WIDGETS   ARROWS = ORDER   L/C/R = ZONE"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }

                    Repeater {
                        model: root.orderRows
                        delegate: Item {
                            id: orow
                            required property var modelData
                            width: parent.width; height: 25

                            Row {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                spacing: 8
                                DotIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "up"; px: 1; gap: 0.9
                                    color: uma.containsMouse ? Theme.red : Theme.dim
                                    MouseArea {
                                        id: uma
                                        anchors.fill: parent; anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: root.moveWidget(orow.modelData.id, orow.modelData.zone, -1)
                                    }
                                }
                                DotIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "down"; px: 1; gap: 0.9
                                    color: dnma.containsMouse ? Theme.red : Theme.dim
                                    MouseArea {
                                        id: dnma
                                        anchors.fill: parent; anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: root.moveWidget(orow.modelData.id, orow.modelData.zone, 1)
                                    }
                                }
                                DotText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.widgetNames[orow.modelData.id] ?? orow.modelData.id.toUpperCase()
                                    px: 1; gap: 1
                                    color: {
                                        const k = root.widgetKeys[orow.modelData.id];
                                        return !k || Settings.s[k] ? Theme.fg : Theme.dim;
                                    }
                                }
                            }

                            Row {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                spacing: 10
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 20; radius: 5
                                    color: zma.containsMouse ? "#1c1c1c" : "transparent"
                                    border.color: Theme.blockBorder
                                    DotText {
                                        anchors.centerIn: parent
                                        text: ["L", "C", "R"][orow.modelData.zone]
                                        px: 0.9; gap: 0.9
                                        color: Theme.mid
                                    }
                                    MouseArea {
                                        id: zma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.cycleZone(orow.modelData.id, orow.modelData.zone)
                                    }
                                }
                                DotToggle {
                                    visible: root.widgetKeys[orow.modelData.id] !== undefined
                                    anchors.verticalCenter: parent.verticalCenter
                                    on: Settings.s[root.widgetKeys[orow.modelData.id]] ?? true
                                    onToggled: {
                                        const k = root.widgetKeys[orow.modelData.id];
                                        Settings.s[k] = !Settings.s[k];
                                    }
                                }
                            }
                        }
                    }
                }

                // CLOCK
                Column {
                    visible: root.tab === 1
                    width: parent.width
                    spacing: 6
                    ToggleRow { label: "12H FORMAT"; key: "clock12h" }
                    ToggleRow { label: "SHOW DATE"; key: "showDate" }
                    Item { width: 1; height: 6 }
                    DotText {
                        text: "CLICK THE CLOCK FOR CALENDAR"
                        px: 0.9; gap: 0.9; color: Theme.dim
                    }
                }

                // AUDIO
                Column {
                    visible: root.tab === 2
                    width: parent.width
                    spacing: 6
                    ToggleRow { label: "VOLUME OSD"; key: "osdEnabled" }
                    SliderRow {
                        label: "OSD TIME"
                        valueText: Settings.s.osdDuration + "MS"
                        value: (Settings.s.osdDuration - 800) / 2400
                        onMoved: v => Settings.s.osdDuration = 800 + Math.round(v * 24) * 100
                    }
                    SliderRow {
                        label: "SCROLL STEP"
                        valueText: Settings.s.volumeStep + "%"
                        value: (Settings.s.volumeStep - 1) / 9
                        onMoved: v => Settings.s.volumeStep = 1 + Math.round(v * 9)
                    }
                    ToggleRow { label: "VISUALIZER"; key: "eqEnabled" }
                    Item { width: 1; height: 6 }
                    DotText {
                        text: "EQ PRESETS LIVE IN THE MEDIA PANEL"
                        px: 0.9; gap: 0.9; color: Theme.dim
                    }
                }

                // WEATHER
                Column {
                    visible: root.tab === 3
                    width: parent.width
                    spacing: 6
                    ToggleRow { label: "SHOW WEATHER"; key: "showWeather" }
                    Item { width: 1; height: 4 }
                    DotText { text: "LOCATION"; px: 1; gap: 1; color: Theme.dim }
                    Rectangle {
                        width: parent.width; height: 32
                        radius: 8
                        color: "#161616"
                        border.color: root.locEditing ? Theme.red : Theme.blockBorder
                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            DotText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.locEditing
                                      ? locInput.text.toUpperCase()
                                      : (Settings.s.weatherLocation === ""
                                         ? "AUTO (IP)" : Settings.s.weatherLocation.toUpperCase())
                                px: 1.2; gap: 1
                                color: !root.locEditing && Settings.s.weatherLocation === ""
                                       ? Theme.dim : Theme.fg
                            }
                            Rectangle {
                                visible: root.locEditing
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 14
                                color: Theme.fg
                                SequentialAnimation on opacity {
                                    running: root.locEditing; loops: Animation.Infinite
                                    NumberAnimation { to: 0; duration: 500 }
                                    NumberAnimation { to: 1; duration: 500 }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.locEditing = true;
                                locInput.text = Settings.s.weatherLocation;
                                locInput.forceActiveFocus();
                            }
                        }
                    }
                    DotText {
                        text: "TYPE CITY. ENTER = SAVE. EMPTY = AUTO"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                    SliderRow {
                        label: "REFRESH"
                        valueText: Settings.s.weatherInterval + "MIN"
                        value: (Settings.s.weatherInterval - 5) / 55
                        onMoved: v => Settings.s.weatherInterval = 5 + Math.round(v * 11) * 5
                    }
                }

                // WALLPAPER
                Column {
                    visible: root.tab === 4
                    width: parent.width
                    spacing: 6

                    // the picker is its own panel: big thumbnails, keyboard
                    Rectangle {
                        width: parent.width; height: 34
                        radius: 8
                        color: pma.containsMouse ? "#1c1c1c" : "#161616"
                        border.color: pma.containsMouse ? Theme.red : Theme.blockBorder
                        border.width: 1
                        DotText {
                            anchors.centerIn: parent
                            text: "OPEN THE PICKER   (MOD+W)"
                            px: 1; gap: 1
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Popups.open = "wallpaper"
                        }
                    }
                    DotText {
                        text: "FOLDER  " + root.shortDir(Wallpapers.dir)
                        px: 0.85; gap: 0.85; color: Theme.mid
                    }
                    DotText {
                        text: "NOW  " + (Settings.s.wallpaper === "" ? "NONE"
                                : root.shortDir(Settings.s.wallpaper).slice(-40))
                        px: 0.85; gap: 0.85; color: Theme.mid
                    }
                    Item { width: 1; height: 4 }
                    SliderRow {
                        label: "FX TIME"
                        valueText: Settings.s.wallpaperTransitionMs + "MS"
                        value: Settings.s.wallpaperTransitionMs / 3000
                        onMoved: v => Settings.s.wallpaperTransitionMs = Math.round(v * 30) * 100
                    }
                    Item { width: 1; height: 4 }
                    DotText { text: "BEHIND THE PICTURE"; px: 1; gap: 1; color: Theme.dim }
                    Row {
                        spacing: 10
                        Repeater {
                            model: ["#000000", "#241f31", "#1a1a2e", "#101820", "#f2f2f2"]
                            delegate: Rectangle {
                                required property string modelData
                                width: 24; height: 24; radius: 12
                                color: "transparent"
                                border.color: Settings.s.wallpaperSolid === modelData ? Theme.fg : Theme.blockBorder
                                border.width: 1
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 13; height: 13; radius: 6.5
                                    color: parent.modelData
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Settings.s.wallpaperSolid = parent.modelData
                                }
                            }
                        }
                    }
                    Item { width: 1; height: 6 }
                    DotText {
                        text: "THE SHELL PAINTS THE WALLPAPER ITSELF. NO SWWW, NO WAYPAPER."
                        px: 0.7; gap: 0.7; color: Theme.hint
                    }
                }

                // THEME
                Column {
                    visible: root.tab === 5
                    width: parent.width
                    spacing: 6
                    DotText { text: "ACCENT"; px: 1; gap: 1; color: Theme.dim }
                    Row {
                        spacing: 10
                        Repeater {
                            model: ["#d71921", "#f2f2f2", "#2b7de3", "#2ec46b", "#f5c518"]
                            delegate: Rectangle {
                                required property string modelData
                                width: 24; height: 24; radius: 12
                                color: "transparent"
                                border.color: Settings.s.accent === modelData ? Theme.fg : Theme.blockBorder
                                border.width: 1
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 13; height: 13; radius: 6.5
                                    color: parent.modelData
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Settings.s.accent = parent.modelData
                                }
                            }
                        }
                    }
                    Item { width: 1; height: 8 }
                    SliderRow {
                        label: "UI SCALE"
                        valueText: Math.round(Settings.s.scale * 100) + "%"
                        value: (Settings.s.scale - 0.85) / 0.45
                        onMoved: v => Settings.s.scale = Math.round((0.85 + v * 0.45) * 20) / 20
                    }
                    DotText {
                        text: "SCALES BAR, TILES AND DOT FONTS"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                    Item { width: 1; height: 8 }
                    ToggleRow { label: "DOT MATRIX FONT"; key: "dotFont" }
                    DotText {
                        text: "OFF = PLAIN TEXT INSTEAD OF DOTS"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                }

                // ABOUT
                Column {
                    visible: root.tab === 6
                    width: parent.width
                    spacing: 10
                    Item { width: 1; height: 8 }
                    DotText { text: "GLUEQS"; px: 2.6; gap: 1.3 }
                    DotText {
                        text: "DOT MATRIX SHELL FOR GLUEWC"
                        px: 1; gap: 1; color: Theme.mid
                    }
                    Item { width: 1; height: 8 }
                    DotText { text: "DOT MATRIX. BLACK. ONE RED."; px: 0.9; gap: 0.9; color: Theme.red }
                    DotText { text: "CONFIG " + "~/.CONFIG/QUICKSHELL/GLUEQS"; px: 0.9; gap: 0.9; color: Theme.dim }
                    DotText { text: "SETTINGS SAVED TO SETTINGS.JSON"; px: 0.9; gap: 0.9; color: Theme.dim }
                    Item { width: 1; height: 8 }
                    Rectangle {
                        width: 60; height: 24; radius: 6
                        color: "transparent"
                        border.color: Theme.blockBorder
                        DotText {
                            anchors.centerIn: parent
                            text: "RESET"
                            px: 1; gap: 1; color: rma.containsMouse ? Theme.red : Theme.mid
                        }
                        MouseArea {
                            id: rma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Settings.s.accent = "#d71921";
                                Settings.s.scale = 1.0;
                                Settings.s.barPosition = "top";
                                Settings.s.barSolid = false;
                                Settings.s.barLeft = "settings,launcher,workspaces,tray,media";
                                Settings.s.barCenter = "weather,clock,notifs";
                                Settings.s.barRight = "netspeed,network,volume,battery,power";
                            }
                        }
                    }
                }
            }
        }

        TextInput {
            id: locInput
            width: 1; height: 1; opacity: 0
            Keys.onEscapePressed: root.locEditing = false
            Keys.onReturnPressed: {
                Settings.s.weatherLocation = text.trim();
                root.locEditing = false;
            }
            Keys.onEnterPressed: {
                Settings.s.weatherLocation = text.trim();
                root.locEditing = false;
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 8800
        onTriggered: {
            Popups.open = "settings";
            Popups.settingsTab = parseInt(Quickshell.env("GLUEQS_SHOT_TAB")) || 0;
            shotTimer.start();
        }
    }
    Timer {
        id: shotTimer
        interval: 1000
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/settings-" + root.screen.name + ".png"))
    }
}

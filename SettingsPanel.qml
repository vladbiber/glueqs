import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Settings: a centred panel with the pages on the left (BAR / CLOCK / AUDIO /
// WEATHER / WALLPAPER / DISPLAY / THEME / ABOUT, plus GLUEWC under that
// compositor) and the page on the right. Plain text for what has to be read,
// dots for the headings.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 720
    implicitHeight: Math.max(480, Math.min(640, (root.screen?.height ?? 900) - Theme.popupTop - 40))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "settings"

    readonly property int tab: Popups.settingsTab
    readonly property var baseTabs: [
        { label: "BAR", sub: "position, widgets" },
        { label: "CLOCK", sub: "format, date" },
        { label: "AUDIO", sub: "osd, steps" },
        { label: "WEATHER", sub: "location, refresh" },
        { label: "WALLPAPER", sub: "picker, fill, colour" },
        { label: "DISPLAY", sub: "brightness" },
        { label: "THEME", sub: "accent, scale, font" },
        { label: "ABOUT", sub: "glueqs" }
    ]
    // the compositor's settings have their own, wider panel; under gluewc
    // they get an entry at the end of this list that opens it
    readonly property var tabs: Gluewc.available ? baseTabs.concat([{ label: "GLUEWC", sub: "compositor, monitors", external: true }]) : baseTabs

    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    function shortDir(p) { return p.startsWith(homeDir) ? "~" + p.slice(homeDir.length) : p }

    // ---- widget order/zone management ----
    readonly property var widgetNames: ({
        settings: "Settings", launcher: "Launcher", workspaces: "Workspaces",
        weather: "Weather", clock: "Clock", media: "Media", netspeed: "Net speed",
        network: "Wi-Fi and Bluetooth", volume: "Volume", battery: "Battery", power: "Power",
        tray: "Tray", notifs: "Notifications", brightness: "Brightness"
    })
    readonly property var widgetKeys: ({
        launcher: "showLauncher", workspaces: "showWorkspaces", weather: "showWeather",
        clock: "showClock", media: "showMedia", netspeed: "showNetSpeed",
        network: "showNetwork", volume: "showVolume", battery: "showBattery",
        power: "showPower", tray: "showTray", notifs: "showNotifs", brightness: "showBrightness"
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

    // a row with a shell setting toggle
    component SToggle: GwRow {
        property string skey: ""
        GwToggle { bound: true; value: Settings.s[parent.skey] ?? false; onToggled: Settings.s[parent.skey] = !Settings.s[parent.skey] }
    }
    component Swatches: Row {
        property string skey: ""
        property var colors: []
        spacing: 10
        Repeater {
            model: parent.colors
            delegate: Rectangle {
                required property string modelData
                width: 28; height: 28; radius: 14
                color: "transparent"
                border.color: Settings.s[parent.skey] === modelData ? Theme.fg : swm.containsMouse ? "#4a4a4a" : Theme.blockBorder
                border.width: Settings.s[parent.skey] === modelData ? 2 : 1
                Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: parent.modelData }
                MouseArea { id: swm; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.s[parent.parent.skey] = parent.modelData }
            }
        }
    }
    component Note: Text {
        width: parent.width
        wrapMode: Text.WordWrap
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11
        topPadding: 10
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: content.forceActiveFocus() }

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            height: 34
            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 14
                DotText { anchors.verticalCenter: parent.verticalCenter; text: "SETTINGS"; px: 2; gap: 1.2 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "glueqs shell"; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12 }
            }
            DotIcon {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                name: "x"; px: 1.6; gap: 1
                color: sxArea.containsMouse ? Theme.red : Theme.dim
                MouseArea {
                    id: sxArea
                    anchors.fill: parent; anchors.margins: -8
                    hoverEnabled: true
                    onClicked: Popups.open = ""
                }
            }
        }
        Rectangle {
            anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 10 }
            height: 1; color: Theme.blockBorder
        }

        Row {
            anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18; topMargin: 24 }
            spacing: 20

            Column {
                id: side
                width: 150
                spacing: 4
                Repeater {
                    model: root.tabs
                    delegate: Rectangle {
                        id: tabRow
                        required property var modelData
                        required property int index
                        readonly property bool external: modelData.external === true
                        readonly property bool active: !external && root.tab === index
                        width: parent.width; height: 44
                        radius: 8
                        color: tma.containsMouse ? "#1c1c1c" : active ? "#181818" : "transparent"
                        border.color: active ? Theme.red : external ? Theme.blockBorder : "transparent"
                        border.width: 1
                        Column {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 4
                            DotText { text: tabRow.modelData.label; px: 1.05; gap: 1; color: tabRow.active ? Theme.fg : Theme.mid }
                            Text { text: tabRow.modelData.sub; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 10 }
                        }
                        DotText {
                            visible: tabRow.external
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            text: ">"; px: 1.1; gap: 1; color: Theme.red
                        }
                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                content.forceActiveFocus();
                                if (tabRow.external) Popups.open = "gluewc";
                                else Popups.settingsTab = tabRow.index;
                            }
                        }
                    }
                }
            }

            Rectangle { width: 1; height: parent.height; color: Theme.blockBorder }

            Flickable {
                id: tabArea
                width: parent.width - side.width - 1 - 40
                height: parent.height
                clip: true
                contentWidth: width
                contentHeight: tabStack.implicitHeight + 8
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: root
                    function onTabChanged() { tabArea.contentY = 0 }
                }

                Item {
                    id: tabStack
                    width: tabArea.width - 6
                    implicitHeight: {
                        let h = 0;
                        for (const c of children) if (c.visible) h = Math.max(h, c.implicitHeight);
                        return h;
                    }

                    // BAR
                    Column {
                        visible: root.tab === 0
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "BAR"; sub: "Where the bar sits and what is on it. Arrows change the order, L / C / R moves a widget between the three zones." }
                        GwRow { label: "Position"; hint: "Which screen edge"
                            GwChoice {
                                bound: true; value: Settings.s.barPosition
                                options: [{ v: "top", label: "TOP" }, { v: "bottom", label: "BOTTOM" }, { v: "left", label: "LEFT" }, { v: "right", label: "RIGHT" }]
                                onPicked: v => Settings.s.barPosition = v
                            }
                        }
                        SToggle { label: "Solid black background"; hint: "Instead of see-through between the tiles"; skey: "barSolid" }

                        GwTitle { text: "WIDGETS" }
                        Repeater {
                            model: root.orderRows
                            delegate: Item {
                                id: orow
                                required property var modelData
                                readonly property string vkey: root.widgetKeys[modelData.id] ?? ""
                                width: parent.width; height: 40
                                Row {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    spacing: 6
                                    GwButton { label: "↑"; small: true; implicitWidth: 26; onClicked: root.moveWidget(orow.modelData.id, orow.modelData.zone, -1) }
                                    GwButton { label: "↓"; small: true; implicitWidth: 26; onClicked: root.moveWidget(orow.modelData.id, orow.modelData.zone, 1) }
                                    Item { width: 6; height: 1 }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.widgetNames[orow.modelData.id] ?? orow.modelData.id
                                        color: orow.vkey === "" || Settings.s[orow.vkey] ? Theme.fg : "#8a8a8a"
                                        font.family: Theme.uiFont; font.pixelSize: 13
                                    }
                                }
                                Row {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    spacing: 10
                                    GwButton {
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: ["LEFT", "CENTER", "RIGHT"][orow.modelData.zone]; small: true
                                        onClicked: root.cycleZone(orow.modelData.id, orow.modelData.zone)
                                    }
                                    DotToggle {
                                        visible: orow.vkey !== ""
                                        anchors.verticalCenter: parent.verticalCenter
                                        on: Settings.s[orow.vkey] ?? true
                                        onToggled: Settings.s[orow.vkey] = !Settings.s[orow.vkey]
                                    }
                                    Item { visible: orow.vkey === ""; width: 30; height: 1 }
                                }
                                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#1a1a1a" }
                            }
                        }
                    }

                    // CLOCK
                    Column {
                        visible: root.tab === 1
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "CLOCK"; sub: "Click the clock in the bar for the calendar." }
                        SToggle { label: "12-hour format"; skey: "clock12h" }
                        SToggle { label: "Show the date"; skey: "showDate" }
                    }

                    // AUDIO
                    Column {
                        visible: root.tab === 2
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "AUDIO"; sub: "The volume tile, its OSD and the media visualiser. Equaliser presets live in the media panel." }
                        SToggle { label: "Volume OSD"; hint: "A pop-up when the volume changes"; skey: "osdEnabled" }
                        GwRow { label: "OSD time"; hint: "How long the pop-up stays"
                            GwNumber { bound: true; value: Settings.s.osdDuration; min: 800; max: 3200; step: 100; unit: "ms"; onChanged: v => Settings.s.osdDuration = Math.round(v) }
                        }
                        GwRow { label: "Scroll step"; hint: "Per wheel notch on the volume tile"
                            GwNumber { bound: true; value: Settings.s.volumeStep; min: 1; max: 10; unit: "%"; onChanged: v => Settings.s.volumeStep = Math.round(v) }
                        }
                        SToggle { label: "Visualiser"; hint: "The live spectrum in the media panel"; skey: "eqEnabled" }
                    }

                    // WEATHER
                    Column {
                        visible: root.tab === 3
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "WEATHER"; sub: "Current conditions from wttr.in through curl." }
                        SToggle { label: "Show weather"; skey: "showWeather" }
                        GwRow { label: "Location"; hint: "A city name. Empty finds you by IP address."
                            GwField {
                                width: 200
                                text: Settings.s.weatherLocation
                                placeholder: "auto (IP)"
                                onCommitted: v => Settings.s.weatherLocation = v.trim()
                            }
                        }
                        GwRow { label: "Refresh"
                            GwNumber { bound: true; value: Settings.s.weatherInterval; min: 5; max: 60; step: 5; unit: "min"; onChanged: v => Settings.s.weatherInterval = Math.round(v) }
                        }
                    }

                    // WALLPAPER
                    Column {
                        visible: root.tab === 4
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "WALLPAPER"; sub: "The shell paints it itself, no swww or waypaper needed. The picker browses folders, shows thumbnails and takes a typed path." }
                        GwRow { label: "Picture"; hint: Settings.s.wallpaper === "" ? "none yet" : root.shortDir(Settings.s.wallpaper)
                            GwButton { label: "OPEN THE PICKER   (MOD+W)"; active: true; onClicked: Popups.open = "wallpaper" }
                        }
                        GwRow { label: "Shuffle folder"; hint: root.shortDir(Wallpapers.dir) + "   ·   " + Wallpapers.files.length + " pictures"
                            GwField {
                                width: 220
                                text: Settings.s.wallpaperDir
                                placeholder: "~/Pictures/Wallpapers"
                                onCommitted: v => { let p = v.trim(); if (p.startsWith("~")) p = root.homeDir + p.slice(1); Settings.s.wallpaperDir = p; }
                            }
                        }
                        GwRow { label: "Fill"
                            GwChoice {
                                bound: true; value: Settings.s.wallpaperFill
                                options: [{ v: "crop", label: "CROP" }, { v: "fit", label: "FIT" }, { v: "stretch", label: "STRETCH" }, { v: "center", label: "CENTER" }, { v: "tile", label: "TILE" }]
                                onPicked: v => Settings.s.wallpaperFill = v
                            }
                        }
                        GwRow { label: "Transition"
                            GwChoice {
                                bound: true; value: Settings.s.wallpaperTransition
                                options: [{ v: "fade", label: "FADE" }, { v: "wipe", label: "WIPE" }, { v: "slide", label: "SLIDE" }, { v: "zoom", label: "ZOOM" }, { v: "random", label: "RANDOM" }]
                                onPicked: v => Settings.s.wallpaperTransition = v
                            }
                        }
                        GwRow { label: "Transition time"
                            GwNumber { bound: true; value: Settings.s.wallpaperTransitionMs; min: 0; max: 3000; step: 100; unit: "ms"; onChanged: v => Settings.s.wallpaperTransitionMs = Math.round(v) }
                        }
                        GwRow { label: "Shuffle every"; hint: "0 turns the random change off"
                            GwNumber { bound: true; value: Settings.s.wallpaperRandomMin; min: 0; max: 240; step: 5; unit: "min"; onChanged: v => Settings.s.wallpaperRandomMin = Math.round(v) }
                        }
                        GwRow { label: "Behind the picture"; hint: "Also the colour on its own without one"
                            Swatches { skey: "wallpaperSolid"; colors: ["#000000", "#241f31", "#1a1a2e", "#101820", "#f2f2f2"] }
                        }
                    }

                    // DISPLAY
                    Column {
                        visible: root.tab === 5
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "BRIGHTNESS"; sub: "The panel backlight. The bar has the same slider under the brightness tile." }
                        Item { width: 1; height: 14 }
                        Loader {
                            width: parent.width
                            active: Brightness.available
                            sourceComponent: BrightnessControls { width: parent.width }
                        }
                        Note {
                            visible: !Brightness.available
                            text: "No backlight under /sys/class/backlight on this machine, so there is nothing to dim from here."
                        }
                        GwTitle { visible: Gluewc.available; text: "MONITORS"; sub: "Layout, resolution, scale and mirroring are compositor settings." }
                        Item { visible: Gluewc.available; width: 1; height: 12 }
                        GwButton { visible: Gluewc.available; label: "OPEN GLUEWC MONITORS  >"; active: true; onClicked: { Popups.gluewcPage = 7; Popups.open = "gluewc"; } }
                    }

                    // THEME
                    Column {
                        visible: root.tab === 6
                        width: parent.width
                        spacing: 0
                        GwTitle { first: true; text: "THEME"; sub: "Black, white and one accent." }
                        GwRow { label: "Accent"
                            Swatches { skey: "accent"; colors: ["#d71921", "#f2f2f2", "#2b7de3", "#2ec46b", "#f5c518"] }
                        }
                        GwRow { label: "Custom accent"; hint: "Any hex colour"
                            GwField {
                                width: 110
                                text: Settings.s.accent
                                onCommitted: v => { const c = v.trim(); if (/^#[0-9a-fA-F]{6}$/.test(c)) Settings.s.accent = c; }
                            }
                        }
                        GwRow { label: "UI scale"; hint: "Bar, tiles and dot fonts"
                            GwNumber { bound: true; value: Settings.s.scale; min: 0.85; max: 1.3; step: 0.05; decimals: 2; unit: "×"; onChanged: v => Settings.s.scale = Math.round(v * 20) / 20 }
                        }
                        SToggle { label: "Dot-matrix font"; hint: "Off shows plain text in the bar instead of dots"; skey: "dotFont" }
                    }

                    // ABOUT
                    Column {
                        visible: root.tab === 7
                        width: parent.width
                        spacing: 10
                        Item { width: 1; height: 8 }
                        DotText { text: "GLUEQS"; px: 2.6; gap: 1.3 }
                        Text { text: "Dot-matrix shell for gluewc. Black, white, one red."; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13 }
                        Item { width: 1; height: 6 }
                        Text { text: "Shell files    " + Quickshell.shellPath("").replace(root.homeDir, "~"); color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12 }
                        Text { text: "Settings       " + Settings.dir.replace(root.homeDir, "~") + "/settings.json"; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12 }
                        Text { visible: Gluewc.available; text: "Compositor     " + Gluewc.configPath.replace(root.homeDir, "~"); color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12 }
                        Item { width: 1; height: 10 }
                        GwButton {
                            label: "RESET THE BAR LAYOUT"; danger: true
                            onClicked: {
                                Settings.s.accent = "#d71921";
                                Settings.s.scale = 1.0;
                                Settings.s.barPosition = "top";
                                Settings.s.barSolid = false;
                                Settings.s.barLeft = "settings,launcher,workspaces,tray,media";
                                Settings.s.barCenter = "weather,clock,notifs";
                                Settings.s.barRight = "netspeed,network,volume,brightness,battery,power";
                            }
                        }
                        Note { text: "Accent, scale, position and the widget zones go back to the defaults. Everything else stays." }
                    }
                }
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
        interval: 1500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/settings-" + root.screen.name + ".png"))
    }
}

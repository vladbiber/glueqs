import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Settings: a centred panel. On the left the pages, each with its dot icon,
// a search box over their keywords and an accent pill that slides to the one
// open; on the right a big header and the page, loaded on demand and faded in.
// GLUEWC and GLUE LINUX at the end open their own windows.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 980
    implicitHeight: Math.max(520, Math.min(740, (root.screen?.height ?? 900) - Theme.popupTop - 40))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "settings" || content.opacity > 0.01

    readonly property bool shown: Popups.open === "settings"
    readonly property int tab: Popups.settingsTab
    readonly property var baseTabs: [
        { label: "BAR", sub: "position, size, look", icon: "window", page: "SpBar.qml", keys: "bar position top bottom left right floating solid size height spacing" },
        { label: "WIDGETS", sub: "add, order, remove", icon: "grid", page: "SpWidgets.qml", keys: "widgets add remove order cpu ram temp disk visualiser visualizer mic microphone keep awake caffeine wallpaper button window caps spacer" },
        { label: "THEME", sub: "colour schemes", icon: "palette", page: "SpTheme.qml", keys: "theme colour color scheme palette accent custom matugen wallpaper colours dark light gruvbox nord catppuccin dracula tokyo" },
        { label: "LOOK", sub: "fonts, dots, shape", icon: "sliders", page: "SpLook.qml", keys: "font fonts dot shape square round diamond scale radius corners opacity transparency borders animation speed weight" },
        { label: "WALLPAPER", sub: "picker, fill, shuffle", icon: "image", page: "SpWallpaper.qml", keys: "wallpaper picture background fill transition shuffle folder" },
        { label: "NETWORK", sub: "wifi, bluetooth", icon: "wifi3", page: "SpNetwork.qml", keys: "network wifi wi-fi wireless internet password ssid bluetooth bt pair headphones airplane" },
        { label: "AUDIO", sub: "mixer, devices, osd", icon: "speaker", page: "SpAudio.qml", keys: "audio sound volume mixer output input device speakers headphones microphone mic apps osd visualiser visualizer spectrum bars cava equaliser" },
        { label: "CLOCK", sub: "format, date", icon: "clock", page: "SpClock.qml", keys: "clock time date 12h 24h calendar" },
        { label: "WEATHER", sub: "location, refresh", icon: "cloud", page: "SpWeather.qml", keys: "weather location city wttr refresh" },
        { label: "DISPLAY", sub: "brightness, sleep", icon: "bright", page: "DisplayControls.qml", keys: "display brightness backlight sleep mode screen off suspend idle keep awake monitors" }
    ].concat(Gluewc.available ? [
        { label: "MACROS", sub: "clicks, keys, recorder", icon: "sliders", page: "GwMacros.qml", keys: "macro macros autoclicker auto click cps repeat record recorder keys keyboard mouse hold toggle sequence" }
    ] : []).concat([
        { label: "ABOUT", sub: "glueqs, reset", icon: "info", page: "SpAbout.qml", keys: "about reset files version" }
    ])
    // the compositor's settings and Glue Linux's own open their own windows
    property bool glueLinux: false
    Process {
        running: true
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; [ \"$ID\" = glue ] && command -v glue-welcome >/dev/null"]
        onExited: code => root.glueLinux = code === 0
    }
    readonly property var tabs: baseTabs
        .concat(Gluewc.available ? [{ label: "GLUEWC", sub: "compositor, monitors", icon: "window", external: "gluewc", keys: "gluewc compositor keybinds monitors layout animations input" }] : [])
        .concat(glueLinux ? [{ label: "GLUE LINUX", sub: "system settings", icon: "gear", external: "glue", keys: "glue linux system" }] : [])

    property string query: ""
    function matches(t) {
        const q = query.trim().toLowerCase();
        return q === "" || (t.label + " " + t.sub + " " + t.keys).toLowerCase().includes(q);
    }
    function openTab(i) {
        const t = tabs[i];
        if (!t) return;
        if (t.external === "gluewc") Popups.open = "gluewc";
        else if (t.external === "glue") {
            Quickshell.execDetached(["glue-welcome", "--page", "settings"]);
            Popups.open = "";
        } else Popups.settingsTab = i;
    }
    onShownChanged: if (shown) { query = ""; content.forceActiveFocus(); }

    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    function shortDir(p) { return p.startsWith(homeDir) ? "~" + p.slice(homeDir.length) : p }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: Theme.panelRadius
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1
        focus: true
        Keys.onEscapePressed: Popups.open = ""
        Keys.onUpPressed: root.openTab(Math.max(0, root.tab - 1))
        Keys.onDownPressed: root.openTab(Math.min(root.baseTabs.length - 1, root.tab + 1))

        // open and close: a short rise and fade
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.ms(250) } }

        MouseArea { anchors.fill: parent; onClicked: content.forceActiveFocus() }

        // ---------- sidebar ----------
        Rectangle {
            id: side
            anchors { top: parent.top; left: parent.left; bottom: parent.bottom; margins: 10 }
            width: 216
            radius: Theme.panelRadius - 4
            color: Theme.card
            border.color: Theme.line

            Column {
                id: brand
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
                spacing: 6
                Row {
                    spacing: 8
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.red }
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "GLUEQS"; px: 2; gap: 1.1 }
                }
                Text { text: "settings"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
            }

            // search over the pages' keywords
            Rectangle {
                id: searchBox
                anchors { top: brand.bottom; left: parent.left; right: parent.right; margins: 12; topMargin: 14 }
                height: 32; radius: 8
                color: Theme.surface
                border.color: search.activeFocus ? Theme.red : Theme.border
                Behavior on border.color { ColorAnimation { duration: Theme.ms(150) } }
                DotIcon { id: sIcon; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                name: "search"; px: 0.9; gap: 0.7; color: Theme.muted }
                TextInput {
                    id: search
                    anchors { left: sIcon.right; right: parent.right; leftMargin: 8; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
                    clip: true
                    text: root.query
                    onTextEdited: root.query = text
                    Keys.onEscapePressed: { if (text !== "") { root.query = ""; } else Popups.open = ""; }
                    Keys.onReturnPressed: {
                        for (let i = 0; i < root.tabs.length; i++)
                            if (root.matches(root.tabs[i])) { root.openTab(i); break; }
                    }
                    Text {
                        visible: parent.text === ""
                        text: "Search settings"
                        color: Theme.muted; font: parent.font
                    }
                }
            }

            Flickable {
                id: tabList
                anchors { top: searchBox.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8; topMargin: 12 }
                contentHeight: tabCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // the accent pill, sliding to the open page
                Rectangle {
                    id: pill
                    readonly property Item target: {
                        for (let i = 0; i < tabRep.count; i++) {
                            const it = tabRep.itemAt(i);
                            if (it && it.index === root.tab && it.visible) return it;
                        }
                        return null;
                    }
                    visible: target !== null
                    x: 0; width: parent.width
                    y: target ? target.y : 0
                    height: 48
                    radius: 10
                    color: Theme.red
                    Behavior on y { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.ms(250) } }
                }

                Column {
                    id: tabCol
                    width: parent.width
                    spacing: 2
                    Repeater {
                        id: tabRep
                        model: root.tabs
                        delegate: Item {
                            id: tabRow
                            required property var modelData
                            required property int index
                            readonly property string external: modelData.external ?? ""
                            readonly property bool active: external === "" && root.tab === index
                            visible: root.matches(modelData)
                            width: parent.width; height: visible ? 48 : 0

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: tma.containsMouse && !tabRow.active ? Theme.hover : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
                            }
                            Rectangle {
                                visible: tabRow.external !== "" && index > 0 && (root.tabs[index - 1].external ?? "") === ""
                                anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10 }
                                height: 1; color: Theme.line
                            }
                            DotIcon {
                                id: ti
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                name: tabRow.modelData.icon
                                px: 1.2; gap: 0.9
                                color: tabRow.active ? Theme.onAccent : Theme.fg
                            }
                            Column {
                                anchors { left: parent.left; leftMargin: 44; verticalCenter: parent.verticalCenter }
                                spacing: 4
                                DotText { text: tabRow.modelData.label; px: 1.05; gap: 1; color: tabRow.active ? Theme.onAccent : Theme.fg }
                                Text { text: tabRow.modelData.sub; color: tabRow.active ? Qt.alpha(Theme.onAccent, 0.75) : Theme.muted; font.family: Theme.uiFont; font.pixelSize: 10 }
                            }
                            DotText {
                                visible: tabRow.external !== ""
                                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                text: ">"; px: 1.1; gap: 1; color: Theme.red
                            }
                            MouseArea {
                                id: tma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: { content.forceActiveFocus(); root.openTab(tabRow.index); }
                            }
                        }
                    }
                }
            }
        }

        // ---------- page ----------
        Item {
            id: pane
            anchors { top: parent.top; bottom: parent.bottom; left: side.right; right: parent.right; margins: 10; leftMargin: 24; rightMargin: 18 }
            readonly property var cur: root.baseTabs[root.tab] ?? root.baseTabs[0]

            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 10 }
                height: 52
                Rectangle {
                    id: hIconBox
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44; height: 44; radius: 12
                    color: Qt.alpha(Theme.red, 0.14)
                    border.color: Qt.alpha(Theme.red, 0.5)
                    DotIcon { anchors.centerIn: parent; name: pane.cur.icon; px: 2; gap: 1.1; color: Theme.red }
                }
                Column {
                    anchors { left: hIconBox.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    DotText { text: pane.cur.label; px: 2.4; gap: 1.2 }
                    Text { text: pane.cur.sub; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 12 }
                }
                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 34; height: 34; radius: 17
                    color: xa.containsMouse ? Qt.alpha(Theme.red, 0.18) : "transparent"
                    border.color: xa.containsMouse ? Theme.red : Theme.border
                    DotIcon { anchors.centerIn: parent; name: "x"; px: 1.4; gap: 0.9; color: xa.containsMouse ? Theme.red : Theme.fg }
                    MouseArea { id: xa; anchors.fill: parent; hoverEnabled: true; onClicked: Popups.open = "" }
                }
            }
            Rectangle {
                id: hLine
                anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 10 }
                height: 1; color: Theme.line
            }

            Flickable {
                id: tabArea
                anchors { top: hLine.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: 4 }
                clip: true
                contentWidth: width
                contentHeight: page.implicitHeight + 30
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: Popups
                    function onSettingsScroll(y) { tabArea.contentY = Math.max(0, Math.min(y, tabArea.contentHeight - tabArea.height)) }
                }

                Loader {
                    id: page
                    y: 14
                    width: tabArea.width - 10
                    source: pane.cur.page
                    // each page fades and slides in when it opens
                    opacity: 0
                    onLoaded: { tabArea.contentY = 0; enter.restart(); }
                    ParallelAnimation {
                        id: enter
                        NumberAnimation { target: page; property: "opacity"; from: 0; to: 1; duration: Theme.ms(260); easing.type: Easing.OutCubic }
                        NumberAnimation { target: page; property: "y"; from: 30; to: 14; duration: Theme.ms(320); easing.type: Easing.OutCubic }
                    }
                }
            }
            // scroll position
            Rectangle {
                anchors.right: parent.right
                width: 3; radius: 1.5
                visible: tabArea.contentHeight > tabArea.height
                color: Theme.strong
                height: Math.max(30, tabArea.height * tabArea.height / Math.max(1, tabArea.contentHeight))
                y: tabArea.y + (tabArea.contentY / Math.max(1, tabArea.contentHeight - tabArea.height)) * (tabArea.height - height)
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

import Quickshell
import Quickshell.Wayland
import QtQuick

// The compositor's own settings, in a wider panel than the shell's: a list
// of pages on the left, the page on the right, and the display-change trial
// bar at the bottom. Only exists under gluewc.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 960
    implicitHeight: Math.max(520, Math.min(740, (root.screen?.height ?? 900) - Theme.popupTop - 40))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glueqs-gluewc"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "gluewc" && Gluewc.available

    readonly property int page: Popups.gluewcPage
    readonly property var pages: [
        { label: "APPEARANCE", sub: "corners, blur, borders", file: "GwAppearance.qml" },
        { label: "ANIMATIONS", sub: "open, close, motion", file: "GwAnimations.qml" },
        { label: "LAYOUT", sub: "bsp, scroll, drift", file: "GwLayout.qml" },
        { label: "INPUT", sub: "pointer, keyboard", file: "GwInput.qml" },
        { label: "AUTOSTART", sub: "runs at login", file: "GwAutostart.qml" },
        { label: "KEYBINDS", sub: "every shortcut", file: "GwBinds.qml" },
        { label: "DISPLAY", sub: "brightness", file: "GwDisplay.qml" },
        { label: "MONITORS", sub: "layout, mirror, scale", file: "GwMonitors.qml" }
    ]

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        // a click on bare panel commits and blurs whichever field was open
        MouseArea { anchors.fill: parent; onClicked: content.forceActiveFocus() }

        // header
        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
            height: 40
            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 14
                DotText { anchors.verticalCenter: parent.verticalCenter; text: "GLUEWC"; px: 2.2; gap: 1.2 }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: "Compositor settings"; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium }
                    Text {
                        text: Gluewc.configPath.replace(Gluewc.home, "~") + "   ·   saved changes apply immediately"
                        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11
                    }
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 12
                GwButton {
                    anchors.verticalCenter: parent.verticalCenter
                    label: "<  SHELL SETTINGS"; small: true
                    onClicked: Popups.open = "settings"
                }
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "x"; px: 1.6; gap: 1
                    color: xa.containsMouse ? Theme.red : Theme.dim
                    MouseArea {
                        id: xa
                        anchors.fill: parent; anchors.margins: -8
                        hoverEnabled: true
                        onClicked: Popups.open = ""
                    }
                }
            }
        }
        Rectangle {
            anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 12 }
            height: 1; color: Theme.blockBorder
        }

        // body
        Row {
            id: body
            anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: trial.top; margins: 18; topMargin: 26 }
            spacing: 22

            Column {
                id: side
                width: 176
                spacing: 4
                Repeater {
                    model: root.pages
                    delegate: Rectangle {
                        id: prow
                        required property var modelData
                        required property int index
                        readonly property bool active: root.page === index
                        width: parent.width; height: 46
                        radius: 8
                        color: pma.containsMouse ? "#1c1c1c" : active ? "#181818" : "transparent"
                        border.color: active ? Theme.red : "transparent"
                        border.width: 1
                        Column {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 4
                            DotText { text: prow.modelData.label; px: 1.1; gap: 1; color: prow.active ? Theme.fg : Theme.mid }
                            Text { text: prow.modelData.sub; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11 }
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { content.forceActiveFocus(); Popups.gluewcPage = prow.index; }
                        }
                    }
                }
            }

            Rectangle { width: 1; height: parent.height; color: Theme.blockBorder }

            Flickable {
                id: area
                width: parent.width - side.width - 1 - 44
                height: parent.height
                clip: true
                contentWidth: width
                contentHeight: pageLoader.item ? pageLoader.item.implicitHeight + 24 : 0
                boundsBehavior: Flickable.StopAtBounds
                Connections {
                    target: root
                    function onPageChanged() { area.contentY = 0 }
                }
                Loader {
                    id: pageLoader
                    width: area.width - 8
                    active: root.visible
                    source: root.pages[root.page].file
                }
            }
        }

        // the 15 s trial after a display change
        Rectangle {
            id: trial
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18 }
            height: Gluewc.trialActive ? 52 : 0
            visible: height > 0
            radius: 10
            color: "#151010"
            border.color: Theme.red
            Behavior on height { NumberAnimation { duration: 140 } }
            clip: true
            Row {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 14
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Keep these display settings?"
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "reverting in " + Gluewc.trialLeft + " s"
                    color: Theme.red; font.family: Theme.uiFont; font.pixelSize: 12
                }
            }
            Row {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 8
                GwButton { label: "KEEP"; active: true; onClicked: Gluewc.keepTrial() }
                GwButton { label: "REVERT"; danger: true; onClicked: Gluewc.revertTrial() }
            }
        }
    }

    // GLUEQS_SHOT_DIR=/dir GLUEQS_SHOT_GLUEWC=<page> writes gluewc-<page>-<screen>.png
    readonly property string shotDir: Quickshell.env("GLUEQS_SHOT_DIR") ?? ""
    Timer {
        running: root.shotDir !== "" && (Quickshell.env("GLUEQS_SHOT_GLUEWC") ?? "") !== ""
        interval: 4500
        onTriggered: {
            Popups.gluewcPage = parseInt(Quickshell.env("GLUEQS_SHOT_GLUEWC")) || 0;
            Popups.open = "gluewc";
            if ((Quickshell.env("GLUEQS_SHOT_TRIAL") ?? "") !== "") Gluewc.beginTrial();
            shot.start();
        }
    }
    Timer {
        id: shot
        interval: 1500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(root.shotDir + "/gluewc-" + root.page + "-" + root.screen.name + ".png"))
    }
}

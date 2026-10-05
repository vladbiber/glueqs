import Quickshell
import Quickshell.Wayland
import QtQuick

// The brightness panel under the bar widget: slider, presets, screen off, sleep mode.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 380
    implicitHeight: content.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "brightness"

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: col.implicitHeight + 36
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"
            px: 1.6; gap: 1
            color: xa.containsMouse ? Theme.red : Theme.dim
            MouseArea {
                id: xa
                anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true
                onClicked: Popups.open = ""
            }
        }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 14
            Row {
                spacing: 14
                DotText { anchors.verticalCenter: parent.verticalCenter; text: "BRIGHTNESS"; px: 1.5; gap: 1.2 }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Brightness.percent + "%"
                    px: 2.4; gap: 1.2
                    color: Brightness.percent === 0 ? Theme.red : Theme.fg
                }
            }
            Text {
                text: Brightness.device + (Brightness.writer !== "" ? "   ·   " + Brightness.writer : "")
                color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
            }
            BrightnessControls { width: parent.width }
            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }
            Row {
                width: parent.width
                spacing: 12
                Column {
                    width: parent.width - sleepToggle.width - 12
                    spacing: 3
                    DotText { text: "SLEEP MODE"; px: 1.5; gap: 1.2 }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: Settings.s.sleepEnabled
                            ? Idle.statusText
                            : "Off: the screen stays on."
                        color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
                    }
                }
                GwToggle {
                    id: sleepToggle
                    anchors.verticalCenter: parent.verticalCenter
                    bound: true
                    value: Settings.s.sleepEnabled
                    onToggled: Settings.s.sleepEnabled = !Settings.s.sleepEnabled
                }
            }
            Row {
                spacing: 10
                visible: Settings.s.sleepEnabled
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "After"
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
                }
                GwNumber {
                    bound: true; value: Settings.s.idleOffMin; min: 1; max: 120; step: 1; unit: "min"
                    onChanged: v => Settings.s.idleOffMin = Math.round(v)
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT_BRIGHTNESS") ?? "") !== "" && Brightness.available
        interval: 5200
        onTriggered: { Popups.open = "brightness"; shot.start(); }
    }
    Timer {
        id: shot
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/brightness-panel-" + root.screen.name + ".png"))
    }
}

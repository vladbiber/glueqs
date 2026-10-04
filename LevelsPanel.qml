import Quickshell
import Quickshell.Wayland
import QtQuick

// Volume and brightness side by side, under the levels tile.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: Brightness.available ? 800 : 380
    implicitHeight: content.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "levels"

    component Small: Text { color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: row.implicitHeight + 36
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"; px: 1.6; gap: 1
            color: xa.containsMouse ? Theme.red : Theme.dim
            MouseArea { id: xa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: Popups.open = "" }
        }

        Row {
            id: row
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 22

            // volume
            Column {
                width: Brightness.available ? (row.width - 22 - 1) / 2 : row.width
                spacing: 12
                Row {
                    spacing: 14
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "VOLUME"; px: 1.5; gap: 1.2 }
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: Audio.percent + "%"; px: 2.4; gap: 1.2; color: Audio.muted ? Theme.dim : Theme.fg }
                }
                Small { text: Audio.muted ? "muted" : (Audio.sink?.description ?? Audio.sink?.name ?? "default output") ; width: parent.width; elide: Text.ElideRight }
                Row {
                    width: parent.width
                    spacing: 12
                    DotIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: Audio.muted ? "volx" : Audio.volume > 0.5 ? "vol2" : Audio.volume > 0 ? "vol1" : "vol0"
                        px: 1.6; gap: 1
                        color: Audio.muted ? Theme.red : Theme.fg
                        MouseArea { anchors.fill: parent; anchors.margins: -5; onClicked: Audio.toggleMute() }
                    }
                    DotSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        dots: Math.max(10, Math.floor((parent.width - 40 - 64) / 9))
                        value: Audio.volume
                        muted: Audio.muted
                        onMoved: v => Audio.setVolume(v)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44; horizontalAlignment: Text.AlignRight
                        text: Audio.percent + "%"
                        color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 14; font.weight: Font.Medium
                    }
                }
                Row {
                    spacing: 6
                    Repeater {
                        model: [0, 25, 50, 75, 100]
                        delegate: GwButton {
                            required property int modelData
                            label: modelData + "%"; small: true
                            active: Audio.percent === modelData && !Audio.muted
                            onClicked: Audio.setVolume(modelData / 100)
                        }
                    }
                    Item { width: 10; height: 1 }
                    GwButton { label: Audio.muted ? "UNMUTE" : "MUTE"; small: true; danger: !Audio.muted; active: Audio.muted; onClicked: Audio.toggleMute() }
                }
                Row {
                    spacing: 8
                    GwButton { label: "MIXER"; small: true; onClicked: Popups.open = "volume" }
                    Small { anchors.verticalCenter: parent.verticalCenter; text: "outputs, microphone and per-app streams" }
                }
            }

            Rectangle { visible: Brightness.available; width: 1; height: row.height; color: Theme.blockBorder }

            // brightness
            Column {
                visible: Brightness.available
                width: (row.width - 22 - 1) / 2
                spacing: 12
                Row {
                    spacing: 14
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "BRIGHTNESS"; px: 1.5; gap: 1.2 }
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: Brightness.percent + "%"; px: 2.4; gap: 1.2; color: Brightness.percent === 0 ? Theme.red : Theme.fg }
                }
                Small { text: Brightness.device + (Brightness.writer !== "" ? "   ·   " + Brightness.writer : "") }
                BrightnessControls { width: parent.width }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 5200
        onTriggered: { Popups.open = "levels"; shot.start(); }
    }
    Timer {
        id: shot
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/levels-" + root.screen.name + ".png"))
    }
}

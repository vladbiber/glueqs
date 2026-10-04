import Quickshell
import Quickshell.Wayland
import QtQuick

// Bottom-center volume OSD: big dot-matrix percent + dotted level bar.
PanelWindow {
    id: root
    anchors.bottom: true
    margins.bottom: Theme.osdBottom
    implicitWidth: 280
    implicitHeight: 88
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}  // click-through
    visible: shown

    property bool shown: false

    Connections {
        target: Audio
        function onOsdTrigger() {
            if (!Settings.s.osdEnabled) return;
            root.shown = true;
            hideTimer.restart();
        }
    }
    // both OSDs sit in the same spot, so never let them stack
    Connections {
        target: Brightness
        function onOsdTrigger() { root.shown = false }
    }
    Timer { id: hideTimer; interval: Settings.s.osdDuration; onTriggered: root.shown = false }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 10

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Audio.muted ? "volx"
                        : Audio.volume > 0.5 ? "vol2"
                        : Audio.volume > 0 ? "vol1" : "vol0"
                    px: 2.4; gap: 1.2
                    color: Audio.muted ? Theme.red : Theme.fg
                }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.muted ? "MUTED" : Audio.percent + "%"
                    px: 2.4; gap: 1.2
                    color: Audio.muted ? Theme.red : Theme.fg
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: 25
                    delegate: Rectangle {
                        required property int index
                        readonly property int lit: Math.round(Audio.volume * 25)
                        width: 5; height: 5; radius: 2.5
                        color: Audio.muted ? Theme.faint
                             : index === lit - 1 ? Theme.red
                             : index < lit ? Theme.fg : Theme.faint
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 1000
        onTriggered: { root.shown = true; hideTimer.stop(); shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/osd-" + root.screen.name + ".png"))
    }
}

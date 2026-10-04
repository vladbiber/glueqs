import Quickshell
import Quickshell.Wayland
import QtQuick

// Transient toast for incoming notifications, top center.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 320
    implicitHeight: 72
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: shown

    property bool shown: false
    property var current: ({ app: "", summary: "", body: "", time: "" })

    function trunc(t, max) {
        return t.length > max ? t.slice(0, max - 1) + "." : t;
    }

    Connections {
        target: Notifs
        function onToast(n) {
            if (Popups.open === "notifs") return;
            root.current = n;
            root.shown = true;
            hideTimer.restart();
        }
    }
    Timer { id: hideTimer; interval: 5000; onTriggered: root.shown = false }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
            spacing: 5
            Item {
                width: parent.width; height: 8
                DotText {
                    anchors.left: parent.left
                    text: root.current.app.toUpperCase()
                    maxWidth: parent.width - 60
                    px: 0.8; gap: 0.8; color: Theme.red
                }
                DotText {
                    anchors.right: parent.right
                    text: root.current.time
                    px: 0.8; gap: 0.8; color: Theme.dim
                }
            }
            DotText {
                text: root.current.summary.toUpperCase()
                maxWidth: parent.width
                px: 1.2; gap: 1
            }
            DotText {
                visible: root.current.body !== ""
                text: root.current.body.toUpperCase()
                maxWidth: parent.width
                px: 0.9; gap: 0.9; color: Theme.mid
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: { root.shown = false; Popups.open = "notifs"; }
        }
    }
}

import Quickshell
import Quickshell.Wayland
import QtQuick

// IDENTIFY: each screen shows its own name and mode for a moment.
PanelWindow {
    id: root
    visible: Gluewc.identifying && Gluewc.available
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glueqs-identify"
    mask: Region {}
    implicitWidth: 420
    implicitHeight: 170
    readonly property var out: Gluewc.output(root.screen?.name ?? "")

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Theme.panel
        border.color: Theme.red
        border.width: 2
        Column {
            anchors.centerIn: parent
            spacing: 14
            DotText { anchors.horizontalCenter: parent.horizontalCenter; text: root.screen?.name ?? ""; px: 4.2; gap: 2 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.out ? root.out.pw + " × " + root.out.ph + "  @ " + root.out.hz.toFixed(0) + " Hz"
                                 + (root.out.mirror !== "none" ? "   mirror of " + root.out.mirror : "")
                               : (root.screen ? root.screen.width + " × " + root.screen.height : "")
                color: Theme.fg
                font.family: Theme.uiFont
                font.pixelSize: 16
            }
        }
    }
}

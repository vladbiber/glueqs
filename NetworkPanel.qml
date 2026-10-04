import Quickshell
import Quickshell.Wayland
import QtQuick

// The wifi and bluetooth popup; the content is NetView, shared with settings.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 420
    implicitHeight: Math.min(view.implicitHeight + 36, (root.screen?.height ?? 900) - Theme.popupTop - 24)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    readonly property bool shown: Popups.open === "net"
    visible: shown || content.opacity > 0.01

    Rectangle {
        id: content
        anchors.fill: parent
        radius: Theme.panelRadius
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1
        focus: true
        Keys.onEscapePressed: Popups.open = ""
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.96
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: Theme.ms(170); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }

        Flickable {
            anchors { fill: parent; margins: 18 }
            contentHeight: view.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            NetView { id: view; active: root.shown }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 5000
        onTriggered: { Popups.open = "net"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1800
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/net-" + root.screen.name + ".png"))
    }
}

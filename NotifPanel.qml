import Quickshell
import Quickshell.Wayland
import QtQuick

// Notification history with clear-all.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 340
    implicitHeight: 400
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "notifs"

    onVisibleChanged: if (visible) Notifs.markRead()

    function trunc(t, max) {
        return t.length > max ? t.slice(0, max - 1) + "." : t;
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            anchors { fill: parent; margins: 16 }
            spacing: 8

            Item {
                width: parent.width; height: 24
                DotText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "NOTIFICATIONS"
                    px: 1.3; gap: 1
                }
                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: 58; height: 22; radius: 6
                    color: "transparent"
                    border.color: cma.containsMouse ? Theme.red : Theme.blockBorder
                    DotText {
                        anchors.centerIn: parent
                        text: "CLEAR"
                        px: 0.9; gap: 0.9
                        color: cma.containsMouse ? Theme.red : Theme.mid
                    }
                    MouseArea {
                        id: cma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.clear()
                    }
                }
            }

            DotText {
                visible: Notifs.list.length === 0
                text: "NO NOTIFICATIONS"
                px: 1.1; gap: 1; color: Theme.dim
            }

            Column {
                width: parent.width
                spacing: 6
                Repeater {
                    model: Notifs.list.slice(0, 8)
                    delegate: Rectangle {
                        id: nrow
                        required property var modelData
                        width: parent.width
                        height: ncol.implicitHeight + 14
                        radius: 8
                        color: Theme.surface
                        border.color: Theme.blockBorder
                        border.width: 1
                        Column {
                            id: ncol
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                            spacing: 4
                            Item {
                                width: parent.width; height: 8
                                DotText {
                                    anchors.left: parent.left
                                    text: nrow.modelData.app.toUpperCase()
                                    maxWidth: parent.width - 60
                                    px: 0.8; gap: 0.8; color: Theme.red
                                }
                                DotText {
                                    anchors.right: parent.right
                                    text: nrow.modelData.time
                                    px: 0.8; gap: 0.8; color: Theme.dim
                                }
                            }
                            DotText {
                                text: nrow.modelData.summary.toUpperCase()
                                maxWidth: ncol.width
                                px: 1.1; gap: 1
                            }
                            DotText {
                                visible: nrow.modelData.body !== ""
                                text: nrow.modelData.body.toUpperCase()
                                maxWidth: ncol.width
                                px: 0.9; gap: 0.9; color: Theme.mid
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 12400
        onTriggered: { Popups.open = "notifs"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1000
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/notifs-" + root.screen.name + ".png"))
    }
}

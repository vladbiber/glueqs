import Quickshell
import Quickshell.Wayland
import QtQuick

// Session menu: logout / reboot / power off. Click once to arm ("SURE?"), again to run.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 190
    implicitHeight: rows.implicitHeight + 36
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Session.panelOpen

    onVisibleChanged: if (!visible)
        for (let i = 0; i < repeater.count; i++)
            repeater.itemAt(i).armed = false

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            id: rows
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 18 }
            spacing: 6

            Repeater {
                id: repeater
                model: Session.actions
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    property bool armed: false

                    width: rows.width
                    height: 34
                    radius: 8
                    color: area.containsMouse ? Theme.hover : "transparent"
                    border.color: armed ? Theme.red : "transparent"
                    border.width: 1

                    DotText {
                        anchors.centerIn: parent
                        text: row.armed ? "SURE?" : row.modelData.label
                        px: 1.4; gap: 1
                        color: row.armed || row.modelData.danger ? Theme.red : Theme.fg
                    }

                    Timer {
                        id: disarm
                        interval: 3000
                        onTriggered: row.armed = false
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (row.armed) {
                                Session.panelOpen = false;
                                Session.run(row.modelData.cmd);
                            } else {
                                row.armed = true;
                                disarm.restart();
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 1000
        onTriggered: { Session.panelOpen = true; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/session-" + root.screen.name + ".png"))
    }
}

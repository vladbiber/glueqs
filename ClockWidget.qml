import QtQuick
import Quickshell

Block {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property var loc: Qt.locale("en_US")
    readonly property string fmt: Settings.s.clock12h ? "h:mm" : "HH:mm"

    // how far the time text's center sits left of the block center (the date
    // column pushes it left); the bar shifts the block right by this amount
    // so the time itself lands on the exact screen center
    readonly property real centerShift:
        (!Theme.vertical && Settings.s.showDate) ? (10 + dateCol.width) / 2 : 0

    Grid {
        columns: 1

    Row {
            visible: !Theme.vertical
            spacing: 10

            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: clock.date.toLocaleTimeString(root.loc, root.fmt)
                px: Theme.pxBig; gap: 1.1
            }
            Column {
                id: dateCol
                visible: Settings.s.showDate
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                DotText {
                    text: clock.date.toLocaleDateString(root.loc, "ddd").toUpperCase()
                    px: 1; gap: 1; color: Theme.fg
                }
                DotText {
                    text: clock.date.toLocaleDateString(root.loc, "d MMM").toUpperCase()
                    px: 1; gap: 1; color: Theme.fg
                }
            }
        }

        Column {
            visible: Theme.vertical
            spacing: 3
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleTimeString(root.loc, Settings.s.clock12h ? "h" : "HH")
                px: 1.5; gap: 1
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleTimeString(root.loc, "mm")
                px: 1.5; gap: 1
            }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("calendar")
    }
}

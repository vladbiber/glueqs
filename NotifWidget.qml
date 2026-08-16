import QtQuick

// Bell with unread count. Click opens notification history.
Block {
    id: root

    Row {
        spacing: 6
        DotIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "bell"
            px: 1.6; gap: 1
            color: Notifs.unread > 0 ? Theme.red
                 : Popups.open === "notifs" ? Theme.red : Theme.fg
        }
        DotText {
            visible: Notifs.unread > 0
            anchors.verticalCenter: parent.verticalCenter
            text: String(Math.min(Notifs.unread, 99))
            px: 1.2; gap: 1
            color: Theme.red
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("notifs")
    }
}

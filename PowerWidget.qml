import QtQuick

// Power tile: opens the session menu.
Block {
    id: root

    DotIcon {
        name: "power"
        px: Theme.pxIcon; gap: 1
        color: Session.panelOpen ? Theme.fg : Theme.red
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Session.panelOpen = !Session.panelOpen
    }
}

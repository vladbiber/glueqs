import QtQuick

// App launcher button (dot grid).
Block {
    id: root

    DotIcon {
        name: "grid"
        px: Theme.pxIcon; gap: 2
        color: Popups.open === "launcher" ? Theme.red : Theme.fg
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("launcher")
    }
}

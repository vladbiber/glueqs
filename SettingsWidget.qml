import QtQuick

// Settings button (gear icon).
Block {
    id: root

    DotIcon {
        name: "gear"
        px: 1.4; gap: 1
        color: Popups.open === "settings" ? Theme.red : Theme.fg
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("settings")
    }
}

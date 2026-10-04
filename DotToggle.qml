import QtQuick

// Nothing-style toggle pill: dot slides right + red when on.
Rectangle {
    id: root
    property bool on: false
    signal toggled()

    width: 30; height: 16
    radius: 8
    color: Theme.panelSolid
    border.color: on ? Theme.red : Theme.blockBorder
    border.width: 1

    Rectangle {
        width: 10; height: 10; radius: 5
        y: 3
        x: root.on ? root.width - width - 3 : 3
        color: root.on ? Theme.red : Theme.offDot
        Behavior on x { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}

import QtQuick

// Rounded dark container, the Nothing widget "tile".
// Horizontal bar: fixed height, width from content. Vertical bar: the reverse.
Rectangle {
    default property alias content: inner.data
    property real hpad: 12

    implicitWidth: Theme.vertical ? Theme.blockHeight : inner.implicitWidth + hpad * 2
    implicitHeight: Theme.vertical ? inner.implicitHeight + hpad * 2 : Theme.blockHeight
    radius: Theme.blockRadius
    color: Theme.blockBg
    border.color: Theme.tileBorder
    border.width: 1
    Behavior on color { ColorAnimation { duration: Theme.ms(250) } }

    Item {
        id: inner
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}

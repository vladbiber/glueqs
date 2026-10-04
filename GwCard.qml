import QtQuick

// Rows that belong together sit in one card: no gap between them, a hairline
// inside, and a clear gap to the next card.
Rectangle {
    default property alias rows: col.data
    width: parent.width
    implicitHeight: col.implicitHeight + 2
    radius: 10
    color: Theme.card
    border.color: Theme.blockBorder
    border.width: 1
    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        spacing: 0
    }
}

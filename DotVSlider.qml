import QtQuick

// Vertical dotted slider for EQ bands. Middle dot marks 0 dB.
Item {
    id: root
    property real value: 0.5     // 0..1, bottom to top
    property int dots: 15
    signal moved(real v)

    implicitWidth: 16
    implicitHeight: dots * 9 - 4

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        Repeater {
            model: root.dots
            delegate: Rectangle {
                required property int index
                readonly property int lit: Math.round(root.value * root.dots)
                readonly property bool on: root.dots - index <= lit
                width: 5; height: 5; radius: 2.5
                anchors.horizontalCenter: parent.horizontalCenter
                color: on && root.dots - index === lit ? Theme.red
                     : on ? Theme.fg
                     : index === Math.floor(root.dots / 2) ? Theme.offDot : Theme.faint
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -2
        anchors.rightMargin: -2
        preventStealing: true
        function set(my) { root.moved(Math.max(0, Math.min(1, 1 - my / root.height))) }
        onPressed: mouse => set(mouse.y)
        onPositionChanged: mouse => set(mouse.y)
    }
}

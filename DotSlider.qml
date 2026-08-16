import QtQuick

// Dotted slider: click/drag to set. Head dot is accent-colored.
Item {
    id: root
    property real value: 0        // 0..1
    property int dots: 22
    property bool muted: false
    signal moved(real v)

    implicitWidth: dots * 9 - 4
    implicitHeight: 16

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: root.dots
            delegate: Rectangle {
                required property int index
                readonly property int lit: Math.round(root.value * root.dots)
                anchors.verticalCenter: parent.verticalCenter
                width: 5; height: 5; radius: 2.5
                color: root.muted ? Theme.faint
                     : index === lit - 1 ? Theme.red
                     : index < lit ? Theme.fg : Theme.faint
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function set(mx) { root.moved(Math.max(0, Math.min(1, mx / root.width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => set(mouse.x)
    }
}

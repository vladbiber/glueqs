import QtQuick

// A big quick-settings switch: icon, name and state, filled with the accent
// when on, with a ripple from where it was clicked.
Rectangle {
    id: root
    property string icon: "dot"
    property string label: ""
    property string sub: ""
    property bool on: false
    property bool busy: false
    signal clicked()

    implicitWidth: 120
    implicitHeight: 74
    radius: Theme.cardRadius + 2
    clip: true
    color: on ? Theme.red : ma.containsMouse ? Theme.hover : Theme.card
    border.color: on ? Theme.red : Theme.blockBorder
    Behavior on color { ColorAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
    scale: ma.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }

    Rectangle {
        id: ripple
        width: 0; height: width; radius: width / 2
        color: root.on ? Theme.fg : Theme.red
        opacity: 0
        ParallelAnimation {
            id: rip
            NumberAnimation { target: ripple; property: "width"; from: 0; to: root.width * 2.4; duration: Theme.ms(520); easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "opacity"; from: 0.35; to: 0; duration: Theme.ms(520) }
        }
        x: px - width / 2; y: py - width / 2
        property real px: 0
        property real py: 0
    }

    Column {
        anchors { left: parent.left; top: parent.top; margins: 12 }
        spacing: 10
        DotIcon {
            name: root.icon; px: 1.5; gap: 0.9
            color: root.on ? Theme.onAccent : Theme.fg
            SequentialAnimation on opacity {
                running: root.busy; loops: Animation.Infinite
                onRunningChanged: if (!running) parent.opacity = 1
                NumberAnimation { to: 0.25; duration: 420 }
                NumberAnimation { to: 1; duration: 420 }
            }
        }
        Column {
            spacing: 4
            DotText { text: root.label; maxWidth: root.width - 24; px: root.width > 140 ? 1.2 : 1.0; gap: root.width > 140 ? 0.8 : 0.72; color: root.on ? Theme.onAccent : Theme.fg }
            Text {
                width: root.width - 24
                text: root.sub
                elide: Text.ElideRight
                color: root.on ? Qt.alpha(Theme.onAccent, 0.75) : Theme.muted
                font.family: Theme.uiFont; font.pixelSize: 10
            }
        }
    }
    // the switch dot in the corner
    Rectangle {
        anchors { right: parent.right; top: parent.top; margins: 12 }
        width: 8; height: 8; radius: 4
        color: root.on ? Theme.onAccent : Theme.faint
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => { ripple.px = mouse.x; ripple.py = mouse.y; rip.restart(); root.clicked(); }
    }
}

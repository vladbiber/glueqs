import QtQuick

// Seamless scrolling dot text: pauses, scrolls left, snaps back (like the reference shell).
Item {
    id: root
    property string text: ""
    property real px: 1.6
    property color color: Theme.fg
    clip: true
    implicitHeight: inner.implicitHeight

    readonly property bool overflow: inner.implicitWidth > width
    readonly property real span: inner.implicitWidth + 34
    readonly property real textWidth: inner.implicitWidth

    Row {
        id: row
        spacing: 34
        DotText { id: inner; text: root.text; px: root.px; gap: 1; color: root.color }
        DotText { visible: root.overflow; text: root.text; px: root.px; gap: 1; color: root.color }
    }

    SequentialAnimation {
        running: root.overflow && root.visible
        loops: Animation.Infinite
        onStopped: row.x = 0
        PauseAnimation { duration: 2200 }
        NumberAnimation {
            target: row; property: "x"
            from: 0; to: -root.span
            duration: Math.max(2000, root.span * 22)
        }
        PropertyAction { target: row; property: "x"; value: 0 }
    }
}

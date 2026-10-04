import QtQuick
import "DotFont.js" as DotFont

// A rising wedge of dot columns, lit up to the value with the accent at the
// head. Click or drag to set, wheel to step.
Item {
    id: root
    property real value: 0
    property bool muted: false
    property int rows: 7
    property real cell: 11
    property real step: 0.05
    readonly property int cols: Math.max(6, Math.floor((width + cell * 0.35) / cell))
    signal moved(real v)

    implicitWidth: 260
    implicitHeight: rows * cell
    property real shown: value
    Behavior on shown { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }

    onShownChanged: canvas.requestPaint()
    onMutedChanged: canvas.requestPaint()
    onColsChanged: canvas.requestPaint()
    readonly property string look: String(Theme.red) + Theme.fg + Theme.faint + Theme.dotShape + Theme.dotFill
    onLookChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const n = root.cols, R = root.rows, c = root.cell, d = c * 0.6;
            const lit = root.shown * n;
            for (let i = 0; i < n; i++) {
                const h = Math.max(2, Math.round(R * (0.3 + 0.7 * i / Math.max(1, n - 1))));
                const on = i < Math.ceil(lit - 0.001) && lit > 0;
                const head = on && i === Math.ceil(lit - 0.001) - 1;
                ctx.fillStyle = root.muted ? String(Theme.faint)
                              : head ? String(Theme.red) : on ? String(Theme.fg) : String(Theme.faint);
                for (let r = 0; r < h; r++)
                    DotFont.dot(ctx, i * c + (c - d) / 2, (R - 1 - r) * c + (c - d) / 2, d * Theme.dotFill, Theme.dotShape);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function set(mx) { root.moved(Math.max(0, Math.min(1, mx / Math.max(1, root.cols * root.cell)))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}

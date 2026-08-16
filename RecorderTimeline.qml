import QtQuick

// Recorder-style timeline: red dotted trail up to a triangle playhead; click/drag seeks.
Item {
    id: root
    property real frac: 0        // 0..1
    signal seekTo(real f)
    implicitHeight: 30

    onFracChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const y = 21;
            const px = Math.max(4, Math.min(width - 4, root.frac * width));
            const red = String(Theme.red);

            for (let x = 2; x < width - 2; x += 7) {
                ctx.fillStyle = x <= px ? red : String(Theme.faint);
                ctx.beginPath();
                ctx.arc(x, y, 1.6, 0, Math.PI * 2);
                ctx.fill();
            }

            ctx.strokeStyle = red;
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.moveTo(px, 10);
            ctx.lineTo(px, 30);
            ctx.stroke();

            ctx.fillStyle = red;
            ctx.beginPath();
            ctx.moveTo(px - 6, 0);
            ctx.lineTo(px + 6, 0);
            ctx.lineTo(px, 9);
            ctx.closePath();
            ctx.fill();
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function go(mx) { root.seekTo(Math.max(0, Math.min(1, mx / root.width))) }
        onPressed: mouse => go(mouse.x)
        onPositionChanged: mouse => go(mouse.x)
    }
}

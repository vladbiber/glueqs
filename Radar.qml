import QtQuick
import "DotFont.js" as DotFont

// The wifi mark drawn as dotted arcs, lit by signal strength, with a ring
// that sweeps outward while searching or connecting.
Item {
    id: root
    property int level: 0          // 0..4 arcs lit
    property bool off: false
    property bool pulsing: false
    property real cell: 7
    implicitWidth: 112
    implicitHeight: 92

    property real t: 0
    NumberAnimation on t {
        running: root.pulsing && root.visible
        from: 0; to: 1; duration: 1400; loops: Animation.Infinite
    }
    onTChanged: canvas.requestPaint()
    onLevelChanged: canvas.requestPaint()
    onOffChanged: canvas.requestPaint()
    onPulsingChanged: canvas.requestPaint()
    readonly property string look: String(Theme.red) + Theme.fg + Theme.faint + Theme.dotShape
    onLookChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height - root.cell, d = root.cell * 0.62;
            const a0 = -Math.PI * 0.77, a1 = -Math.PI * 0.23;
            const step = (height - root.cell * 1.6) / 4;
            const wave = root.pulsing ? root.t * 4.6 : -9;
            for (let k = 1; k <= 4; k++) {
                const r = k * step;
                const n = Math.max(2, Math.round(r * (a1 - a0) / root.cell));
                const lit = !root.off && k <= root.level;
                const near = Math.max(0, 1 - Math.abs(wave - k) * 1.4);
                for (let i = 0; i <= n; i++) {
                    const a = a0 + (a1 - a0) * i / n;
                    const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r;
                    if (near > 0.05) {
                        ctx.globalAlpha = 0.35 + 0.65 * near;
                        ctx.fillStyle = String(Theme.red);
                    } else {
                        ctx.globalAlpha = 1;
                        ctx.fillStyle = lit ? String(Theme.fg) : String(Theme.faint);
                    }
                    DotFont.dot(ctx, x - d / 2, y - d / 2, d, Theme.dotShape);
                }
            }
            ctx.globalAlpha = 1;
            ctx.fillStyle = root.off ? String(Theme.faint) : String(Theme.red);
            DotFont.dot(ctx, cx - d * 0.8, cy - d * 0.8, d * 1.6, Theme.dotShape);
        }
    }
}

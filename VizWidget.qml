import QtQuick
import "DotFont.js" as DotFont

// An audio visualiser tile for the bar. The style comes from the widget id
// (viz:dots, viz:bars, viz:mirror, viz:wave, viz:line, viz:peaks), so the
// bar can carry several, each in its own style. Data from Spectrum.
Block {
    id: root
    property string style: "dots"
    hpad: 8

    readonly property int n: Math.max(4, Settings.s.vizBars)
    readonly property bool idle: !(MediaService.active?.isPlaying ?? false)
    visible: !(Settings.s.vizHideIdle && idle)

    Component.onCompleted: Spectrum.acquire()
    Component.onDestruction: Spectrum.release()

    // the spectrum folded down to n values, low notes on the left
    readonly property var vals: {
        const src = Spectrum.values;
        const out = [];
        if (!src || src.length === 0) { for (let i = 0; i < n; i++) out.push(0); return out; }
        for (let i = 0; i < n; i++) {
            const a = Math.floor(i * src.length / n), b = Math.max(a + 1, Math.floor((i + 1) * src.length / n));
            let m = 0;
            for (let j = a; j < b; j++) m = Math.max(m, src[j] ?? 0);
            out.push(m);
        }
        return out;
    }
    // falling peak markers for the peaks style
    property var peaks: []
    onValsChanged: {
        if (style === "peaks") {
            const p = peaks.length === n ? peaks.slice() : vals.slice();
            for (let i = 0; i < n; i++) p[i] = Math.max(vals[i], (p[i] ?? 0) - 0.03);
            peaks = p;
        }
        canvas.requestPaint();
    }

    function colorAt(v) {
        switch (Settings.s.vizColor) {
        case "text": return String(Theme.fg);
        case "gradient": return String(Qt.tint(Theme.fg, Qt.alpha(Theme.red, Math.min(1, v * 1.3))));
        default: return String(Theme.red);
        }
    }

    Item {
        width: Theme.vertical ? Theme.blockHeight - 12 : Settings.s.vizWidth
        height: Theme.vertical ? Settings.s.vizWidth : Theme.blockHeight - 14

        Canvas {
            id: canvas
            anchors.fill: parent
            readonly property string key: Theme.dotShape + Settings.s.vizColor + Theme.red + Theme.fg + Theme.faint
            onKeyChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const vert = Theme.vertical;
                // draw in "long axis = x" space, rotated for a vertical bar
                const L = vert ? height : width, S = vert ? width : height;
                if (vert) { ctx.translate(width, 0); ctx.rotate(Math.PI / 2); }
                const n = root.n, v = root.vals, slot = L / n;
                switch (root.style) {
                case "bars":
                    for (let i = 0; i < n; i++) {
                        const h = Math.max(1.5, v[i] * S);
                        ctx.fillStyle = root.colorAt(v[i]);
                        ctx.fillRect(i * slot + slot * 0.2, S - h, slot * 0.6, h);
                    }
                    break;
                case "mirror":
                    for (let i = 0; i < n; i++) {
                        const h = Math.max(1.5, v[i] * S);
                        ctx.fillStyle = root.colorAt(v[i]);
                        ctx.fillRect(i * slot + slot * 0.2, (S - h) / 2, slot * 0.6, h);
                    }
                    break;
                case "wave":
                case "line": {
                    const pts = [];
                    for (let i = 0; i < n; i++) pts.push([i * slot + slot / 2, v[i]]);
                    const y = a => S / 2 - a * S / 2;
                    ctx.beginPath();
                    ctx.moveTo(0, y(0));
                    for (let i = 0; i < n; i++) {
                        const px = i === 0 ? 0 : pts[i - 1][0], py = i === 0 ? y(0) : y(pts[i - 1][1]);
                        const mx = (px + pts[i][0]) / 2;
                        ctx.bezierCurveTo(mx, py, mx, y(pts[i][1]), pts[i][0], y(pts[i][1]));
                    }
                    ctx.bezierCurveTo(L - slot / 4, y(pts[n - 1][1]), L - slot / 4, y(0), L, y(0));
                    if (root.style === "line") {
                        ctx.strokeStyle = root.colorAt(0.6);
                        ctx.lineWidth = 2;
                        ctx.stroke();
                    } else {
                        // the same curve mirrored below the centre line
                        for (let i = n - 1; i >= 0; i--) {
                            const nx = i === 0 ? 0 : pts[i - 1][0];
                            const ny = i === 0 ? S / 2 : S / 2 + pts[i - 1][1] * S / 2;
                            const cy = S / 2 + pts[i][1] * S / 2;
                            const mx = (nx + pts[i][0]) / 2;
                            if (i === n - 1) ctx.lineTo(pts[i][0], cy);
                            ctx.bezierCurveTo(mx, cy, mx, ny, nx, ny);
                        }
                        ctx.closePath();
                        ctx.fillStyle = root.colorAt(0.6);
                        ctx.fill();
                    }
                    break;
                }
                case "peaks":
                    for (let i = 0; i < n; i++) {
                        const h = v[i] * S;
                        ctx.fillStyle = String(Qt.alpha(Theme.fg, 0.35));
                        ctx.fillRect(i * slot + slot * 0.2, S - h, slot * 0.6, h);
                        ctx.fillStyle = root.colorAt(1);
                        ctx.fillRect(i * slot + slot * 0.15, S - Math.max(2, (root.peaks[i] ?? 0) * S) , slot * 0.7, 2);
                    }
                    break;
                default: {
                    // dot matrix columns, the Nothing look
                    const rows = Math.max(3, Math.floor(S / Math.max(3, slot)));
                    const cell = Math.min(slot, S / rows);
                    const d = cell * 0.72;
                    for (let i = 0; i < n; i++) {
                        const lit = Math.round(v[i] * rows);
                        for (let r = 0; r < rows; r++) {
                            const on = r < lit;
                            ctx.fillStyle = on ? (r === lit - 1 ? String(Theme.red) : (Settings.s.vizColor === "accent" ? String(Theme.fg) : root.colorAt(r / rows)))
                                               : String(Theme.faint);
                            DotFont.dot(ctx, i * slot + (slot - d) / 2, S - (r + 1) * cell + (cell - d) / 2, d, Theme.dotShape);
                        }
                    }
                }
                }
            }
        }
    }
}

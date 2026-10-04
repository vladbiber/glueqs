import QtQuick

// Nothing Recorder-style reel: red disc with rotating dashes, belt to a "1x" pulley.
// Album art spins inside the disc, clipped to a circle.
Item {
    id: root
    property bool spinning: false
    property real rate: 1
    property string artUrl: ""
    implicitWidth: 160
    implicitHeight: 100

    property real angle: 0
    NumberAnimation on angle {
        running: root.spinning && root.visible
        loops: Animation.Infinite
        from: 0; to: 360
        duration: 2600
    }
    onAngleChanged: canvas.requestPaint()
    onArtUrlChanged: {
        if (artUrl !== "") canvas.loadImage(artUrl);
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onImageLoaded: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = 50, cy = 50, R = 44;
            const pcx = 132, pcy = 40, pr = 17;
            const rot = root.angle * Math.PI / 180;

            // belt + pulley + tension wheel (gray mechanics)
            ctx.strokeStyle = String(Theme.strong);
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(cx + R * 0.45, cy - R * 0.89);
            ctx.lineTo(pcx + 2, pcy - pr);
            ctx.moveTo(cx + R * 0.45, cy + R * 0.89);
            ctx.lineTo(pcx - 14, pcy + pr + 26);
            ctx.moveTo(pcx + pr, pcy);
            ctx.lineTo(pcx - 8, pcy + pr + 24);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(pcx, pcy, pr, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(pcx - 12, pcy + pr + 27, 7, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = String(Theme.strong);
            ctx.beginPath();
            ctx.arc(pcx - 12, pcy + pr + 27, 1.6, 0, Math.PI * 2);
            ctx.fill();

            // album art spinning inside the disc, circular clip + slight darken
            if (root.artUrl !== "" && canvas.isImageLoaded(root.artUrl)) {
                ctx.save();
                ctx.beginPath();
                ctx.arc(cx, cy, R - 3, 0, Math.PI * 2);
                ctx.clip();
                ctx.translate(cx, cy);
                ctx.rotate(rot);
                ctx.drawImage(root.artUrl, -(R - 3), -(R - 3), (R - 3) * 2, (R - 3) * 2);
                ctx.rotate(-rot);
                ctx.fillStyle = "rgba(0,0,0,0.30)";
                ctx.beginPath();
                ctx.arc(0, 0, R - 3, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }

            // disc rim + hub
            const red = String(Theme.red);
            ctx.strokeStyle = red;
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.arc(cx, cy, R, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = String(Theme.panelSolid);
            ctx.beginPath();
            ctx.arc(cx, cy, 15, 0, Math.PI * 2);
            ctx.fill();
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.arc(cx, cy, 15, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillStyle = red;
            ctx.beginPath();
            ctx.arc(cx, cy, 6.5, 0, Math.PI * 2);
            ctx.fill();

            // two tangential dashes rotating with the disc
            ctx.strokeStyle = red;
            ctx.lineWidth = 3;
            for (let k = 0; k < 2; k++) {
                const a = rot + k * Math.PI;
                const mx = cx + 28 * Math.cos(a);
                const my = cy + 28 * Math.sin(a);
                const dx = -Math.sin(a) * 10, dy = Math.cos(a) * 10;
                ctx.beginPath();
                ctx.moveTo(mx - dx, my - dy);
                ctx.lineTo(mx + dx, my + dy);
                ctx.stroke();
            }
        }
    }

    DotText {
        x: 132 - implicitWidth / 2
        y: 40 - implicitHeight / 2
        text: Math.round(root.rate) + "X"
        px: 1; gap: 1
        color: Theme.mid
    }
}

import QtQuick
import "DotFont.js" as DotFont

// Renders text as a grid of round dots, NDot style. With the dot font switched
// off in settings it falls back to a plain label sized to the same cap height,
// so every caller keeps its layout either way.
Item {
    id: root
    property string text: ""
    property real px: 2        // dot diameter
    property real gap: 1       // space between dots
    property color color: Theme.fg
    property color offColor: "transparent"  // set to paint unlit dots faintly
    // > 0: text wider than this is cut and ends in an ellipsis, in both
    // renderings, so a long name can never run out of its tile
    property real maxWidth: 0

    readonly property real cell: px + gap
    readonly property real dotHeight: 7 * cell - gap
    readonly property bool dotted: Settings.s.dotFont

    // true when maxWidth cut the text short
    readonly property bool cut: dotted ? shown !== text : label.truncated

    // what is actually drawn in dot mode
    readonly property string shown: maxWidth > 0 && dotted
        ? DotFont.fitCells(text, Math.floor((maxWidth + gap) / cell))
        : text

    implicitWidth: dotted ? Math.max(1, DotFont.textCells(shown) * cell - gap)
                          : Math.max(1, maxWidth > 0
                                ? Math.min(label.implicitWidth, maxWidth)
                                : label.implicitWidth)
    // the plain label keeps the dot font's box height so both modes sit in the
    // same place; a font's own implicitHeight includes descenders and would
    // push all-caps text off centre against the icons next to it
    implicitHeight: dotHeight

    onShownChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onPxChanged: canvas.requestPaint()
    onGapChanged: canvas.requestPaint()
    readonly property string shapeKey: Theme.dotShape + Theme.dotFill
    onShapeKeyChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.dotted

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!root.dotted)
                return;
            const px = root.px, cell = root.cell;
            const r = px / 2;
            let cx = 0;
            const drawDot = (col, row, on) => {
                if (!on && root.offColor.a === 0) return;
                ctx.fillStyle = on ? String(root.color) : String(root.offColor);
                DotFont.dot(ctx, col * cell + px * (1 - Theme.dotFill) / 2, row * cell + px * (1 - Theme.dotFill) / 2, px * Theme.dotFill, Theme.dotShape);
            };
            for (let i = 0; i < root.shown.length; i++) {
                const g = DotFont.glyph(root.shown[i]);
                const w = g[0].length;
                for (let row = 0; row < 7; row++)
                    for (let col = 0; col < w; col++)
                        drawDot(cx + col, row, g[row][col] === "1");
                cx += w + 1;
            }
        }
    }

    // The dot glyphs are 7 rows of caps. Centring the label by its own box
    // would sit the caps high, because the box reserves room for descenders
    // this all-caps text never uses, and the overflow got clipped by parents
    // like the marquee. So place it by its baseline instead: the cap band ends
    // up exactly where the dot rows would be.
    FontMetrics {
        id: fm
        font: label.font
    }
    Text {
        id: label
        visible: !root.dotted
        y: Math.round((root.dotHeight + fm.capitalHeight) / 2 - fm.ascent)
        text: root.text
        color: root.color
        // bound only while there is a limit: tying width to implicitWidth
        // with elide on is a binding loop
        elide: root.maxWidth > 0 ? Text.ElideRight : Text.ElideNone
        Binding {
            target: label; property: "width"
            value: root.maxWidth
            when: root.maxWidth > 0
            restoreMode: Binding.RestoreBindingOrValue
        }
        font.family: Theme.uiFont
        font.pixelSize: Math.max(7, Math.round(root.dotHeight * 1.15))
        font.weight: Theme.fontWeight
        font.letterSpacing: Math.max(0, root.gap * 0.3)
        renderType: Text.NativeRendering
    }
}

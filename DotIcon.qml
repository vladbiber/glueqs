import QtQuick
import "DotFont.js" as DotFont

// Renders a named bitmap from DotFont.ICONS as round dots. With the dot font
// switched off it draws the matching Nerd Font glyph instead, at the same size.
Item {
    id: root
    property string name: "dot"
    property real px: 2
    property real gap: 1
    property color color: Theme.fg

    readonly property real cell: px + gap
    readonly property var bitmap: DotFont.ICONS[name] ?? DotFont.ICONS.dot
    readonly property bool dotted: Settings.s.dotFont

    implicitWidth: dotted ? bitmap[0].length * cell - gap : Math.max(1, glyph.implicitWidth)
    // same box height in both modes, so icons line up with the text beside them
    implicitHeight: bitmap.length * cell - gap

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onPxChanged: canvas.requestPaint()
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
            const px = root.px, cell = root.cell, bitmap = root.bitmap;
            ctx.fillStyle = String(root.color);
            const r = px / 2;
            for (let row = 0; row < bitmap.length; row++)
                for (let col = 0; col < bitmap[row].length; col++)
                    if (bitmap[row][col] === "1") {
                        DotFont.dot(ctx, col * cell, row * cell, px * Theme.dotFill, Theme.dotShape);
                    }
        }
    }

    Text {
        id: glyph
        anchors.centerIn: parent
        visible: !root.dotted
        text: DotFont.nfIcon(root.name)
        color: root.color
        font.family: Theme.iconFont
        // the dot icons are 7 rows tall, so match that as the glyph height
        font.pixelSize: Math.max(9, Math.round((7 * root.cell - root.gap) * 1.2))
        renderType: Text.NativeRendering
    }
}

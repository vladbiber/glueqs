import QtQuick
import "DotFont.js" as DotFont

// LOOK: dots, fonts, scale, corners, see-through and motion.
Column {
    id: page
    width: parent.width
    spacing: 0

    // ---- dots ----
    GwTitle { first: true; text: "DOTS"; sub: "The dot-matrix lettering and icons. Off shows plain text in the font below." }
    GwCard {
        SToggle { label: "Dot-matrix font"; hint: "Dots in the bar, the panels and the headings"; skey: "dotFont" }
    }
    Grid {
        id: shapes
        width: parent.width
        columns: 5
        spacing: 10
        topPadding: 12
        readonly property real cw: (width - spacing * 4) / 5
        Repeater {
            model: [{ v: "round", n: "ROUND" }, { v: "square", n: "SQUARE" }, { v: "rounded", n: "SOFT" }, { v: "diamond", n: "DIAMOND" }, { v: "bar", n: "LED" }]
            delegate: Rectangle {
                id: sh
                required property var modelData
                readonly property bool on: Settings.s.dotShape === modelData.v
                width: shapes.cw; height: 92
                radius: Theme.cardRadius
                color: sma.containsMouse ? Theme.hover : Theme.card
                border.color: on ? Theme.red : Theme.border
                border.width: on ? 2 : 1
                Canvas {
                    id: cv
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 14 }
                    width: 60; height: 42
                    readonly property string key: sh.modelData.v + Theme.fg + Theme.red + Settings.s.dotFill
                    onKeyChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        // "A" plus a lit dot, at a size where the shape reads
                        const g = DotFont.glyph("A");
                        const cell = 6, d = 4.6 * Settings.s.dotFill;
                        for (let r = 0; r < 7; r++)
                            for (let c = 0; c < g[r].length; c++)
                                if (g[r][c] === "1") {
                                    ctx.fillStyle = String(Theme.fg);
                                    DotFont.dot(ctx, c * cell, r * cell, d, sh.modelData.v);
                                }
                        ctx.fillStyle = String(Theme.red);
                        DotFont.dot(ctx, 6 * cell + 6, 6 * cell, d, sh.modelData.v);
                    }
                }
                Text {
                    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 10 }
                    text: sh.modelData.n; color: sh.on ? Theme.red : Theme.fg
                    font.family: Theme.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold
                }
                MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.s.dotShape = sh.modelData.v }
            }
        }
    }
    Item { width: 1; height: 10 }
    GwCard {
        GwRow { label: "Dot size"; hint: "How much of its cell each dot fills"
            GwNumber { bound: true; value: Settings.s.dotFill; min: 0.6; max: 1.2; step: 0.05; decimals: 2; unit: "×"; onChanged: v => Settings.s.dotFill = Math.round(v * 20) / 20 }
        }
    }

    // ---- fonts ----
    GwTitle { text: "FONT"; sub: "For plain text: hints, fields, and everything when the dot font is off." }
    readonly property var curated: ["JetBrains Mono", "Iosevka", "CaskaydiaCove Nerd Font", "DejaVu Sans Mono", "Liberation Mono",
                                    "Noto Sans", "DejaVu Sans", "Liberation Sans", "Nimbus Sans", "Noto Serif", "Nimbus Roman", "Noto Sans Mono"]
    readonly property var installed: Qt.fontFamilies()
    readonly property var shown: {
        const q = fontSearch.draft.trim().toLowerCase();
        if (q === "") return curated.filter(f => installed.includes(f));
        return installed.filter(f => f.toLowerCase().includes(q)).slice(0, 24);
    }
    Row {
        spacing: 10
        bottomPadding: 10
        GwField { id: fontSearch; width: 260; placeholder: "search all " + page.installed.length + " fonts" }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "now: " + Theme.uiFont; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
    }
    Grid {
        id: fonts
        width: parent.width
        columns: 3
        spacing: 8
        readonly property real cw: (width - spacing * 2) / 3
        Repeater {
            model: page.shown
            delegate: Rectangle {
                id: fc
                required property string modelData
                readonly property bool on: Theme.uiFont === modelData
                width: fonts.cw; height: 62
                radius: Theme.cardRadius
                color: fma.containsMouse ? Theme.hover : Theme.card
                border.color: on ? Theme.red : Theme.border
                border.width: on ? 2 : 1
                Text {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                    text: "Aa 12:45 Glue"
                    elide: Text.ElideRight
                    color: Theme.fg; font.family: fc.modelData; font.pixelSize: 17; font.weight: Theme.fontWeight
                }
                Text {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 8 }
                    text: fc.modelData; elide: Text.ElideRight
                    color: fc.on ? Theme.red : Theme.muted; font.family: Theme.uiFont; font.pixelSize: 10
                }
                MouseArea { id: fma; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.s.uiFont = fc.modelData }
            }
        }
    }
    Item { width: 1; height: 10 }
    GwCard {
        GwRow { label: "Weight"
            GwChoice {
                bound: true; value: String(Settings.s.fontWeight)
                options: [{ v: "300", label: "LIGHT" }, { v: "400", label: "REGULAR" }, { v: "500", label: "MEDIUM" }, { v: "600", label: "SEMIBOLD" }, { v: "700", label: "BOLD" }]
                onPicked: v => Settings.s.fontWeight = parseInt(v)
            }
        }
    }

    // ---- shape ----
    GwTitle { text: "SHAPE"; sub: "Scale, corners, outlines and how much shows through." }
    GwCard {
        GwRow { label: "UI scale"; hint: "Bar, tiles and dot fonts"
            GwNumber { bound: true; value: Settings.s.scale; min: 0.85; max: 1.3; step: 0.05; decimals: 2; unit: "×"; onChanged: v => Settings.s.scale = Math.round(v * 20) / 20 }
        }
        GwRow { label: "Corner radius"; hint: "Tiles and cards; panels a little rounder"
            Row {
                spacing: 12
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 34; height: 24; radius: Math.min(12, Settings.s.radius); color: Theme.surface; border.color: Theme.red }
                GwNumber { bound: true; value: Settings.s.radius; min: 0; max: 20; step: 1; unit: "px"; onChanged: v => Settings.s.radius = Math.round(v) }
            }
        }
        SToggle { label: "Tile outlines"; hint: "A hairline around each bar tile"; skey: "borders" }
        GwRow { label: "Tile opacity"; hint: "Lower lets the wallpaper through the bar tiles"
            GwNumber { bound: true; value: Settings.s.tileOpacity; min: 0.2; max: 1; step: 0.05; decimals: 2; onChanged: v => Settings.s.tileOpacity = Math.round(v * 20) / 20 }
        }
        GwRow { label: "Panel opacity"; hint: "Popups, the settings and a solid bar"
            GwNumber { bound: true; value: Settings.s.panelOpacity; min: 0.5; max: 1; step: 0.05; decimals: 2; onChanged: v => Settings.s.panelOpacity = Math.round(v * 20) / 20 }
        }
    }

    // ---- motion ----
    GwTitle { text: "MOTION"; sub: "Speed of the panels, highlights and colour changes." }
    GwCard {
        GwRow { label: "Animations"
            GwChoice {
                bound: true; value: String(Settings.s.animSpeed)
                options: [{ v: "0", label: "OFF" }, { v: "0.6", label: "SLOW" }, { v: "1", label: "NORMAL" }, { v: "1.6", label: "FAST" }]
                onPicked: v => Settings.s.animSpeed = parseFloat(v)
            }
        }
    }
}

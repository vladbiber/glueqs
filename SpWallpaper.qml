import Quickshell
import QtQuick

// WALLPAPER: a live band of slanted previews from the shuffle folder, the
// picker, and the options it shares.
Column {
    id: page
    width: parent.width
    spacing: 0
    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    function shortDir(p) { return p.startsWith(homeDir) ? "~" + p.slice(homeDir.length) : p }
    Component.onCompleted: WallThumbs.load(Wallpapers.dir)

    // the pictures around the current one, slanted like the picker's cards
    readonly property var around: {
        WallThumbs.version;
        const f = Wallpapers.files;
        if (f.length === 0) return [];
        const i = Math.max(0, f.indexOf(Settings.s.wallpaper));
        const out = [];
        for (let d = -3; d <= 3; d++) out.push(f[((i + d) % f.length + f.length) % f.length]);
        return out;
    }

    GwTitle { first: true; text: "PICTURE"; sub: "Click a card to put it on every screen. The picker (Mod+W) has them all, with colour filters and search." }
    Item {
        width: parent.width
        height: 210
        clip: true
        Row {
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: page.around
                delegate: Item {
                    id: c
                    required property string modelData
                    required property int index
                    readonly property bool mid: index === 3
                    width: mid ? 230 : 70; height: mid ? 190 : 170
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: mid ? 1 : ca.containsMouse ? 0.9 : 0.55
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
                    Item {
                        anchors.fill: parent
                        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -0.3, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        Rectangle { anchors.fill: parent; color: c.mid ? Theme.red : WallThumbs.colors[c.modelData] ? "#" + WallThumbs.colors[c.modelData] : Theme.border }
                        Item {
                            anchors { fill: parent; margins: 3 }
                            clip: true
                            Image {
                                anchors.centerIn: parent
                                width: 300; height: 190
                                fillMode: Image.PreserveAspectCrop
                                source: "file://" + WallThumbs.thumb(c.modelData)
                                sourceSize.height: 240
                                asynchronous: true
                                transform: Matrix4x4 { matrix: Qt.matrix4x4(1, 0.3, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                            }
                        }
                        MouseArea { id: ca; anchors.fill: parent; hoverEnabled: true; onClicked: Wallpapers.set(c.modelData, "") }
                    }
                }
            }
        }
        DotText { visible: page.around.length === 0; anchors.centerIn: parent; text: "NO PICTURES IN THE SHUFFLE FOLDER"; px: 1; gap: 0.9; color: Theme.muted }
    }
    Row {
        spacing: 8
        topPadding: 4
        GwButton { label: "OPEN THE PICKER   (MOD+W)"; active: true; onClicked: Popups.open = "wallpaper" }
        GwButton { label: "PREVIOUS"; onClicked: { const f = Wallpapers.files; const i = f.indexOf(Settings.s.wallpaper); if (f.length) Wallpapers.set(f[(i - 1 + f.length) % f.length], ""); } }
        GwButton { label: "NEXT"; onClicked: Wallpapers.next("") }
        GwButton { label: "RANDOM"; onClicked: Wallpapers.random("") }
    }

    GwTitle { text: "OPTIONS"; sub: "The shell paints the wallpaper itself, no swww or waypaper needed." }
    GwCard {
        GwRow { label: "Shuffle folder"; hint: page.shortDir(Wallpapers.dir) + "   ·   " + Wallpapers.files.length + " pictures"
            GwField {
                width: 220
                text: Settings.s.wallpaperDir
                placeholder: "~/Pictures/Wallpapers"
                onCommitted: v => { let p = v.trim(); if (p.startsWith("~")) p = page.homeDir + p.slice(1); Settings.s.wallpaperDir = p; }
            }
        }
        GwRow { label: "Fill"
            GwChoice {
                bound: true; value: Settings.s.wallpaperFill
                options: [{ v: "crop", label: "CROP" }, { v: "fit", label: "FIT" }, { v: "stretch", label: "STRETCH" }, { v: "center", label: "CENTER" }, { v: "tile", label: "TILE" }]
                onPicked: v => Settings.s.wallpaperFill = v
            }
        }
        GwRow { label: "Transition"
            GwChoice {
                bound: true; value: Settings.s.wallpaperTransition
                options: [{ v: "fade", label: "FADE" }, { v: "wipe", label: "WIPE" }, { v: "slide", label: "SLIDE" }, { v: "zoom", label: "ZOOM" }, { v: "random", label: "RANDOM" }]
                onPicked: v => Settings.s.wallpaperTransition = v
            }
        }
        GwRow { label: "Transition time"
            GwNumber { bound: true; value: Settings.s.wallpaperTransitionMs; min: 0; max: 3000; step: 100; unit: "ms"; onChanged: v => Settings.s.wallpaperTransitionMs = Math.round(v) }
        }
        GwRow { label: "Shuffle every"; hint: "0 turns the random change off"
            GwNumber { bound: true; value: Settings.s.wallpaperRandomMin; min: 0; max: 240; step: 5; unit: "min"; onChanged: v => Settings.s.wallpaperRandomMin = Math.round(v) }
        }
        GwRow { label: "Behind the picture"; hint: "Also the colour on its own without one"
            Swatches { skey: "wallpaperSolid"; colors: ["#000000", "#241f31", "#1a1a2e", "#101820", "#f2f2f2"] }
        }
        GwRow { label: "Shell colours from the wallpaper"; hint: "Choose the palette style and image colours on the THEME page"
            GwToggle { bound: true; value: Settings.s.themeScheme === "wallpaper"
                       onToggled: { Settings.s.themeScheme = Settings.s.themeScheme === "wallpaper" ? "nothing" : "wallpaper"; Settings.s.accent = ""; } }
        }
    }
}

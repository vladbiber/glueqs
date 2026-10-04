import QtQuick
import "Palettes.js" as Palettes

// THEME: colour schemes as cards painted in their own colours, the scheme
// taken from the wallpaper, a custom scheme with every slot editable, and
// the accent on its own.
Column {
    id: page
    width: parent.width
    spacing: 0

    function pick(id) {
        Settings.s.themeScheme = id;
        Settings.s.accent = "";
    }
    readonly property var custom: Palettes.parse(Settings.s.themeCustom)
    function setCustom(k, v) {
        const c = Palettes.parse(Settings.s.themeCustom);
        c[k] = v;
        delete c.dark;
        Settings.s.themeCustom = JSON.stringify(c);
    }
    function copyToCustom() {
        const c = {};
        for (const k of Palettes.KEYS) c[k] = String(k === "accent" ? Theme.red : Theme.p[k]).slice(0, 7);
        Settings.s.themeCustom = JSON.stringify(c);
        Settings.s.themeScheme = "custom";
        Settings.s.accent = "";
    }

    // a small mock of the shell in a scheme's colours
    component Preview: Rectangle {
        id: pv
        property var s: Palettes.SCHEMES[0]
        radius: 10
        color: s.bg
        clip: true
        // bar
        Row {
            x: 8; y: 8
            spacing: 4
            Repeater {
                model: [26, 18, 40, 18]
                delegate: Rectangle {
                    required property int modelData
                    required property int index
                    width: modelData; height: 14; radius: 4
                    color: pv.s.surface; border.color: pv.s.border
                    Rectangle {
                        visible: index === 2
                        anchors.centerIn: parent
                        width: 22; height: 4; radius: 2; color: pv.s.fg
                    }
                    Rectangle {
                        visible: index === 0
                        anchors.centerIn: parent
                        width: 6; height: 6; radius: 3; color: pv.s.accent
                    }
                }
            }
        }
        // panel with a card and an accent switch
        Rectangle {
            x: 8; y: 28
            width: parent.width - 16; height: parent.height - 36
            radius: 6
            color: pv.s.panel; border.color: pv.s.border
            Column {
                x: 7; y: 7
                spacing: 4
                Rectangle { width: 46; height: 4; radius: 2; color: pv.s.accent }
                Rectangle { width: 70; height: 3; radius: 1.5; color: pv.s.fg }
                Rectangle { width: 54; height: 3; radius: 1.5; color: pv.s.muted }
            }
            Rectangle {
                anchors { right: parent.right; bottom: parent.bottom; margins: 7 }
                width: 20; height: 10; radius: 5
                color: pv.s.accent
                Rectangle { x: 11; y: 1; width: 8; height: 8; radius: 4; color: pv.s.bg }
            }
        }
    }

    component SchemeCard: Rectangle {
        id: sc
        property var s: Palettes.SCHEMES[0]
        property string sid: s.id
        property string name: s.name
        readonly property bool on: Settings.s.themeScheme === sid
        width: grid.cw; height: 128
        radius: Theme.cardRadius
        color: Theme.card
        border.color: on ? Theme.red : sma.containsMouse ? Theme.strong : Theme.border
        border.width: on ? 2 : 1
        scale: sma.containsMouse ? 1.03 : 1
        z: sma.containsMouse ? 2 : 0
        Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: Theme.ms(160) } }
        Preview { anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 } height: 84; s: sc.s }
        Text {
            anchors { left: parent.left; bottom: parent.bottom; margins: 10; bottomMargin: 9 }
            text: sc.name; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.Medium
        }
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 11 }
            spacing: 3
            Repeater {
                model: [sc.s.accent, sc.s.fg, sc.s.muted, sc.s.surface]
                delegate: Rectangle { required property string modelData; width: 9; height: 9; radius: 4.5; color: modelData; border.color: Theme.border }
            }
        }
        MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: page.pick(sc.sid) }
    }

    GwTitle { first: true; text: "SCHEMES"; sub: "Every colour of the shell at once. The accent follows the scheme unless you pick one below." }
    Grid {
        id: grid
        width: parent.width
        columns: 4
        spacing: 10
        readonly property real cw: (width - spacing * (columns - 1)) / columns
        Repeater {
            model: Palettes.SCHEMES
            delegate: SchemeCard { required property var modelData; s: modelData }
        }
        SchemeCard {
            sid: "wallpaper"; name: Theme.matugenOk ? "From wallpaper" : "Wallpaper (no matugen)"
            s: Theme.wallScheme ?? Palettes.SCHEMES[0]
            opacity: Theme.matugenOk ? 1 : 0.45
            enabled: Theme.matugenOk
        }
        SchemeCard { sid: "custom"; name: "Custom"; s: page.custom }
    }

    // ---- the wallpaper scheme ----
    GwTitle { visible: Settings.s.themeScheme === "wallpaper"; text: "FROM THE WALLPAPER"; sub: "matugen reads the picture on screen and builds the scheme; it follows every wallpaper change." }
    GwCard {
        visible: Settings.s.themeScheme === "wallpaper"
        GwRow { label: "Mode"
            GwChoice {
                bound: true; value: Settings.s.wallpaperSchemeMode
                options: [{ v: "dark", label: "DARK" }, { v: "light", label: "LIGHT" }]
                onPicked: v => Settings.s.wallpaperSchemeMode = v
            }
        }
        GwRow { label: "Style"; hint: "How far the colours stray from the picture"
            GwChoice {
                bound: true; value: Settings.s.wallpaperSchemeType
                options: [{ v: "scheme-tonal-spot", label: "TONAL" }, { v: "scheme-vibrant", label: "VIBRANT" },
                          { v: "scheme-expressive", label: "EXPRESSIVE" }, { v: "scheme-fidelity", label: "FAITHFUL" },
                          { v: "scheme-monochrome", label: "MONO" }]
                onPicked: v => Settings.s.wallpaperSchemeType = v
            }
        }
    }

    // ---- custom ----
    GwTitle { text: "CUSTOM SCHEME"; sub: Settings.s.themeScheme === "custom" ? "Each slot of the scheme. Type a hex code, Enter applies." : "Start from whatever is on screen now and change what you like." }
    GwCard {
        GwRow { label: "Start from the current colours"; hint: "Copies them into the custom scheme and switches to it"
            GwButton { label: "COPY AND EDIT"; active: Settings.s.themeScheme !== "custom"; onClicked: page.copyToCustom() }
        }
        Repeater {
            model: Settings.s.themeScheme === "custom" ? Palettes.KEYS : []
            delegate: GwRow {
                id: crow
                required property string modelData
                label: Palettes.KEY_NAMES[modelData]
                SColor { value: page.custom[crow.modelData] ?? "#000000"; onPicked: v => page.setCustom(crow.modelData, v) }
            }
        }
    }

    // ---- accent ----
    GwTitle { text: "ACCENT"; sub: "The one colour. Leave it on SCHEME to use the scheme's own." }
    GwCard {
        GwRow { label: "Accent"
            Row {
                spacing: 10
                GwButton { anchors.verticalCenter: parent.verticalCenter; small: true; label: "SCHEME"; active: Settings.s.accent === ""; onClicked: Settings.s.accent = "" }
                Swatches { skey: "accent"; colors: ["#d71921", "#ff6a00", "#f5c518", "#2ec46b", "#3dd6ff", "#2b7de3", "#8839ef", "#ff79c6", "#f2f2f2"] }
            }
        }
        GwRow { label: "Custom accent"; hint: "Any hex colour"
            SColor { value: String(Theme.red).slice(0, 7); onPicked: v => Settings.s.accent = v }
        }
    }
}

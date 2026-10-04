pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "Palettes.js" as Palettes

// Colours, fonts and sizes. The colours come from a scheme (Palettes.js), a
// custom one the user edits, or matugen run on the wallpaper; the accent can
// still be overridden on its own.
Singleton {
    id: root

    // ---- colours ----
    readonly property string schemeId: Settings.s.themeScheme
    property var wallScheme: null
    readonly property var p: {
        if (schemeId === "custom") return Palettes.parse(Settings.s.themeCustom);
        if (schemeId === "wallpaper" && wallScheme) return wallScheme;
        return Palettes.byId(schemeId);
    }
    readonly property bool dark: p.dark !== false

    readonly property color bg: p.bg
    readonly property color panel: Qt.alpha(p.panel, Settings.s.panelOpacity)
    readonly property color panelSolid: p.panel
    readonly property color card: p.card
    readonly property color surface: p.surface
    readonly property color hover: p.hover
    readonly property color line: p.line
    readonly property color strong: p.strong
    readonly property color blockBg: Qt.alpha(p.surface, Settings.s.tileOpacity)
    readonly property color blockBorder: p.border
    readonly property color tileBorder: Settings.s.borders ? p.border : "transparent"
    readonly property color border: p.border
    readonly property color fg: p.fg
    readonly property color muted: p.muted
    // the three text tiers stay on fg: depth is carried by dot size
    readonly property color mid: fg
    readonly property color dim: fg
    readonly property color hint: fg
    readonly property color faint: p.faint
    readonly property color offDot: p.muted
    // the accent: the scheme's own unless one was picked
    readonly property color red: Settings.s.accent !== "" ? Settings.s.accent : p.accent
    readonly property color redDim: Qt.darker(red, 2.3)
    readonly property color onAccent: Palettes.luminance(String(red).slice(0, 7)) > 0.6 ? "#000000" : "#ffffff"
    // a dim veil behind modal popups
    readonly property color scrim: dark ? "#99000000" : "#55000000"

    // matugen on the current wallpaper, only while that scheme is chosen
    readonly property string wallPath: Settings.s.wallpaper
    function refreshWall() { if (schemeId === "wallpaper" && wallPath !== "") matu.running = true }
    onWallPathChanged: refreshWall()
    onSchemeIdChanged: refreshWall()
    readonly property string wallKnobs: Settings.s.wallpaperSchemeMode + Settings.s.wallpaperSchemeType
    onWallKnobsChanged: refreshWall()
    Component.onCompleted: refreshWall()
    Process {
        id: matu
        command: ["sh", "-c",
            'PATH="$HOME/.local/bin:$PATH"; command -v matugen >/dev/null || exit 3; '
            + 'matugen image "$1" --json hex --dry-run -m "$2" -t "$3" --prefer saturation 2>/dev/null',
            "glueqs", root.wallPath, Settings.s.wallpaperSchemeMode, Settings.s.wallpaperSchemeType]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const mode = Settings.s.wallpaperSchemeMode;
                    const c = {};
                    for (const k in j.colors) {
                        const v = j.colors[k];
                        c[k] = typeof v === "string" ? v : (v[mode]?.color ?? v.default?.color ?? "");
                    }
                    root.wallScheme = Palettes.fromMaterial(c, mode !== "light");
                } catch (e) {
                    console.warn("glueqs: matugen output not understood: " + e);
                }
            }
        }
    }
    readonly property bool matugenOk: matuCheck.ok
    Process {
        id: matuCheck
        property bool ok: false
        running: true
        command: ["sh", "-c", 'PATH="$HOME/.local/bin:$PATH"; command -v matugen >/dev/null']
        onExited: code => ok = code === 0
    }

    // ---- fonts ----
    readonly property string uiFont: Settings.s.uiFont !== "" ? Settings.s.uiFont : "JetBrains Mono"
    readonly property string iconFont: "CaskaydiaCove Nerd Font"
    readonly property int fontWeight: Settings.s.fontWeight
    // dot shape: round | square | diamond | bar
    readonly property string dotShape: Settings.s.dotShape
    readonly property real dotFill: Settings.s.dotFill

    // ---- sizes ----
    readonly property real scale: Math.max(0.8, Math.min(1.4, Settings.s.scale))
    readonly property int barHeight: Math.round(Settings.s.barSize * scale) + barMargin * 2
    readonly property int blockHeight: Math.round((Settings.s.barSize - 10) * scale)
    readonly property int blockRadius: Math.round(Settings.s.radius * Math.min(1, blockHeight / 38))
    readonly property int panelRadius: Math.round(Settings.s.radius * 1.4)
    readonly property int cardRadius: Settings.s.radius
    readonly property int spacing: Settings.s.tileSpacing
    readonly property bool floating: Settings.s.barFloating
    readonly property int barMargin: floating ? 8 : 0

    // ---- motion ----
    readonly property real anim: Settings.s.animSpeed   // 0 = off
    function ms(base) { return anim <= 0 ? 0 : Math.round(base / anim) }

    // where popups sit relative to the bar (bar can be on any screen edge)
    readonly property string barPos: Settings.s.barPosition
    readonly property bool vertical: barPos === "left" || barPos === "right"
    readonly property int popupTop: barPos === "top" ? barHeight + 8 : 8
    readonly property int popupLeft: barPos === "left" ? barHeight + 8 : 8
    readonly property int popupRight: barPos === "right" ? barHeight + 8 : 8
    readonly property int osdBottom: barPos === "bottom" ? barHeight + 42 : 90

    // unified dot sizes across widgets
    readonly property real pxBig: 2.2 * scale    // clock time, weather temp
    readonly property real pxMed: 1.6 * scale    // percentages, titles, tag numbers
    readonly property real pxSmall: 1.0 * scale  // secondary labels
    readonly property real pxIcon: 1.8 * scale   // bar icons
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "Palettes.js" as Palettes

// Colours, fonts and sizes. The colours come from a scheme (Palettes.js), a
// custom one the user edits, or a palette extracted from the wallpaper; the accent can
// still be overridden on its own.
Singleton {
    id: root

    // ---- colours ----
    readonly property string schemeId: Settings.s.themeScheme
    property var wallScheme: null
    readonly property var p: {
        if (schemeId === "custom") return Palettes.parse(Settings.s.themeCustom);
        if (schemeId === "wallpaper") return wallScheme || Palettes.fromMaterial({ primary: "#b8b8b8" }, Settings.s.wallpaperSchemeMode !== "light");
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

    // Snapshot each request. Old extraction results never overwrite a newer
    // wallpaper, mode or seed choice; changes while busy queue one fresh run.
    readonly property string wallPath: Wallpapers.pathFor(Settings.s.wallpaperPaletteMonitor
        || (Quickshell.screens.length ? Quickshell.screens[0].name : ""))
    readonly property string wallRequest: JSON.stringify([wallPath, Settings.s.wallpaperSchemeMode,
        Settings.s.wallpaperSchemeType, Settings.s.wallpaperSeed])
    property string wallApplied: ""
    property string wallError: ""
    property var wallSeeds: []
    readonly property bool wallReady: wallScheme !== null && wallApplied === wallRequest
    readonly property bool wallBusy: extract.running || wallDelay.running
    function refreshWall() { wallDelay.restart() }
    onWallRequestChanged: refreshWall()
    onWallPathChanged: if (wallApplied !== "") Settings.s.wallpaperSeed = 0
    onSchemeIdChanged: refreshWall()
    Connections { target: Settings; function onReadyChanged() { root.refreshWall() } }
    Component.onCompleted: refreshWall()
    Timer {
        id: wallDelay
        interval: 180
        onTriggered: {
            if (!Settings.ready || root.schemeId !== "wallpaper") return;
            if (root.wallPath === "") { root.wallError = "Choose a wallpaper first."; return; }
            if (extract.running) return; // onExited schedules the latest request
            root.wallError = "";
            extract.request = root.wallRequest;
            const args = JSON.parse(extract.request);
            extract.command = ["python3", Quickshell.shellPath("theme_tools.py"), "extract",
                args[0], args[1], args[2], String(args[3])];
            extract.running = true;
        }
    }
    Process {
        id: extract
        property string request: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (extract.request !== root.wallRequest || root.schemeId !== "wallpaper") return;
                try {
                    const result = JSON.parse(text);
                    if (result.error) { root.wallError = result.error; return; }
                    root.wallScheme = result.palette;
                    root.wallSeeds = result.seeds;
                    root.wallApplied = extract.request;
                } catch (e) { root.wallError = "Wallpaper extraction needs Python 3.11+ and Pillow."; }
            }
        }
        onExited: {
            if (request !== root.wallRequest) root.refreshWall();
        }
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

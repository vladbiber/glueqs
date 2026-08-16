pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Nothing palette: black, white, signature red
    readonly property color bg: "#000000"
    readonly property color blockBg: "#141414"
    readonly property color blockBorder: "#262626"
    readonly property color fg: "#f2f2f2"
    // text is white across the board: the old grey ramp (#9a9a9a/#8f8f8f/#6b6b6b)
    // was unreadable on the panel backgrounds, so the three text tiers all map
    // onto fg and depth is carried by dot size instead of colour
    readonly property color mid: "#f2f2f2"
    readonly property color dim: "#f2f2f2"
    readonly property color hint: "#f2f2f2"
    readonly property color faint: "#2e2e2e" // unlit dots only, too dark to read as text
    readonly property color offDot: "#8f8f8f" // non-text indicators in their off state
    property color red: Settings.s.accent   // accent, configurable from the settings panel
    readonly property color redDim: "#5c1013"

    // used only when the dot font is off: CaskaydiaCove is the Nerd Font on
    // this system carrying the full Material Design icon range
    readonly property string uiFont: "JetBrains Mono"
    readonly property string iconFont: "CaskaydiaCove Nerd Font"

    readonly property real scale: Math.max(0.8, Math.min(1.4, Settings.s.scale))
    readonly property int barHeight: Math.round(48 * scale)
    readonly property int blockHeight: Math.round(38 * scale)
    readonly property int blockRadius: 10

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

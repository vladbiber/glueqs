import QtQuick

// Layout page: the layout every monitor starts in and the drift canvas.
Column {
    spacing: 0
    GwTitle { first: true; text: "LAYOUT"; sub: "Mod+N cycles bsp, scroll and drift at any time; this is where a monitor starts." }
    GwCard {
        GwRow { label: "Starting layout"; hint: "bsp tiles, scroll is a niri-style strip, drift is a free canvas"; key: "layout"
            GwChoice { key: "layout"; options: [{ v: "bsp", label: "BSP" }, { v: "scroll", label: "SCROLL" }, { v: "drift", label: "DRIFT" }] } }
        GwRow { label: "Remember the last layout"; hint: "The layout the previous session ended in wins over the one above"; key: "remember_layout"
            GwToggle { key: "remember_layout" } }
        GwRow { label: "Log in on the overview"; hint: "Every workspace and the dash in view right after login"; key: "start_in_overview"
            GwToggle { key: "start_in_overview" } }
    }
    GwTitle { text: "DRIFT CANVAS"; sub: "Only the drift layout uses these." }
    GwCard {
        GwRow { label: "Snap distance"; hint: "Windows snap to each other within this many pixels, 0 turns it off"; key: "drift_snap"; unit: "px"
            GwNumber { key: "drift_snap"; min: 0; max: 100; unit: "px" } }
        GwRow { label: "Nudge step"; hint: "How far the keyboard moves a window"; key: "drift_nudge"; unit: "px"
            GwNumber { key: "drift_nudge"; min: 1; max: 200; unit: "px" } }
        GwRow { label: "Zoom out limit"; key: "drift_zoom_min"
            GwNumber { key: "drift_zoom_min"; min: 0.05; max: 1; step: 0.05; decimals: 2; unit: "x" } }
        GwRow { label: "Zoom in limit"; key: "drift_zoom_max"
            GwNumber { key: "drift_zoom_max"; min: 1; max: 10; step: 0.5; decimals: 1; unit: "x" } }
        GwRow { label: "Zoom step"; hint: "Multiplier per zoom keypress or wheel notch"; key: "drift_zoom_step"
            GwNumber { key: "drift_zoom_step"; min: 1.01; max: 2; step: 0.02; decimals: 2; unit: "x" } }
        GwRow { label: "Pan speed"; key: "drift_pan_speed"
            GwNumber { key: "drift_pan_speed"; min: 0.1; max: 5; step: 0.1; decimals: 1; unit: "x" } }
    }
}

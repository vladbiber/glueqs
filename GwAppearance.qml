import QtQuick

// Appearance page: corners, blur, opacity, gaps, borders and colours.
Column {
    spacing: 0
    GwTitle { first: true; text: "WINDOWS"; sub: "Every change is written to config.conf and applied by gluewc on the spot." }
    GwCard {
        GwRow { label: "Corner radius"; hint: "Rounded window corners"; key: "corner_radius"; unit: "px"
            GwNumber { key: "corner_radius"; min: 0; max: 40; unit: "px" } }
        GwRow { label: "Gap"; hint: "Space between tiled windows and the screen edge"; key: "gap"; unit: "px"
            GwNumber { key: "gap"; min: 0; max: 80; unit: "px" } }
        GwRow { label: "Opacity"; hint: "Of every window, 0.1 to 1"; key: "opacity"
            GwNumber { key: "opacity"; min: 0.1; max: 1; step: 0.05; decimals: 2 } }
    }
    GwTitle { text: "BLUR"; sub: "Behind translucent windows. Costs GPU time, so it is off by default." }
    GwCard {
        GwRow { label: "Blur"; key: "blur"
            GwToggle { key: "blur" } }
        GwRow { label: "Passes"; hint: "More passes, softer and slower"; key: "blur_passes"
            GwNumber { key: "blur_passes"; min: 1; max: 8 } }
        GwRow { label: "Radius"; key: "blur_radius"; unit: "px"
            GwNumber { key: "blur_radius"; min: 1; max: 20; unit: "px" } }
    }
    GwTitle { text: "BORDERS"; sub: "Hex colours, rrggbb or rrggbbaa." }
    GwCard {
        SToggle { label: "Follow bar colours"; hint: "Use the GlueQS theme and wallpaper palette"; skey: "themeWindowBorders" }
        GwRow { label: "Border width"; key: "border"; unit: "px"
            GwNumber { key: "border"; min: 0; max: 12; unit: "px" } }
        GwRow { label: "Focused window"; key: "border_focus"
            GwColor { key: "border_focus"; enabled: !Settings.s.themeWindowBorders } }
        GwRow { label: "Other windows"; key: "border_normal"
            GwColor { key: "border_normal"; enabled: !Settings.s.themeWindowBorders } }
        GwRow { label: "Normal mode"; hint: "The focused border while the keyboard is in normal mode"; key: "normal_mode_color"
            GwColor { key: "normal_mode_color"; enabled: !Settings.s.themeWindowBorders } }
        GwRow { label: "Borders on unfocused windows"; key: "unfocused_borders"
            GwToggle { key: "unfocused_borders" } }
        GwRow { label: "Desktop colour"; hint: "Behind everything, where no wallpaper is painted"; key: "root_color"
            GwColor { key: "root_color" } }
    }
}

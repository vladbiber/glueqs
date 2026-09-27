import QtQuick

// Input page: pointer, key repeat and the XKB keyboard layout.
Column {
    spacing: 0
    GwTitle { first: true; text: "POINTER" }
    GwRow { label: "Warp the pointer to the focused window"; hint: "When focus moves by keyboard"; key: "warp_pointer"
        GwToggle { key: "warp_pointer" } }

    GwTitle { text: "KEY REPEAT" }
    GwRow { label: "Rate"; hint: "Repeats per second while a key is held"; key: "repeat_rate"; unit: "/s"
        GwNumber { key: "repeat_rate"; min: 1; max: 100; unit: "/s" } }
    GwRow { label: "Delay"; hint: "Before the first repeat"; key: "repeat_delay"; unit: "ms"
        GwNumber { key: "repeat_delay"; min: 100; max: 2000; step: 25; unit: "ms" } }

    GwTitle { text: "KEYBOARD LAYOUT"; sub: "XKB names as in setxkbmap: layout \"us,ro\", variant \",std\", options \"grp:alt_shift_toggle,ctrl:nocaps\". Empty keeps the system default." }
    GwRow { label: "Layout"; key: "xkb_layout"
        GwText { key: "xkb_layout"; placeholder: "us" } }
    GwRow { label: "Variant"; key: "xkb_variant"
        GwText { key: "xkb_variant"; placeholder: "" } }
    GwRow { label: "Options"; key: "xkb_options"
        GwText { key: "xkb_options"; placeholder: "ctrl:nocaps" } }
}

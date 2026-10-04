import QtQuick

// The DISPLAY content shared by the shell settings and the gluewc panel:
// the backlight card, the sleep mode card and the door to the monitors.
Column {
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "BRIGHTNESS"; sub: "The panel backlight. The bar's levels tile has the same slider, and the keys run gluewc-backlight." }
    GwCard {
        visible: Brightness.available
        BrightnessControls { pad: 14 }
    }
    GwCard {
        visible: !Brightness.available
        GwRow { label: "No backlight"; hint: "Nothing under /sys/class/backlight on this machine. External monitors are set from their own buttons." }
    }

    GwTitle { text: "SLEEP MODE"; sub: "A dark screen after a while without input. Nothing on the laptop stops." }
    SleepControls {}

    GwTitle { visible: Gluewc.available; text: "MONITORS"; sub: "Layout, resolution, scale, rotation and mirroring have their own page." }
    GwCard {
        visible: Gluewc.available
        GwRow { label: "Monitor layout"; hint: "Drag screens into place, mirror them or switch one off"
            GwButton { label: "OPEN MONITORS  >"; active: true; onClicked: { Popups.gluewcPage = 7; Popups.open = "gluewc"; } }
        }
    }
}

import QtQuick

// Display page: the backlight, and the way to the monitor layout.
Column {
    spacing: 0
    GwTitle { first: true; text: "BRIGHTNESS"; sub: "The laptop panel backlight. The keys run gluewc-backlight, which steps 5% down to 10% and then 1% at a time so it can reach 0." }
    Item { width: 1; height: 12 }
    Loader {
        width: parent.width
        active: Brightness.available
        sourceComponent: BrightnessControls { width: parent.width }
    }
    Text {
        visible: !Brightness.available
        width: parent.width; wrapMode: Text.WordWrap
        text: "No backlight under /sys/class/backlight on this machine, so there is nothing to dim here. External monitors are set from their own buttons."
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12
    }

    GwTitle { text: "MONITORS"; sub: "Layout, resolution, scale, rotation and mirroring live on their own page." }
    Item { width: 1; height: 12 }
    GwButton { label: "OPEN MONITORS  >"; active: true; onClicked: Popups.gluewcPage = 7 }
}

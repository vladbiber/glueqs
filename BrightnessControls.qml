import QtQuick

// Backlight slider, presets and the off switch; shared by the bar panel and
// the settings pages. Writes through Brightness.set().
Column {
    id: root
    width: parent.width
    spacing: 12
    topPadding: pad; bottomPadding: pad; leftPadding: pad; rightPadding: pad
    property int pad: 0
    readonly property int pct: Brightness.percent

    Row {
        width: parent.width - root.pad * 2
        spacing: 12
        DotIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "sun"; px: 1.6; gap: 1
            color: root.pct === 0 ? Theme.offDot : Theme.fg
        }
        DotSlider {
            anchors.verticalCenter: parent.verticalCenter
            dots: Math.max(10, Math.floor((parent.width - 40 - 64) / 9))
            value: Brightness.level
            muted: root.pct === 0
            onMoved: v => Brightness.set(v * 100)
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: root.pct + "%"
            color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 14; font.weight: Font.Medium
        }
    }

    Row {
        spacing: 6
        Repeater {
            model: [10, 25, 50, 75, 100]
            delegate: GwButton {
                required property int modelData
                label: modelData + "%"; small: true
                active: root.pct === modelData
                enabled: Brightness.canSet
                onClicked: Brightness.set(modelData)
            }
        }
        Item { width: 10; height: 1 }
        GwButton {
            label: "SCREEN OFF (0%)"; small: true; danger: true
            active: root.pct === 0
            enabled: Brightness.canSet
            onClicked: Brightness.set(0)
        }
    }

    Text {
        width: parent.width - root.pad * 2
        wrapMode: Text.WordWrap
        text: root.pct === 0
            ? "The panel is off. Press your brightness-up key (it runs gluewc-backlight up) or click a preset here to bring it back."
            : !Brightness.canSet
              ? "Nothing here can write the backlight: install brightnessctl or light, or make " + Brightness.base + "/" + Brightness.device + "/brightness writable."
              : "0% switches the panel off. Any brightness key brings it back, and this widget stays in the bar showing 0%."
              + "   Writes through " + Brightness.writer + "."
        color: root.pct === 0 ? Theme.fg : Theme.muted
        font.family: Theme.uiFont; font.pixelSize: 11
    }
}

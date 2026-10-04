import QtQuick

// AUDIO: the volume OSD, the media panel's spectrum and the bar visualisers.
Column {
    id: page
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "SOUND"; sub: "Master volume, where the sound goes, the microphone and every app playing. The same mixer opens from the volume tile." }
    MixerView { wide: true; active: Popups.open === "settings" }

    GwTitle { text: "VOLUME"; sub: "The volume tile and its pop-up. Equaliser presets live in the media panel." }
    GwCard {
        SToggle { label: "Volume OSD"; hint: "A pop-up when the volume changes"; skey: "osdEnabled" }
        GwRow { label: "OSD time"; hint: "How long the pop-up stays"
            GwNumber { bound: true; value: Settings.s.osdDuration; min: 800; max: 3200; step: 100; unit: "ms"; onChanged: v => Settings.s.osdDuration = Math.round(v) }
        }
        GwRow { label: "Scroll step"; hint: "Per wheel notch on the volume tile"
            GwNumber { bound: true; value: Settings.s.volumeStep; min: 1; max: 10; unit: "%"; onChanged: v => Settings.s.volumeStep = Math.round(v) }
        }
        SToggle { label: "Media panel spectrum"; hint: "The live spectrum inside the media panel"; skey: "eqEnabled" }
    }

    GwTitle { text: "VISUALISERS"; sub: "Spectrum tiles for the bar. Add as many as you like, each in its own style, from the WIDGETS page. These settings apply to all of them." }
    // a live strip of every style with the current settings
    GwCard {
        Item {
            width: parent.width
            height: vizGrid.implicitHeight + 28
            Grid {
                id: vizGrid
                anchors.centerIn: parent
                columns: 3
                columnSpacing: 26
                rowSpacing: 14
                Repeater {
                    model: ["dots", "bars", "mirror", "wave", "line", "peaks"]
                    delegate: Column {
                        required property string modelData
                        spacing: 6
                        VizWidget { style: parent.modelData; anchors.horizontalCenter: parent.horizontalCenter
                                    // never hide the preview, even with nothing playing
                                    visible: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.modelData.toUpperCase(); color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 10 }
                    }
                }
            }
        }
    }
    GwCard {
        GwRow { label: "Bars"; hint: "How many columns each visualiser draws"
            GwNumber { bound: true; value: Settings.s.vizBars; min: 6; max: 32; step: 1; onChanged: v => Settings.s.vizBars = Math.round(v) }
        }
        GwRow { label: "Width"; hint: "Length of the tile along the bar"
            GwNumber { bound: true; value: Settings.s.vizWidth; min: 40; max: 260; step: 8; unit: "px"; onChanged: v => Settings.s.vizWidth = Math.round(v) }
        }
        GwRow { label: "Colour"
            GwChoice {
                bound: true; value: Settings.s.vizColor
                options: [{ v: "accent", label: "ACCENT" }, { v: "text", label: "TEXT" }, { v: "gradient", label: "GRADIENT" }]
                onPicked: v => Settings.s.vizColor = v
            }
        }
        GwRow { label: "Frame rate"; hint: "Higher is smoother and costs more CPU"
            GwChoice {
                bound: true; value: String(Settings.s.vizFps)
                options: [{ v: "20", label: "20" }, { v: "30", label: "30" }, { v: "60", label: "60" }]
                onPicked: v => Settings.s.vizFps = parseInt(v)
            }
        }
        SToggle { label: "Hide when nothing plays"; skey: "vizHideIdle" }
        GwRow { label: "Source"; hint: "pipewire = built into this quickshell; cava = the cava program; synthetic = a stand-in motion while a player plays"
            Text { text: Spectrum.wanted ? Spectrum.source.toUpperCase() : "IDLE"; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12 }
        }
    }
}

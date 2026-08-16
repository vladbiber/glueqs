import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

// Expanded media view, Nothing Recorder style: spinning reel disc with album art,
// live dot equalizer, dotted timeline, boxed play button, and a manual 10-band
// EasyEffects equalizer with presets in the right column.
PanelWindow {
    id: root
    // open centred under the media tile when the bar is horizontal and the tile
    // has reported where it is; otherwise fall back to the right edge
    readonly property bool trackTile: !Theme.vertical && MediaService.anchorCenter >= 0
    anchors {
        top: true
        left: trackTile
        right: !trackTile
    }
    margins {
        top: Theme.popupTop
        left: trackTile
             ? Math.max(8, Math.min(MediaService.anchorCenter - root.implicitWidth / 2,
                        (screen ? screen.width : 1920) - root.implicitWidth - 8))
             : 0
        right: trackTile ? 0 : Theme.popupRight
    }
    implicitWidth: 592
    implicitHeight: Settings.s.eqEnabled ? 358 : 340
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: MediaService.panelOpen

    readonly property var player: MediaService.active
    property real pos: 0

    property real intro: 0
    onVisibleChanged: {
        if (visible) {
            intro = 0;
            introAnim.restart();
        }
    }
    NumberAnimation {
        id: introAnim
        target: root; property: "intro"
        from: 0; to: 1; duration: 900
        easing.type: Easing.OutCubic
    }
    function stage(a, b) { return Math.max(0, Math.min(1, (intro - a) / (b - a))) }

    Timer {
        running: root.visible
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: root.pos = root.player?.position ?? 0
    }

    PwAudioSpectrum {
        id: spectrum
        node: Pipewire.defaultAudioSink
        enabled: root.visible && Settings.s.eqEnabled
        barCount: 24
        frameRate: 30
    }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [ Pipewire.defaultAudioSink ] : [] }

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // ---- manual equalizer state ----
    readonly property var presetGains: ({
        "FLAT":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "BASS":    [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
        "TREBLE":  [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
        "VOCAL":   [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
        "POP":     [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
        "ROCK":    [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
        "JAZZ":    [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
        "CLASSIC": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
    })
    property var gains: Settings.s.eqGains.split(",").map(Number)

    function setBand(i, gain) {
        const g = gains.slice();
        g[i] = gain;
        gains = g;
        Settings.s.eqGains = g.join(",");
        Settings.s.eqPreset = "CUSTOM";
        applyDebounce.restart();
    }
    function applyPreset(name) {
        gains = presetGains[name].slice();
        Settings.s.eqGains = gains.join(",");
        Settings.s.eqPreset = name;
        Quickshell.execDetached([Quickshell.shellPath("eq-preset.sh"), name.toLowerCase()]);
    }
    Timer {
        id: applyDebounce
        interval: 400
        onTriggered: Quickshell.execDetached(
            [Quickshell.shellPath("eq-preset.sh"), "custom"].concat(root.gains.map(String)))
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"
            px: 1.6; gap: 1
            color: xArea.containsMouse ? Theme.red : Theme.dim
            MouseArea {
                id: xArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                onClicked: MediaService.panelOpen = false
            }
        }

        Row {
            anchors { fill: parent; margins: 18 }
            spacing: 18

            // ---- left: player ----
            Column {
                width: parent.width - 178 - 18
                spacing: 10

                Row {
                    spacing: 6
                    width: parent.width
                    opacity: root.stage(0, 0.35)

                    Disc {
                        spinning: root.player?.isPlaying ?? false
                        rate: root.player?.rate ?? 1
                        artUrl: root.player?.trackArtUrl ?? ""
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 160 - 6
                        spacing: 5
                        opacity: root.stage(0.1, 0.5)

                        Marquee {
                            width: parent.width
                            text: {
                                let t = (root.player?.trackTitle ?? "NO MEDIA").toUpperCase();
                                return t.length === 0 ? "UNKNOWN" : t;
                            }
                            px: 1.6
                        }
                        DotText {
                            text: {
                                let a = (root.player?.trackArtist ?? "").toUpperCase();
                                return a.length > 20 ? a.slice(0, 19) + "." : a;
                            }
                            px: 1.1; gap: 1
                            color: Theme.dim
                        }
                        DotText {
                            text: {
                                const s = Pipewire.defaultAudioSink;
                                const n = ((s?.nickname && s.nickname !== "" ? s.nickname : s?.description) ?? "").toUpperCase();
                                return n.length > 20 ? n.slice(0, 19) + "." : n;
                            }
                            px: 0.9; gap: 0.9
                            color: Theme.mid
                        }
                    }
                }

                Canvas {
                    id: eqViz
                    visible: Settings.s.eqEnabled
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 24 * 8 - 3
                    height: 12 * 8 - 3
                    property var vals: spectrum.values
                    property real sweep: root.stage(0.2, 0.95)
                    onValsChanged: requestPaint()
                    onSweepChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const cols = 24, rows = 12, cell = 8, r = 2.5;
                        for (let c = 0; c < cols; c++) {
                            const f = Math.max(0, Math.min(1, sweep * 1.6 - c / cols * 0.6));
                            const v = Math.max(0, Math.min(1, vals?.[c] ?? 0)) * f;
                            const lit = Math.round(v * rows);
                            for (let row = 0; row < rows; row++) {
                                const on = row < lit;
                                ctx.fillStyle = on
                                    ? (row === lit - 1 ? String(Theme.red) : String(Theme.fg))
                                    : String(Theme.faint);
                                ctx.beginPath();
                                ctx.arc(c * cell + r, (rows - 1 - row) * cell + r, r, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2
                    opacity: root.stage(0.4, 0.8)

                    RecorderTimeline {
                        width: parent.width
                        frac: {
                            const len = root.player?.length ?? 0;
                            return len > 0 ? root.pos / len : 0;
                        }
                        onSeekTo: f => {
                            const p = root.player;
                            if (!p || !p.canSeek || !(p.length > 0)) return;
                            const target = f * p.length;
                            p.seek(target - root.pos);
                            root.pos = target;
                        }
                    }
                    Item {
                        width: parent.width; height: 12
                        DotText {
                            anchors.left: parent.left
                            text: root.fmt(root.pos)
                            px: 1; gap: 1; color: Theme.dim
                        }
                        DotText {
                            anchors.right: parent.right
                            text: "-" + root.fmt((root.player?.length ?? 0) - root.pos)
                            px: 1; gap: 1; color: Theme.dim
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 40
                    opacity: root.stage(0.55, 1)

                    DotText {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "SHFL"
                        px: 1.1; gap: 1
                        color: root.player?.shuffle ? Theme.red : Theme.dim
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            onClicked: if (root.player?.shuffleSupported)
                                root.player.shuffle = !root.player.shuffle
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 24
                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "prev"
                            px: 1.8; gap: 1
                            color: prevArea.containsMouse ? Theme.red : Theme.fg
                            MouseArea {
                                id: prevArea
                                anchors.fill: parent; anchors.margins: -8
                                hoverEnabled: true
                                onClicked: root.player?.previous()
                            }
                        }
                        Rectangle {
                            width: 62; height: 36; radius: 10
                            color: playArea.containsMouse ? "#1a1a1a" : "transparent"
                            border.color: Theme.fg
                            border.width: 1.5
                            DotIcon {
                                anchors.centerIn: parent
                                name: root.player?.isPlaying ? "pause" : "play"
                                px: 2; gap: 1
                                color: Theme.red
                            }
                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.player?.togglePlaying()
                            }
                        }
                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "next"
                            px: 1.8; gap: 1
                            color: nextArea.containsMouse ? Theme.red : Theme.fg
                            MouseArea {
                                id: nextArea
                                anchors.fill: parent; anchors.margins: -8
                                hoverEnabled: true
                                onClicked: root.player?.next()
                            }
                        }
                    }

                    DotText {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: "LOOP"
                        px: 1.1; gap: 1
                        color: root.player && root.player.loopState !== MprisLoopState.None
                               ? Theme.red : Theme.dim
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -6
                            onClicked: {
                                const p = root.player;
                                if (!p?.loopSupported) return;
                                p.loopState = p.loopState === MprisLoopState.None
                                    ? MprisLoopState.Playlist
                                    : p.loopState === MprisLoopState.Playlist
                                    ? MprisLoopState.Track : MprisLoopState.None;
                            }
                        }
                    }
                }
            }

            // ---- right: manual equalizer ----
            Column {
                width: 178
                spacing: 8
                opacity: root.stage(0.5, 1)

                DotText { text: "EQUALIZER"; px: 1.1; gap: 1; color: Theme.mid }

                Row {
                    spacing: 2
                    Repeater {
                        model: 10
                        delegate: DotVSlider {
                            required property int index
                            value: ((root.gains[index] ?? 0) + 10) / 20
                            onMoved: v => root.setBand(index, Math.round(v * 20 - 10))
                        }
                    }
                }

                Item {
                    width: parent.width; height: 10
                    DotText {
                        anchors.left: parent.left
                        text: "32HZ"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                    DotText {
                        anchors.right: parent.right
                        text: "16KHZ"
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                }

                Grid {
                    columns: 2
                    columnSpacing: 6
                    rowSpacing: 6
                    Repeater {
                        model: ["FLAT", "BASS", "TREBLE", "VOCAL", "POP", "ROCK", "JAZZ", "CLASSIC"]
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            readonly property bool active: Settings.s.eqPreset === modelData
                            width: 86; height: 24
                            radius: 6
                            color: cma.containsMouse ? "#1c1c1c" : "transparent"
                            border.color: active ? Theme.red : Theme.blockBorder
                            border.width: 1
                            DotText {
                                anchors.centerIn: parent
                                text: chip.modelData
                                px: 1; gap: 1
                                color: chip.active ? Theme.fg : Theme.mid
                            }
                            MouseArea {
                                id: cma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.applyPreset(chip.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 1000
        onTriggered: { MediaService.panelOpen = true; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1800
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/media-" + root.screen.name + ".png"))
    }
}

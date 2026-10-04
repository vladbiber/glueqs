pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// One shared audio spectrum for the bar visualisers, running only while one
// is on screen. Where it comes from, best first: PwAudioSpectrum (noctalia-qs
// only, loaded through a Loader so upstream Quickshell just skips it), cava
// fed its config on stdin, or a synthetic motion while a player plays.
Singleton {
    id: root
    readonly property int bars: 32
    property var values: []
    property int users: 0
    readonly property bool wanted: users > 0
    // GLUEQS_VIZ_DEMO=1 moves the synthetic spectrum as if music played, for screenshots
    readonly property bool demo: (Quickshell.env("GLUEQS_VIZ_DEMO") ?? "") !== ""
    readonly property string source: demo ? "synthetic" : pw.status === Loader.Ready ? "pipewire"
                                   : cava.running ? "cava" : "synthetic"

    function acquire() { users++ }
    function release() { users = Math.max(0, users - 1) }

    Loader {
        id: pw
        source: "SpectrumSource.qml"
        active: root.wanted && !root.demo
        onLoaded: { item.barCount = root.bars; item.frameRate = Settings.s.vizFps; }
    }
    Connections {
        target: pw.status === Loader.Ready ? pw.item : null
        function onValuesChanged() { root.values = pw.item.values }
    }

    property bool hasCava: false
    Process {
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null"]
        onExited: code => root.hasCava = code === 0
    }
    Process {
        id: cava
        running: root.wanted && !root.demo && pw.status === Loader.Error && root.hasCava
        command: ["sh", "-c", 'printf "%s" "$1" | cava -p /dev/stdin', "glueqs",
            "[general]\nbars=" + root.bars + "\nframerate=" + Settings.s.vizFps
            + "\nautosens=1\nsensitivity=100\nlower_cutoff_freq=50\nhigher_cutoff_freq=12000\n"
            + "[smoothing]\nmonstercat=1\nnoise_reduction=77\n"
            + "[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100\n"
            + "bit_format=8bit\nchannels=mono\nmono_option=average\n"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < parts.length && out.length < root.bars; i++)
                    if (parts[i] !== "") out.push(Math.min(1, (parseInt(parts[i]) || 0) / 100));
                root.values = out;
            }
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: root.wanted && (root.demo || (pw.status === Loader.Error && !cava.running))
        property real t: 0
        onTriggered: {
            t += 0.05;
            const playing = root.demo || (MediaService.active?.isPlaying ?? false);
            const out = [];
            for (let i = 0; i < root.bars; i++) {
                const v = playing
                    ? 0.35 + 0.3 * Math.sin(t * 2.1 + i * 0.7) * Math.sin(t * 0.9 + i * 1.3)
                      + 0.25 * Math.abs(Math.sin(t * 3.7 + i * 0.4))
                    : 0;
                out.push(Math.max(0, Math.min(1, v * (1 - i / (root.bars * 1.6)))));
            }
            root.values = out;
        }
    }
    onWantedChanged: if (!wanted) values = []
}

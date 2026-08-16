pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round(volume * 100)

    signal osdTrigger()

    // suppress the OSD during startup while initial state lands
    property bool ready: false
    Timer { running: true; interval: 2000; onTriggered: root.ready = true }

    onVolumeChanged: if (ready) osdTrigger()
    onMutedChanged: if (ready) osdTrigger()

    function setVolume(v) {
        if (sink?.ready)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute() {
        if (sink?.ready)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker { objects: [ root.sink ] }
}

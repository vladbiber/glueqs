import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// The small one-icon tiles: keep awake, wallpaper, microphone, active window,
// caps lock and a spacer. Which one comes from `kind`.
Block {
    id: root
    property string kind: "keepawake"
    hpad: kind === "spacer" ? 0 : 10
    color: kind === "spacer" ? "transparent" : (on ? Qt.alpha(Theme.red, 0.18) : Theme.blockBg)
    border.color: kind === "spacer" ? "transparent" : (on ? Theme.red : Theme.tileBorder)
    Behavior on color { ColorAnimation { duration: Theme.ms(180) } }

    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: root.kind === "mic" && root.mic ? [root.mic] : [] }

    readonly property var win: ToplevelManager.activeToplevel
    property bool caps: false

    readonly property bool on: kind === "keepawake" ? Settings.s.keepAwake
                             : kind === "mic" ? !(mic?.audio?.muted ?? true)
                             : kind === "caps" ? caps : false
    readonly property string icon: kind === "keepawake" ? (on ? "cup" : "cupoff")
                                  : kind === "wallpaper" ? "image"
                                  : kind === "mic" ? (on ? "mic" : "micx")
                                  : kind === "window" ? "window" : kind === "caps" ? "caps" : "dot"
    readonly property string label: kind === "window" ? (win?.title ?? win?.appId ?? "DESKTOP").toUpperCase()
                                  : kind === "caps" ? (caps ? "CAPS" : "")
                                  : kind === "mic" ? (on ? Math.round((mic?.audio?.volume ?? 0) * 100) + "%" : "") : ""

    Timer {
        running: root.kind === "caps"; repeat: true; interval: 800; triggeredOnStart: true
        onTriggered: capsRd.running = true
    }
    Process {
        id: capsRd
        command: ["sh", "-c", "cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | sort -r | head -1"]
        stdout: StdioCollector { onStreamFinished: root.caps = text.trim() === "1" }
    }

    Item {
        visible: root.kind === "spacer"
        width: Theme.vertical ? 1 : 24; height: Theme.vertical ? 24 : 1
    }
    Grid {
        visible: root.kind !== "spacer"
        columns: Theme.vertical ? 1 : 2
        spacing: 6
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter
        DotIcon { name: root.icon; px: Theme.pxIcon * 0.85; gap: 0.9; color: root.on ? Theme.red : Theme.fg }
        DotText {
            visible: root.label !== "" && !Theme.vertical
            text: root.label
            maxWidth: root.kind === "window" ? 220 : 0
            px: Theme.pxSmall * 1.1; gap: 0.8
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0; width: root.width; height: root.height
        visible: root.kind !== "spacer"
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            switch (root.kind) {
            case "keepawake": Settings.s.keepAwake = !Settings.s.keepAwake; break;
            case "wallpaper":
                if (mouse.button === Qt.RightButton) Wallpapers.random("");
                else Popups.toggle("wallpaper");
                break;
            case "mic": if (root.mic?.audio) root.mic.audio.muted = !root.mic.audio.muted; break;
            }
        }
        onWheel: wheel => {
            if (root.kind === "wallpaper") Wallpapers.next("");
            else if (root.kind === "mic" && root.mic?.audio)
                root.mic.audio.volume = Math.max(0, Math.min(1, root.mic.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
        }
    }
}

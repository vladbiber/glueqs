import Quickshell
import Quickshell.Wayland
import QtQuick

// The wallpaper itself: a background-layer window per screen with two image
// slots that trade places through a transition. gluewc clones this layer
// into its overview cards, so the picture follows there too.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "glueqs-wallpaper"
    color: Settings.s.wallpaperSolid
    mask: Region {}          // clicks go to whatever the compositor wants

    readonly property string path: Wallpapers.pathFor(root.screen?.name ?? "")
    readonly property int duration: Math.max(0, Settings.s.wallpaperTransitionMs)

    // which of the two slots is showing; the other one gets the next image
    property int front: 0
    property string kind: "fade"

    readonly property int fill: {
        switch (Settings.s.wallpaperFill) {
        case "fit":     return Image.PreserveAspectFit;
        case "stretch": return Image.Stretch;
        case "center":  return Image.Pad;
        case "tile":    return Image.Tile;
        default:        return Image.PreserveAspectCrop;
        }
    }

    function pickKind() {
        const t = Settings.s.wallpaperTransition;
        if (t !== "random") return t;
        const all = ["fade", "wipe", "slide", "zoom"];
        return all[Math.floor(Math.random() * all.length)];
    }

    onPathChanged: show(path)
    Component.onCompleted: {
        // no transition for the very first picture
        slots.itemAt(0).source = path !== "" ? "file://" + path : "";
        slots.itemAt(0).opacity = 1;
    }

    // the new picture is decoded off the main thread; the transition only
    // starts once it is there, so nothing flashes black in between
    function show(p) {
        const nextIdx = 1 - front;
        const incoming = slots.itemAt(nextIdx);
        const showing = slots.itemAt(front);
        if (!incoming) return;
        // the same picture again (a per-screen override that resolves to the
        // one already up, say) is not a transition
        if (showing && String(showing.source) === (p !== "" ? "file://" + p : "")) {
            incoming.pending = false;
            return;
        }
        incoming.pending = true;
        incoming.source = p !== "" ? "file://" + p : "";
        incoming.maybeReveal();
    }
    function swapTo(nextIdx) {
        const incoming = slots.itemAt(nextIdx);
        const outgoing = slots.itemAt(front);
        if (!incoming || !outgoing || nextIdx === front) return;
        kind = pickKind();
        incoming.reveal(kind, duration);
        outgoing.hide(kind, duration);
        front = nextIdx;
    }

    Item {
        id: stage
        anchors.fill: parent
        clip: true

        Repeater {
            id: slots
            model: 2
            delegate: Item {
                id: slot
                required property int index
                // sized, not anchored: the slide and zoom move the slot itself
                width: parent.width
                height: parent.height
                property alias source: img.source
                property real revealX: 0        // wipe: fraction uncovered
                property bool pending: false    // waiting for the picture to load
                z: slot.index === root.front ? 1 : 0

                function maybeReveal() {
                    if (!pending) return;
                    if (img.source == "" || img.status === Image.Ready
                            || img.status === Image.Error) {
                        pending = false;
                        root.swapTo(slot.index);
                    }
                }

                // wipe reveals left to right through a growing clip box
                Item {
                    id: clipBox
                    x: 0; y: 0
                    height: parent.height
                    width: parent.width * (slot.revealX > 0 ? slot.revealX : 1)
                    clip: slot.revealX > 0 && slot.revealX < 1

                    Image {
                        id: img
                        width: slot.width
                        height: slot.height
                        fillMode: root.fill
                        asynchronous: true
                        cache: false
                        smooth: true
                        mipmap: true
                        sourceSize.width: fillMode === Image.Tile ? 0 : Math.max(root.width, 1)
                        onStatusChanged: slot.maybeReveal()
                    }
                }

                function reveal(kind, ms) {
                    revealAnim.stop(); hideAnim.stop();
                    slot.revealX = 0;
                    slot.x = 0; slot.scale = 1;
                    if (ms <= 0) { slot.opacity = 1; return; }
                    revealAnim.kind = kind;
                    revealAnim.duration = ms;
                    slot.opacity = kind === "fade" || kind === "zoom" ? 0 : 1;
                    if (kind === "slide") slot.x = -slot.width * 0.12;
                    if (kind === "zoom") slot.scale = 1.08;
                    if (kind === "wipe") slot.revealX = 0.0001;
                    revealAnim.start();
                }
                function hide(kind, ms) {
                    hideAnim.stop();
                    if (ms <= 0) { slot.opacity = 0; return; }
                    hideAnim.duration = ms;
                    hideAnim.start();
                }

                ParallelAnimation {
                    id: revealAnim
                    property string kind: "fade"
                    property int duration: 800
                    NumberAnimation {
                        target: slot; property: "opacity"; to: 1
                        duration: revealAnim.kind === "wipe" ? 1 : revealAnim.duration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slot; property: "x"; to: 0
                        duration: revealAnim.duration; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slot; property: "scale"; to: 1
                        duration: revealAnim.duration; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: slot; property: "revealX"
                        to: revealAnim.kind === "wipe" ? 1 : 0
                        duration: revealAnim.duration; easing.type: Easing.InOutCubic
                    }
                    onFinished: slot.revealX = 0
                }
                // the old picture just stays put underneath and lets go at the end
                SequentialAnimation {
                    id: hideAnim
                    property int duration: 800
                    PauseAnimation { duration: hideAnim.duration }
                    PropertyAction { target: slot; property: "opacity"; value: 0 }
                }
            }
        }
    }
}

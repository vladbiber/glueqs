import Quickshell
import QtQuick

// Compact media tile: note icon + scrolling track title + prev/play/next controls.
// Click anywhere else opens the big panel.
Block {
    id: root
    readonly property var player: MediaService.active

    // tell the panel where this tile sits so it can open centred under it
    function reportAnchor() {
        const w = QsWindow.window;
        if (!w) return;
        MediaService.anchorCenter = mapToItem(w.contentItem, width / 2, 0).x;
    }
    onXChanged: reportAnchor()
    onWidthChanged: reportAnchor()
    Component.onCompleted: reportAnchor()

    Row {
        spacing: 10

        DotIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "note"   // stays a note: the play/pause state is the button's job
            px: Theme.pxIcon; gap: 1
            color: root.player?.isPlaying ? Theme.red : Theme.dim
        }
        Marquee {
            visible: !Theme.vertical
            anchors.verticalCenter: parent.verticalCenter
            px: Theme.pxMed
            text: {
                let t = (root.player?.trackTitle ?? "").toUpperCase();
                return t.length === 0 ? "MEDIA" : t;
            }
            width: Math.min(150 * Theme.scale, textWidth)
        }
        Row {
            visible: !Theme.vertical
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "prev"
                px: 1.3 * Theme.scale; gap: 1
                color: wPrev.containsMouse ? Theme.red : Theme.mid
                MouseArea {
                    id: wPrev
                    anchors.fill: parent; anchors.margins: -5
                    hoverEnabled: true
                    onClicked: root.player?.previous()
                }
            }
            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.player?.isPlaying ? "pause" : "play"
                px: 1.3 * Theme.scale; gap: 1
                color: wPlay.containsMouse ? Theme.red : Theme.fg
                MouseArea {
                    id: wPlay
                    anchors.fill: parent; anchors.margins: -5
                    hoverEnabled: true
                    onClicked: root.player?.togglePlaying()
                }
            }
            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "next"
                px: 1.3 * Theme.scale; gap: 1
                color: wNext.containsMouse ? Theme.red : Theme.mid
                MouseArea {
                    id: wNext
                    anchors.fill: parent; anchors.margins: -5
                    hoverEnabled: true
                    onClicked: root.player?.next()
                }
            }
        }
    }

    MouseArea {
        parent: root
        z: -1   // under the content so the control buttons get their clicks first
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: MediaService.panelOpen = !MediaService.panelOpen
    }
}

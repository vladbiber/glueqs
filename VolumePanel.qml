import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

// Audio mixer: output devices + master slider, mic, per-app streams.
PanelWindow {
    id: root
    anchors { top: true; right: true }
    margins { top: Theme.popupTop; right: Theme.popupRight }
    implicitWidth: 330
    implicitHeight: 470
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "volume"

    readonly property var sinkNodes:
        Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var streamNodes:
        Pipewire.nodes.values.filter(n => n.isStream && n.isSink)
    readonly property var mic: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: root.sinkNodes.concat(root.streamNodes)
            .concat(root.mic ? [root.mic] : [])
    }

    function appName(n) {
        return (n.properties?.["application.name"] ?? n.nickname ?? n.name ?? "APP");
    }
    function devName(n) {
        return (n.nickname && n.nickname !== "" ? n.nickname : n.description) ?? n.name;
    }
    function trunc(t, max) {
        t = t.toUpperCase();
        return t.length > max ? t.slice(0, max - 1) + "." : t;
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            anchors { fill: parent; margins: 16 }
            spacing: 8

            DotText { text: "OUTPUT"; px: 1.4; gap: 1 }

            Row {
                spacing: 10
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Audio.muted ? "volx"
                        : Audio.volume > 0.5 ? "vol2"
                        : Audio.volume > 0 ? "vol1" : "vol0"
                    px: 1.6; gap: 1
                    color: Audio.muted ? Theme.red : Theme.fg
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -5
                        onClicked: Audio.toggleMute()
                    }
                }
                DotSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    value: Audio.volume
                    muted: Audio.muted
                    onMoved: v => Audio.setVolume(v)
                }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Audio.percent + "%"
                    px: 1.2; gap: 1
                    color: Audio.muted ? Theme.dim : Theme.fg
                }
            }

            Column {
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.sinkNodes
                    delegate: Rectangle {
                        id: drow
                        required property var modelData
                        readonly property bool isDefault: modelData === Pipewire.defaultAudioSink
                        width: parent.width; height: 28
                        radius: 6
                        color: dma.containsMouse ? "#1c1c1c" : "transparent"
                        border.color: isDefault ? Theme.red : "transparent"
                        border.width: 1
                        DotText {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: root.trunc(root.devName(drow.modelData), 24)
                            px: 1.1; gap: 1
                            color: drow.isDefault ? Theme.fg : Theme.mid
                        }
                        MouseArea {
                            id: dma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Pipewire.preferredDefaultAudioSink = drow.modelData
                        }
                    }
                }
            }

            Item { width: 1; height: 6 }
            DotText { text: "MIC"; px: 1.4; gap: 1 }

            Row {
                spacing: 10
                visible: root.mic !== null
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.mic?.audio?.muted ? "volx" : "vol1"
                    px: 1.6; gap: 1
                    color: root.mic?.audio?.muted ? Theme.red : Theme.fg
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -5
                        onClicked: if (root.mic?.ready) root.mic.audio.muted = !root.mic.audio.muted
                    }
                }
                DotSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    value: root.mic?.audio?.volume ?? 0
                    muted: root.mic?.audio?.muted ?? false
                    onMoved: v => { if (root.mic?.ready) root.mic.audio.volume = v }
                }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round((root.mic?.audio?.volume ?? 0) * 100) + "%"
                    px: 1.2; gap: 1
                }
            }

            Item { width: 1; height: 6 }
            DotText { text: "APPS"; px: 1.4; gap: 1 }

            DotText {
                visible: root.streamNodes.length === 0
                text: "NO STREAMS"
                px: 1.1; gap: 1; color: Theme.dim
            }

            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: root.streamNodes
                    delegate: Column {
                        id: arow
                        required property var modelData
                        width: parent.width
                        spacing: 3
                        DotText {
                            text: root.trunc(root.appName(arow.modelData), 24)
                            px: 1.1; gap: 1
                            color: arow.modelData.audio?.muted ? Theme.dim : Theme.fg
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -3
                                onClicked: if (arow.modelData.ready)
                                    arow.modelData.audio.muted = !arow.modelData.audio.muted
                            }
                        }
                        DotSlider {
                            dots: 28
                            value: arow.modelData.audio?.volume ?? 0
                            muted: arow.modelData.audio?.muted ?? false
                            onMoved: v => { if (arow.modelData.ready) arow.modelData.audio.volume = v }
                        }
                    }
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 7000
        onTriggered: { Popups.open = "volume"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/volume-" + root.screen.name + ".png"))
    }
}

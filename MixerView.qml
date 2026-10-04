import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "DotFont.js" as DotFont

// Sound: the master level over a live spectrum, outputs as cards, the
// microphone and every app playing. Used by the bar popup and the AUDIO
// settings page.
Column {
    id: root
    property bool active: false
    property bool wide: false
    width: parent ? parent.width : 400
    spacing: 14

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)
    readonly property var mic: Pipewire.defaultAudioSource
    PwObjectTracker { objects: root.sinks.concat(root.sources).concat(root.streams) }

    property bool held: false
    function hold(on) {
        if (on && !held) { Spectrum.acquire(); held = true; }
        else if (!on && held) { Spectrum.release(); held = false; }
    }
    onActiveChanged: hold(active)
    Component.onCompleted: hold(active)
    Component.onDestruction: hold(false)

    function devName(n) { return (n.description && n.description !== "" ? n.description : n.nickname) || n.name || "DEVICE" }
    function devIcon(n) {
        const s = ((n.name ?? "") + " " + (n.description ?? "")).toLowerCase();
        if (/bluez|head|earbud|airpod|buds/.test(s)) return "headset";
        if (/hdmi|displayport|\bdp\b/.test(s)) return "screen";
        if (!n.isSink) return "mic";
        return "speaker";
    }
    function appName(n) { return n.properties?.["application.name"] ?? n.nickname ?? n.name ?? "APP" }
    function appIcon(n) {
        const p = n.properties ?? {};
        for (const k of [p["application.icon-name"], p["application.process.binary"], p["application.name"]]) {
            if (!k) continue;
            const path = Quickshell.iconPath(String(k).toLowerCase(), true);
            if (path !== "") return path;
        }
        return "";
    }
    function volIcon(v, m) { return m ? "volx" : v > 0.5 ? "vol2" : v > 0 ? "vol1" : "vol0" }

    component Label: Text { color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
    component Head: Item {
        property string title: ""
        property string note: ""
        width: root.width; height: 20
        DotText { id: ht; anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: parent.title; px: 1.3; gap: 1; color: Theme.red }
        Label { anchors { left: ht.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: parent.note }
    }
    // round mute button that fills with the accent when muted
    component MuteBtn: Rectangle {
        id: mb
        property string icon: "vol2"
        property bool muted: false
        property real size: 44
        signal clicked()
        width: size; height: size; radius: size / 2
        color: muted ? Theme.red : mba.containsMouse ? Theme.hover : Theme.surface
        border.color: muted ? Theme.red : Theme.blockBorder
        Behavior on color { ColorAnimation { duration: Theme.ms(180) } }
        scale: mba.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Theme.ms(110) } }
        DotIcon { anchors.centerIn: parent; name: mb.icon; px: mb.size > 40 ? 1.5 : 1.1; gap: 0.8; color: mb.muted ? Theme.onAccent : Theme.fg }
        MouseArea { id: mba; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mb.clicked() }
    }

    // ---------- master ----------
    Rectangle {
        id: hero
        width: root.width
        height: 178
        radius: Theme.cardRadius + 2
        color: Theme.card
        border.color: Audio.muted ? Theme.blockBorder : Qt.alpha(Theme.red, 0.45)
        clip: true

        // the live spectrum, faint, behind everything
        Canvas {
            id: spec
            // a small live band between the number and the mute button
            anchors { left: parent.left; leftMargin: 16 + numRow.width + 22; right: muteBig.left; rightMargin: 14
                      top: parent.top; topMargin: 34 }
            height: 40
            opacity: Audio.muted ? 0 : 0.5
            Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }
            readonly property var vals: Spectrum.values
            onValsChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const v = vals ?? [];
                if (v.length === 0) return;
                const c = 8, d = c * 0.6, cols = Math.floor(width / c), rows = Math.floor(height / c);
                ctx.fillStyle = String(Theme.red);
                for (let i = 0; i < cols; i++) {
                    // mirror the bands from the middle out
                    const k = Math.abs(i - cols / 2) / (cols / 2);
                    const val = v[Math.min(v.length - 1, Math.floor(k * v.length))] ?? 0;
                    const h = Math.round(val * rows);
                    for (let r = 0; r < h; r++)
                        DotFont.dot(ctx, i * c + (c - d) / 2, height - (r + 1) * c + (c - d) / 2, d, Theme.dotShape);
                }
            }
        }

        Column {
            id: heroText
            anchors { left: parent.left; top: parent.top; margins: 16 }
            spacing: 8
            Label { text: "OUTPUT"; font.letterSpacing: 1; font.weight: Font.DemiBold }
            Row {
                id: numRow
                spacing: 4
                DotText {
                    id: big
                    text: String(Audio.percent)
                    px: 4.2; gap: 1.6
                    color: Audio.muted ? Theme.muted : Theme.fg
                }
                DotText { anchors.bottom: big.bottom; text: "%"; px: 2; gap: 1; color: Theme.red }
            }
            Label {
                width: Math.min(implicitWidth, hero.width - 32)
                elide: Text.ElideRight
                text: Audio.muted ? "muted" : Audio.sink ? root.devName(Audio.sink) : "no output"
                font.pixelSize: 12
            }
        }
        MuteBtn {
            id: muteBig
            anchors { right: parent.right; top: parent.top; margins: 16 }
            icon: root.volIcon(Audio.volume, Audio.muted)
            muted: Audio.muted
            onClicked: Audio.toggleMute()
        }
        LevelBar {
            id: lvl
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            rows: 6; cell: 10
            value: Audio.volume
            muted: Audio.muted
            step: Settings.s.volumeStep / 100
            onMoved: v => Audio.setVolume(v)
        }
    }

    Row {
        spacing: 6
        Repeater {
            model: [0, 25, 50, 75, 100]
            delegate: GwButton {
                required property int modelData
                label: modelData + "%"; small: true
                active: Audio.percent === modelData && !Audio.muted
                onClicked: Audio.setVolume(modelData / 100)
            }
        }
    }

    // ---------- outputs ----------
    Head { title: "DEVICES"; note: root.sinks.length + " outputs" }
    Grid {
        id: outGrid
        width: root.width
        columns: root.wide ? 3 : 2
        spacing: 8
        readonly property real cw: (width - (columns - 1) * spacing) / columns
        Repeater {
            model: root.sinks
            delegate: Rectangle {
                id: oc
                required property var modelData
                readonly property bool on: modelData === Pipewire.defaultAudioSink
                width: outGrid.cw; height: 82
                radius: Theme.cardRadius
                color: on ? Qt.alpha(Theme.red, 0.12) : ocm.containsMouse ? Theme.hover : Theme.card
                border.color: on ? Theme.red : Theme.blockBorder
                Behavior on color { ColorAnimation { duration: Theme.ms(180) } }
                scale: ocm.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: Theme.ms(110) } }
                Rectangle {
                    id: oib
                    x: 10; y: 10
                    width: 30; height: 30; radius: 9
                    color: oc.on ? Theme.red : Theme.surface
                    DotIcon { anchors.centerIn: parent; name: root.devIcon(oc.modelData); px: 1.1; gap: 0.7; color: oc.on ? Theme.onAccent : Theme.fg }
                }
                Rectangle {
                    visible: oc.on
                    anchors { right: parent.right; top: parent.top; margins: 12 }
                    width: 7; height: 7; radius: 3.5; color: Theme.red
                    SequentialAnimation on opacity {
                        running: oc.on && root.active; loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    id: ocText
                    anchors { left: parent.left; right: parent.right; top: oib.bottom; margins: 10; topMargin: 8 }
                    text: root.devName(oc.modelData)
                    color: oc.on ? Theme.fg : Theme.muted
                    font.family: Theme.uiFont; font.pixelSize: 11
                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                }
                MouseArea { id: ocm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Pipewire.preferredDefaultAudioSink = oc.modelData }
            }
        }
    }

    // ---------- microphone ----------
    Head { title: "MICROPHONE"; note: root.mic ? root.devName(root.mic) : "none" }
    Rectangle {
        visible: root.mic !== null
        width: root.width; height: 64
        radius: Theme.cardRadius
        color: Theme.card
        border.color: Theme.blockBorder
        MuteBtn {
            id: micBtn
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            size: 36
            icon: root.mic?.audio?.muted ? "micx" : "mic"
            muted: root.mic?.audio?.muted ?? false
            onClicked: if (root.mic?.ready) root.mic.audio.muted = !root.mic.audio.muted
        }
        LevelBar {
            anchors { left: micBtn.right; leftMargin: 12; right: micPct.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            rows: 4; cell: 8
            value: root.mic?.audio?.volume ?? 0
            muted: root.mic?.audio?.muted ?? false
            onMoved: v => { if (root.mic?.ready) root.mic.audio.volume = v }
        }
        Text {
            id: micPct
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            width: 40; horizontalAlignment: Text.AlignRight
            text: Math.round((root.mic?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium
        }
    }
    Flow {
        visible: root.sources.length > 1
        width: root.width
        spacing: 6
        Repeater {
            model: root.sources
            delegate: GwButton {
                required property var modelData
                small: true
                label: { const t = root.devName(modelData); return t.length > 28 ? t.slice(0, 27) + "…" : t }
                active: modelData === Pipewire.defaultAudioSource
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    // ---------- apps ----------
    Head { title: "APPS"; note: root.streams.length === 0 ? "nothing playing" : root.streams.length + " playing" }
    Grid {
        id: appGrid
        width: root.width
        columns: root.wide ? 2 : 1
        spacing: 6
        readonly property real cw: (width - (columns - 1) * spacing) / columns
        Repeater {
            model: root.streams
            delegate: Rectangle {
                id: ac
                required property var modelData
                readonly property bool muted: modelData.audio?.muted ?? false
                readonly property string iconPath: root.appIcon(modelData)
                width: appGrid.cw; height: 62
                radius: Theme.cardRadius
                color: Theme.card
                border.color: Theme.blockBorder
                opacity: 0
                Component.onCompleted: fadeIn.start()
                NumberAnimation { id: fadeIn; target: ac; property: "opacity"; to: 1; duration: Theme.ms(300) }

                Rectangle {
                    id: aib
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 38; height: 38; radius: 10
                    color: Theme.surface
                    Image {
                        anchors.centerIn: parent
                        visible: ac.iconPath !== ""
                        source: ac.iconPath
                        width: 24; height: 24; sourceSize: Qt.size(48, 48)
                        opacity: ac.muted ? 0.35 : 1
                    }
                    DotIcon { anchors.centerIn: parent; visible: ac.iconPath === ""; name: "note"; px: 1.2; gap: 0.8; color: Theme.fg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: if (ac.modelData.ready) ac.modelData.audio.muted = !ac.muted }
                    Rectangle {
                        visible: ac.muted
                        anchors { right: parent.right; bottom: parent.bottom; margins: -3 }
                        width: 14; height: 14; radius: 7; color: Theme.red
                        DotIcon { anchors.centerIn: parent; name: "x"; px: 0.6; gap: 0.4; color: Theme.onAccent }
                    }
                }
                Column {
                    anchors { left: aib.right; leftMargin: 10; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Row {
                        width: parent.width
                        DotText {
                            text: root.appName(ac.modelData).toUpperCase()
                            maxWidth: parent.width - 40
                            px: 1.25; gap: 0.95
                            color: ac.muted ? Theme.muted : Theme.fg
                        }
                    }
                    Row {
                        width: parent.width
                        spacing: 6
                        LevelBar {
                            width: parent.width - 40
                            rows: 3; cell: 7
                            value: ac.modelData.audio?.volume ?? 0
                            muted: ac.muted
                            onMoved: v => { if (ac.modelData.ready) ac.modelData.audio.volume = v }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34; horizontalAlignment: Text.AlignRight
                            text: Math.round((ac.modelData.audio?.volume ?? 0) * 100) + "%"
                            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}

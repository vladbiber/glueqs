import QtQuick

// Monitors page: every output drawn to scale where gluewc has it, dragged
// into place, and a detail card for the selected one. Everything is written
// as output lines in config.conf; the compositor applies them on save, and a
// change that can leave a screen dark runs on a 15 s trial first.
Column {
    id: page
    spacing: 0
    property string selected: ""
    readonly property var outs: Gluewc.outputs
    readonly property var placed: outs.filter(o => o.enabled && o.mirror === "none")
    readonly property var mirrors: outs.filter(o => o.enabled && o.mirror !== "none")
    readonly property var off: outs.filter(o => !o.enabled)
    readonly property var sel: Gluewc.output(selected)
    readonly property var transforms: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]

    onOutsChanged: {
        if (sel === null && outs.length > 0)
            selected = (Gluewc.focusedOutput() ?? outs[0]).name;
    }

    function apply(name, patch) { Gluewc.beginTrial(); Gluewc.setOutput(name, patch); }
    function modeLabel(m) {
        const at = m.indexOf("@");
        const wh = (at < 0 ? m : m.slice(0, at)).replace("x", " × ");
        return at < 0 ? wh : wh + "   " + m.slice(at + 1) + " Hz";
    }
    // "output = * mirror=NAME" mirrors every other screen onto NAME; a
    // per-screen mirror key would override it, so those are cleared too
    function sameOnAll() {
        const primary = (sel && sel.enabled && sel.mirror === "none") ? sel : Gluewc.focusedOutput();
        if (!primary) return;
        const ch = [{ name: "*", patch: { mirror: primary.name } }];
        for (const o of outs) ch.push({ name: o.name, patch: { mirror: null, enabled: null } });
        Gluewc.beginTrial();
        Gluewc.setOutputs(ch);
    }
    function extend() {
        const ch = [{ name: "*", patch: { mirror: null } }];
        for (const o of outs) ch.push({ name: o.name, patch: { mirror: null, pos: null, enabled: null } });
        Gluewc.beginTrial();
        Gluewc.setOutputs(ch);
    }

    component Small: Text {
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11
    }
    component Label: Text {
        color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium
    }
    component Sub: Text {
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11; font.letterSpacing: 1
        topPadding: 12; bottomPadding: 4
    }

    GwTitle {
        first: true
        text: "MONITORS"
        sub: "Drag a screen to move it, click it to edit. Same on all mirrors every screen onto one; extend gives each its own desktop."
    }

    // ---- quick actions ----
    Row {
        width: parent.width
        spacing: 8
        topPadding: 10
        bottomPadding: 10
        GwButton { label: "SAME ON ALL"; enabled: page.outs.length > 1; onClicked: page.sameOnAll() }
        GwButton { label: "EXTEND"; enabled: page.outs.length > 1; onClicked: page.extend() }
        GwButton { label: "IDENTIFY"; enabled: page.outs.length > 0; onClicked: Gluewc.identify() }
        Item { width: 12; height: 1 }
        Small {
            anchors.verticalCenter: parent.verticalCenter
            text: page.outs.length === 0 ? ""
                : page.placed.length + " active" + (page.mirrors.length ? ", " + page.mirrors.length + " mirrored" : "")
                  + (page.off.length ? ", " + page.off.length + " off" : "")
        }
    }

    // ---- the map ----
    Rectangle {
        id: map
        width: parent.width
        height: 250
        radius: 10
        color: "#080808"
        border.color: Theme.blockBorder
        clip: true

        readonly property real pad: 26
        readonly property var bbox: {
            let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
            for (const o of page.placed) {
                x0 = Math.min(x0, o.x); y0 = Math.min(y0, o.y);
                x1 = Math.max(x1, o.x + o.w); y1 = Math.max(y1, o.y + o.h);
            }
            return page.placed.length ? { x: x0, y: y0, w: Math.max(1, x1 - x0), h: Math.max(1, y1 - y0) } : { x: 0, y: 0, w: 1, h: 1 };
        }
        readonly property real s: Math.min((width - 2 * pad) / bbox.w, (height - 2 * pad) / bbox.h, 0.4)
        readonly property real ox: (width - bbox.w * s) / 2 - bbox.x * s
        readonly property real oy: (height - bbox.h * s) / 2 - bbox.y * s

        function snap(o, lx, ly) {
            const thr = 16 / s;
            let bx = lx, by = ly, dx = thr, dy = thr;
            for (const p of page.placed) {
                if (p.name === o.name) continue;
                for (const c of [p.x, p.x + p.w, p.x - o.w, p.x + p.w - o.w])
                    if (Math.abs(lx - c) < dx) { dx = Math.abs(lx - c); bx = c; }
                for (const c of [p.y, p.y + p.h, p.y - o.h, p.y + p.h - o.h])
                    if (Math.abs(ly - c) < dy) { dy = Math.abs(ly - c); by = c; }
            }
            return { x: Math.round(bx), y: Math.round(by) };
        }
        // one output moved; everything is shifted if it went above or left of 0
        function dropped(o, px, py) {
            const l = snap(o, (px - ox) / s, (py - oy) / s);
            let minX = l.x, minY = l.y;
            for (const p of page.placed) if (p.name !== o.name) { minX = Math.min(minX, p.x); minY = Math.min(minY, p.y); }
            const ch = [];
            if (minX < 0 || minY < 0) {
                for (const p of page.placed)
                    ch.push({ name: p.name, patch: { pos: (p.name === o.name ? l.x - minX : p.x - minX) + "," + (p.name === o.name ? l.y - minY : p.y - minY) } });
            } else {
                ch.push({ name: o.name, patch: { pos: l.x + "," + l.y } });
            }
            Gluewc.beginTrial();
            Gluewc.setOutputs(ch);
        }

        Small {
            anchors.centerIn: parent
            visible: page.outs.length === 0
            width: parent.width - 60
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "gluewc has not published its outputs yet. This page needs a gluewc that writes " + Gluewc.stateDir + "/outputs."
        }

        Repeater {
            model: page.placed
            delegate: Rectangle {
                id: box
                required property var modelData
                readonly property bool isSel: page.selected === modelData.name
                readonly property var ghosts: page.mirrors.filter(m => m.mirror === box.modelData.name)
                property bool dragging: false
                function place() {
                    x = Qt.binding(() => map.ox + box.modelData.x * map.s);
                    y = Qt.binding(() => map.oy + box.modelData.y * map.s);
                }
                Component.onCompleted: place()
                width: Math.max(40, modelData.w * map.s)
                height: Math.max(24, modelData.h * map.s)
                radius: 6
                color: dragging ? "#242424" : isSel ? "#1c1c1c" : bma.containsMouse ? "#181818" : "#121212"
                border.color: isSel || modelData.focused ? Theme.red : "#3a3a3a"
                border.width: isSel ? 2 : 1
                z: dragging ? 10 : isSel ? 2 : 1

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    width: parent.width - 12
                    Label { width: parent.width; text: box.modelData.name; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                    Small {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        text: box.modelData.pw + " × " + box.modelData.ph
                    }
                    Small {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        visible: box.height > 60
                        text: (box.modelData.hz > 0 ? box.modelData.hz.toFixed(0) + " Hz" : "") + (box.modelData.scale !== 1 ? "  ·  " + box.modelData.scale.toFixed(2) + "×" : "")
                              + (box.modelData.transform !== "normal" ? "  ·  " + box.modelData.transform : "")
                    }
                    Small {
                        width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        visible: box.ghosts.length > 0 && box.height > 80
                        color: Theme.red
                        text: "+ " + box.ghosts.map(g => g.name).join(", ") + " mirrored"
                    }
                }
                Small {
                    anchors { top: parent.top; left: parent.left; margins: 6 }
                    visible: box.dragging
                    color: Theme.red
                    text: Math.round((box.x - map.ox) / map.s) + ", " + Math.round((box.y - map.oy) / map.s)
                }
                Rectangle {
                    visible: box.modelData.focused
                    anchors { top: parent.top; right: parent.right; margins: 6 }
                    width: 6; height: 6; radius: 3
                    color: Theme.red
                }
                MouseArea {
                    id: bma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: box.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: box
                    drag.threshold: 4
                    onPressed: page.selected = box.modelData.name
                    drag.onActiveChanged: {
                        if (drag.active) { box.dragging = true; return; }
                        box.dragging = false;
                        map.dropped(box.modelData, box.x, box.y);
                        box.place();
                    }
                }
            }
        }

        // mirrors sit inside their source, ghosted
        Repeater {
            model: page.mirrors
            delegate: Rectangle {
                id: ghost
                required property var modelData
                required property int index
                readonly property var src: Gluewc.output(modelData.mirror)
                visible: src !== null && src.enabled
                readonly property real inset: 10 + index * 6
                x: src ? map.ox + src.x * map.s + inset : 0
                y: src ? map.oy + src.y * map.s + inset : 0
                width: src ? Math.max(20, src.w * map.s - 2 * inset) : 0
                height: src ? Math.max(12, src.h * map.s - 2 * inset) : 0
                z: 5
                radius: 5
                color: page.selected === modelData.name ? "#2a1214" : "#00000000"
                border.color: page.selected === modelData.name ? Theme.red : "#6a2a2e"
                border.width: 1
                Small {
                    anchors { bottom: parent.bottom; right: parent.right; margins: 5 }
                    color: Theme.red
                    text: ghost.modelData.name + " = mirror"
                }
                MouseArea { anchors.fill: parent; onClicked: page.selected = ghost.modelData.name }
            }
        }
    }

    // ---- switched off ----
    Row {
        width: parent.width
        spacing: 8
        topPadding: 10
        visible: page.off.length > 0
        Small { anchors.verticalCenter: parent.verticalCenter; text: "OFF" }
        Repeater {
            model: page.off
            delegate: GwButton {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                label: modelData.name + "   ·   turn on"
                active: page.selected === modelData.name
                onClicked: { page.selected = modelData.name; page.apply(modelData.name, { enabled: null }); }
            }
        }
    }

    // ---- selected output ----
    Item { width: 1; height: 14 }
    Loader {
        width: parent.width
        active: page.sel !== null
        sourceComponent: detail
    }

    Component {
        id: detail
        Column {
            id: card
            readonly property var o: page.sel
            readonly property var cfg: Gluewc.outputCfg[o.name] ?? ({})
            readonly property real colW: (width - 24) / 2
            spacing: 0

            Row {
                width: parent.width
                spacing: 12
                DotText { anchors.verticalCenter: parent.verticalCenter; text: card.o.name; px: 1.8; gap: 1 }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Label {
                        text: (card.o.make !== "none" ? card.o.make + " " : "") + (card.o.model !== "none" ? card.o.model : "")
                        visible: text.trim() !== ""
                    }
                    Small {
                        text: !card.o.enabled ? "switched off"
                            : card.o.mirror !== "none" ? "mirrors " + card.o.mirror
                            : card.o.pw + " × " + card.o.ph + " @ " + card.o.hz.toFixed(2) + " Hz   ·   " + card.o.w + " × " + card.o.h + " logical at " + card.o.x + ", " + card.o.y
                    }
                }
                Item { width: 1; height: 1 }
                GwButton { anchors.verticalCenter: parent.verticalCenter; visible: card.o.focused; label: "FOCUSED"; active: true; small: true; enabled: false; opacity: 1 }
            }
            Item { width: 1; height: 8 }
            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }

            Row {
                width: parent.width
                spacing: 24

                // left: on/off and the mode list
                Column {
                    width: card.colW
                    spacing: 0
                    Sub { text: "POWER" }
                    Row {
                        spacing: 10
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.o.enabled ? "ON" : "OFF"
                            color: card.o.enabled ? Theme.fg : "#9a9a9a"
                            font.family: Theme.uiFont; font.pixelSize: 12; font.letterSpacing: 0.6
                        }
                        DotToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            on: card.o.enabled
                            onToggled: page.apply(card.o.name, { enabled: card.o.enabled ? "false" : null })
                        }
                        Small { anchors.verticalCenter: parent.verticalCenter; visible: page.placed.length <= 1 && card.o.enabled && card.o.mirror === "none"; text: "the last screen stays on" }
                    }

                    Sub { text: "MODE" }
                    Rectangle {
                        width: parent.width
                        height: Math.min(212, modeList.contentHeight + 2)
                        radius: 8
                        color: "#0e0e0e"
                        border.color: Theme.blockBorder
                        clip: true
                        ListView {
                            id: modeList
                            anchors { fill: parent; margins: 1 }
                            boundsBehavior: Flickable.StopAtBounds
                            model: ["preferred"].concat(card.o.modes)
                            delegate: Rectangle {
                                id: mrow
                                required property string modelData
                                required property int index
                                readonly property bool isPref: modelData === "preferred"
                                readonly property bool current: isPref ? (card.cfg.mode === undefined || card.cfg.mode === "preferred")
                                                                       : card.cfg.mode === modelData
                                readonly property bool live: !isPref && modelData === card.o.pw + "x" + card.o.ph + "@" + card.o.hz.toFixed(2)
                                width: modeList.width; height: 30
                                color: mma.containsMouse ? "#1a1a1a" : current ? "#161616" : "transparent"
                                Rectangle { visible: mrow.current; width: 2; height: parent.height - 8; y: 4; color: Theme.red }
                                Text {
                                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: mrow.isPref ? "Preferred" + (card.o.preferred !== "none" ? "   " + page.modeLabel(card.o.preferred) : "")
                                                      : page.modeLabel(mrow.modelData)
                                    color: mrow.current || mrow.live ? Theme.fg : "#c8c8c8"
                                    font.family: Theme.uiFont; font.pixelSize: 12
                                    font.weight: mrow.current ? Font.DemiBold : Font.Normal
                                }
                                Small {
                                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                    color: Theme.red
                                    text: mrow.live ? "NOW" : (!mrow.isPref && mrow.modelData === card.o.preferred ? "PREF" : "")
                                }
                                MouseArea {
                                    id: mma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: page.apply(card.o.name, { mode: mrow.isPref ? null : mrow.modelData })
                                }
                            }
                        }
                    }
                    Small {
                        visible: card.o.modes.length === 0
                        topPadding: 6
                        text: "No fixed modes reported. Type one in config.conf as mode=WxH@Hz if you need a custom size."
                        width: parent.width; wrapMode: Text.WordWrap
                    }
                }

                // right: scale, rotation, position, mirror
                Column {
                    width: card.colW
                    spacing: 0
                    Sub { text: "SCALE" }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [1, 1.25, 1.5, 2]
                            delegate: GwButton {
                                required property real modelData
                                label: modelData + "×"; small: true
                                active: Math.abs(card.o.scale - modelData) < 0.001
                                onClicked: page.apply(card.o.name, { scale: String(modelData) })
                            }
                        }
                    }
                    Item { width: 1; height: 8 }
                    GwNumber {
                        bound: true; value: card.o.scale
                        min: 0.5; max: 4; step: 0.05; decimals: 2; unit: "×"; fieldWidth: 70
                        onChanged: v => page.apply(card.o.name, { scale: v.toFixed(2) })
                    }

                    Sub { text: "ROTATION" }
                    Row {
                        spacing: 6
                        GwButton {
                            label: "<"; small: true; implicitWidth: 28
                            onClicked: {
                                const i = page.transforms.indexOf(card.o.transform);
                                const n = page.transforms[(i + page.transforms.length - 1) % page.transforms.length];
                                page.apply(card.o.name, { transform: n === "normal" ? null : n });
                            }
                        }
                        Rectangle {
                            width: 120; height: 24; radius: 6; color: "#141414"; border.color: Theme.blockBorder
                            Text { anchors.centerIn: parent; text: card.o.transform; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12 }
                        }
                        GwButton {
                            label: ">"; small: true; implicitWidth: 28
                            onClicked: {
                                const i = page.transforms.indexOf(card.o.transform);
                                const n = page.transforms[(i + 1) % page.transforms.length];
                                page.apply(card.o.name, { transform: n === "normal" ? null : n });
                            }
                        }
                    }

                    Sub { text: "POSITION" }
                    Row {
                        spacing: 8
                        Small { anchors.verticalCenter: parent.verticalCenter; text: "X" }
                        GwNumber {
                            bound: true; value: card.o.x; min: 0; max: 32768; step: 10; fieldWidth: 64
                            onChanged: v => page.apply(card.o.name, { pos: Math.round(v) + "," + card.o.y })
                        }
                        Small { anchors.verticalCenter: parent.verticalCenter; text: "Y" }
                        GwNumber {
                            bound: true; value: card.o.y; min: 0; max: 32768; step: 10; fieldWidth: 64
                            onChanged: v => page.apply(card.o.name, { pos: card.o.x + "," + Math.round(v) })
                        }
                    }
                    Item { width: 1; height: 6 }
                    GwButton {
                        label: "AUTO"; small: true
                        active: card.cfg.pos === undefined || card.cfg.pos === "auto"
                        onClicked: page.apply(card.o.name, { pos: null })
                    }

                    Sub { text: "MIRROR" }
                    Flow {
                        width: parent.width
                        spacing: 6
                        GwButton {
                            label: "NONE"; small: true
                            active: card.o.mirror === "none"
                            onClicked: page.apply(card.o.name, { mirror: null })
                        }
                        Repeater {
                            model: page.placed.filter(p => p.name !== card.o.name)
                            delegate: GwButton {
                                required property var modelData
                                label: modelData.name; small: true
                                active: card.o.mirror === modelData.name
                                onClicked: page.apply(card.o.name, { mirror: modelData.name })
                            }
                        }
                    }
                    Small {
                        topPadding: 6
                        width: parent.width; wrapMode: Text.WordWrap
                        text: "A mirror shows the other screen whole, letterboxed if the shapes differ, and has no desktop of its own."
                    }

                    Sub { text: "ADAPTIVE SYNC" }
                    Row {
                        spacing: 10
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.cfg.adaptive_sync === "true" ? "ON" : "OFF"
                            color: card.cfg.adaptive_sync === "true" ? Theme.fg : "#9a9a9a"
                            font.family: Theme.uiFont; font.pixelSize: 12; font.letterSpacing: 0.6
                        }
                        DotToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            on: card.cfg.adaptive_sync === "true"
                            onToggled: Gluewc.setOutput(card.o.name, { adaptive_sync: on ? null : "true" })
                        }
                    }
                    Item { width: 1; height: 12 }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }
            Small {
                topPadding: 8
                width: parent.width; wrapMode: Text.WordWrap
                text: "Written as   output = " + card.o.name + " ...   in ~/.config/gluewc/config.conf"
                      + (Gluewc.outputCfg["*"] ? "   ·   an  output = *  line sets the defaults for every screen" : "")
            }
        }
    }
}

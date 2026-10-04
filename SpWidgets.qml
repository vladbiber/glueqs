import QtQuick
import "Widgets.js" as W

// WIDGETS: what is on the bar (order, zone, on/off, remove) and a gallery of
// everything that can be added, the new ones with a live preview.
Column {
    id: page
    width: parent.width
    spacing: 0

    readonly property var zoneKeys: ["barLeft", "barCenter", "barRight"]
    readonly property var zoneNames: ["LEFT", "CENTER", "RIGHT"]
    function zoneList(z) { return Settings.s[zoneKeys[z]].split(",").filter(x => x !== "") }
    function saveZone(z, arr) { Settings.s[zoneKeys[z]] = arr.join(",") }
    readonly property var placed: {
        const out = [];
        for (let z = 0; z < 3; z++) {
            const l = Settings.s[zoneKeys[z]].split(",").filter(x => x !== "");
            for (let i = 0; i < l.length; i++) out.push({ id: l[i], zone: z, idx: i, last: i === l.length - 1 });
        }
        return out;
    }
    function isPlaced(id) { return placed.some(p => p.id === id) }
    function move(zone, idx, dir) {
        const arr = zoneList(zone);
        const j = idx + dir;
        if (j < 0 || j >= arr.length) {
            // past the end of a zone: hop into the neighbour
            const nz = zone + dir;
            if (nz < 0 || nz > 2) return;
            const id = arr.splice(idx, 1)[0];
            saveZone(zone, arr);
            const n = zoneList(nz);
            if (dir > 0) n.unshift(id); else n.push(id);
            saveZone(nz, n);
            return;
        }
        const t = arr[idx]; arr[idx] = arr[j]; arr[j] = t;
        saveZone(zone, arr);
    }
    function setZone(zone, idx, nz) {
        if (nz === zone) return;
        const arr = zoneList(zone);
        const id = arr.splice(idx, 1)[0];
        saveZone(zone, arr);
        const n = zoneList(nz); n.push(id); saveZone(nz, n);
    }
    function remove(zone, idx) {
        const arr = zoneList(zone);
        arr.splice(idx, 1);
        saveZone(zone, arr);
    }
    property int addZone: 2
    function add(id) {
        const n = zoneList(addZone); n.push(id); saveZone(addZone, n);
        const w = W.byId(id);
        if (w.key) Settings.s[w.key] = true;
    }
    property string group: "all"

    GwTitle { first: true; text: "ON THE BAR"; sub: "Arrows move a widget along the bar (and across zones at the ends). The zone button sends it LEFT, CENTER or RIGHT. The switch hides it without losing its place; × takes it off." }
    GwCard {
        Repeater {
            model: page.placed
            delegate: Item {
                id: orow
                required property var modelData
                required property int index
                readonly property var w: W.byId(modelData.id)
                readonly property string vkey: w.key ?? ""
                readonly property bool lit: vkey === "" || (Settings.s[vkey] ?? true)
                width: parent.width; height: 50
                // a zone heading above the first widget of each zone
                Rectangle {
                    anchors.fill: parent; anchors.margins: 1
                    radius: 8
                    color: rma.containsMouse ? Theme.hover : "transparent"
                }
                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    GwButton { label: "↑"; small: true; implicitWidth: 26; onClicked: page.move(orow.modelData.zone, orow.modelData.idx, -1) }
                    GwButton { label: "↓"; small: true; implicitWidth: 26; onClicked: page.move(orow.modelData.zone, orow.modelData.idx, 1) }
                    Item { width: 6; height: 1 }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30; height: 30; radius: 8
                        color: Theme.surface; border.color: Theme.border
                        DotIcon { anchors.centerIn: parent; name: orow.w.icon; px: 1.1; gap: 0.8; color: orow.lit ? Theme.fg : Theme.muted }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: orow.w.name
                            color: orow.lit ? Theme.fg : Theme.muted
                            font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium
                        }
                        Text { text: orow.w.desc; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 10 }
                    }
                }
                Row {
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    GwChoice {
                        anchors.verticalCenter: parent.verticalCenter
                        bound: true; value: String(orow.modelData.zone)
                        options: [{ v: "0", label: "L" }, { v: "1", label: "C" }, { v: "2", label: "R" }]
                        onPicked: v => page.setZone(orow.modelData.zone, orow.modelData.idx, parseInt(v))
                    }
                    DotToggle {
                        visible: orow.vkey !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        on: orow.lit
                        onToggled: Settings.s[orow.vkey] = !Settings.s[orow.vkey]
                    }
                    Item { visible: orow.vkey === ""; width: 30; height: 1 }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: orow.modelData.id !== "settings"
                        width: 26; height: 26; radius: 13
                        color: xa.containsMouse ? Qt.alpha(Theme.red, 0.18) : "transparent"
                        border.color: xa.containsMouse ? Theme.red : Theme.border
                        DotIcon { anchors.centerIn: parent; name: "x"; px: 0.9; gap: 0.6; color: xa.containsMouse ? Theme.red : Theme.muted }
                        MouseArea { id: xa; anchors.fill: parent; hoverEnabled: true; onClicked: page.remove(orow.modelData.zone, orow.modelData.idx) }
                    }
                    Item { visible: orow.modelData.id === "settings"; width: 26; height: 1 }
                }
                Rectangle {
                    visible: !orow.modelData.last
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 14; rightMargin: 14 }
                    height: 1; color: Theme.line
                }
                // a thicker break between zones
                Rectangle {
                    visible: orow.modelData.last && orow.modelData.zone < 2
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 14; rightMargin: 14 }
                    height: 2; color: Qt.alpha(Theme.red, 0.4)
                }
            }
        }
    }

    GwTitle { text: "ADD WIDGETS"; sub: "Off until you add them. Visualisers and spacers can go on the bar more than once." }
    Row {
        spacing: 8
        bottomPadding: 12
        Text { anchors.verticalCenter: parent.verticalCenter; text: "Add to"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 12 }
        GwChoice {
            bound: true; value: String(page.addZone)
            options: [{ v: "0", label: "LEFT" }, { v: "1", label: "CENTER" }, { v: "2", label: "RIGHT" }]
            onPicked: v => page.addZone = parseInt(v)
        }
    }
    Flow {
        width: parent.width
        spacing: 6
        bottomPadding: 12
        Repeater {
            model: W.GROUPS
            delegate: GwButton {
                required property var modelData
                small: true
                label: modelData.name
                active: page.group === modelData.id
                onClicked: page.group = modelData.id
            }
        }
    }
    Grid {
        id: gallery
        width: parent.width
        columns: 3
        spacing: 10
        readonly property real cw: (width - spacing * (columns - 1)) / columns
        Repeater {
            model: W.LIST.filter(w => page.group === "all" || w.group === page.group)
            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool onBar: page.isPlaced(modelData.id)
                readonly property bool canAdd: modelData.multi || !onBar
                width: gallery.cw; height: 150
                radius: Theme.cardRadius
                color: gma.containsMouse ? Theme.hover : Theme.card
                border.color: onBar ? Qt.alpha(Theme.red, 0.6) : gma.containsMouse ? Theme.strong : Theme.border
                Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
                scale: gma.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }
                MouseArea { id: gma; anchors.fill: parent; hoverEnabled: true; onClicked: if (card.canAdd) page.add(card.modelData.id) }

                // preview: the real tile for the new kinds, the icon for the rest
                Rectangle {
                    id: stage
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                    height: 62; radius: 8
                    color: Theme.bg
                    clip: true
                    Loader {
                        anchors.centerIn: parent
                        readonly property string wid: card.modelData.id
                        active: card.modelData.isNew === true && wid !== "spacer"
                        source: wid.startsWith("viz:") ? "VizWidget.qml"
                              : ["cpu", "ram", "temp", "disk"].includes(wid) ? "StatWidget.qml" : "ButtonWidget.qml"
                        onLoaded: {
                            if (wid.startsWith("viz:")) { item.style = wid.slice(4); item.visible = true; }
                            else item.kind = wid;
                        }
                    }
                    DotIcon {
                        visible: card.modelData.isNew !== true || card.modelData.id === "spacer"
                        anchors.centerIn: parent
                        name: card.modelData.icon; px: 2.2; gap: 1.2
                    }
                }
                Column {
                    anchors { top: stage.bottom; left: parent.left; right: parent.right; margins: 10; topMargin: 8 }
                    spacing: 3
                    Text { width: parent.width; text: card.modelData.name; elide: Text.ElideRight; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.Medium }
                    Text { width: parent.width; text: card.modelData.desc; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 10 }
                }
                Rectangle {
                    anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                    width: addLbl.implicitWidth + 14; height: 20; radius: 10
                    color: card.canAdd ? (gma.containsMouse ? Theme.red : "transparent") : "transparent"
                    border.color: card.canAdd ? Theme.red : Theme.border
                    Text {
                        id: addLbl
                        anchors.centerIn: parent
                        text: card.canAdd ? (card.onBar ? "+ ANOTHER" : "+ ADD") : "ON THE BAR"
                        color: card.canAdd && gma.containsMouse ? Theme.onAccent : card.canAdd ? Theme.red : Theme.muted
                        font.family: Theme.uiFont; font.pixelSize: 9; font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}

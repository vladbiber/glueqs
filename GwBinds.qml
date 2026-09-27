import Quickshell
import QtQuick
import "GwActions.js" as Actions

// Keybinds. SIMPLE says what each key does in words and edits a bind with a
// key-capture box and an action picker; ADVANCED is the raw combo and action
// text. Both write bind lines to config.conf.
Column {
    id: page
    spacing: 0
    property string view: "simple"     // simple | advanced
    property string query: ""
    property string modeFilter: "all"  // all | insert | normal

    // the bind being edited, or null; isNew for a fresh one
    property var editing: null
    property bool picking: false
    property string pickerTab: "wm"

    readonly property var groupsOrder: ["Windows", "Focus", "Move", "Workspaces", "Layout", "Session", "Run", "Other"]
    readonly property var shown: {
        const q = query.toLowerCase();
        const l = Gluewc.binds.filter(b => {
            if (modeFilter !== "all" && b.mode !== modeFilter) return false;
            if (q === "") return true;
            const d = Actions.describe(b.action);
            return b.combo.toLowerCase().includes(q) || b.action.toLowerCase().includes(q)
                || d.label.toLowerCase().includes(q) || Actions.chips(b.combo).join(" ").toLowerCase().includes(q);
        });
        if (view === "advanced") return l;
        const rank = b => { const g = Actions.describe(b.action).group; const i = groupsOrder.indexOf(g); return i < 0 ? 99 : i; };
        return l.slice().sort((a, b) => rank(a) - rank(b));
    }
    readonly property var duplicates: {
        const seen = ({}), dup = ({});
        for (const b of Gluewc.binds) {
            const k = b.mode + " " + b.combo;
            if (seen[k]) dup[k] = true; else seen[k] = true;
        }
        return dup;
    }
    function isDup(b) { return duplicates[b.mode + " " + b.combo] === true }
    function defaultAction(b) { const d = Gluewc.defaultBind(b.mode, b.combo); return d ? d.action : null }

    function startEdit(b) {
        editing = { mode: b.mode, combo: b.combo, action: b.action, origMode: b.mode, origCombo: b.combo, isNew: false };
        picking = false;
    }
    function startNew() {
        editing = { mode: "insert", combo: "", action: "", origMode: "", origCombo: "", isNew: true };
        picking = true;
    }
    function patchEdit(p) { const e = Object.assign({}, editing); for (const k in p) e[k] = p[k]; editing = e; }
    readonly property var conflict: {
        if (!editing || editing.combo === "") return null;
        return Gluewc.binds.find(b => b.mode === editing.mode && b.combo === editing.combo
            && !(b.mode === editing.origMode && b.combo === editing.origCombo)) ?? null;
    }
    function saveEdit() {
        const e = editing;
        if (!e || e.combo === "" || e.action === "") return;
        if (!e.isNew && (e.origMode !== e.mode || e.origCombo !== e.combo))
            Gluewc.removeBind(e.origMode, e.origCombo);
        Gluewc.setBind(e.mode, e.combo, e.action);
        editing = null;
    }

    component Small: Text { color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11 }

    // GLUEQS_SHOT_BIND=edit|capture|new opens the editor for screenshots
    Timer {
        readonly property string what: Quickshell.env("GLUEQS_SHOT_BIND") ?? ""
        running: what !== "" && Gluewc.binds.length > 0
        interval: 800
        onTriggered: {
            if (what === "new" || what === "apps") { page.pickerTab = what === "apps" ? "apps" : "wm"; page.startNew(); return; }
            page.startEdit(Gluewc.binds.find(b => b.combo === "mod+c") ?? Gluewc.binds[0]);
            if (what === "capture") capture.focusCapture();
        }
    }
    component Chips: Row {
        property string combo: ""
        property real size: 12
        spacing: 4
        Repeater {
            model: Actions.chips(parent.combo)
            delegate: Rectangle {
                required property string modelData
                required property int index
                width: t.implicitWidth + 14; height: 24; radius: 6
                color: "#0a0a0a"; border.color: "#363636"
                Text { id: t; anchors.centerIn: parent; text: parent.modelData; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            }
        }
    }

    GwTitle {
        first: true
        text: "KEYBINDS"
        sub: "Super plus a key in insert mode, the everyday one. Normal mode (Super+Escape) takes the same keys without Super. Every change lands in config.conf and works immediately."
    }

    // ---- toolbar ----
    Row {
        width: parent.width
        spacing: 8
        topPadding: 10
        bottomPadding: 8
        GwChoice {
            anchors.verticalCenter: parent.verticalCenter
            bound: true; value: page.view
            options: [{ v: "simple", label: "SIMPLE" }, { v: "advanced", label: "ADVANCED" }]
            onPicked: v => { page.view = v; page.editing = null; }
        }
        GwField {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 8 * 3 - 170 - 200 - 110
            placeholder: "search: close, workspace 3, Super Q, spawn..."
            text: page.query
            onCommitted: v => page.query = v
        }
        GwChoice {
            anchors.verticalCenter: parent.verticalCenter
            bound: true; value: page.modeFilter
            options: [{ v: "all", label: "ALL" }, { v: "insert", label: "INSERT" }, { v: "normal", label: "NORMAL" }]
            onPicked: v => page.modeFilter = v
        }
        GwButton { anchors.verticalCenter: parent.verticalCenter; label: "+ NEW BIND"; active: true; visible: page.editing === null; onClicked: page.startNew() }
    }
    Small { text: page.shown.length + " of " + Gluewc.binds.length + " binds" + (Object.keys(page.duplicates).length ? "   ·   " + Object.keys(page.duplicates).length + " duplicated combo(s), the last line wins" : ""); bottomPadding: 8 }

    // ---- editor ----
    Rectangle {
        visible: page.editing !== null
        width: parent.width
        height: visible ? editor.implicitHeight + 32 : 0
        radius: 10
        color: "#111111"
        border.color: Theme.red
        Column {
            id: editor
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 12
            Row {
                width: parent.width
                spacing: 12
                DotText { anchors.verticalCenter: parent.verticalCenter; text: page.editing && page.editing.isNew ? "NEW BIND" : "EDIT BIND"; px: 1.2; gap: 1 }
                GwChoice {
                    anchors.verticalCenter: parent.verticalCenter
                    bound: true; value: page.editing ? page.editing.mode : "insert"
                    options: [{ v: "insert", label: "INSERT MODE" }, { v: "normal", label: "NORMAL MODE" }]
                    onPicked: v => page.patchEdit({ mode: v })
                }
            }

            // action
            Small { text: "DOES"; font.letterSpacing: 1 }
            Loader {
                width: parent.width
                active: page.picking
                sourceComponent: GwActionPicker {
                    tab: page.pickerTab
                    onPicked: a => { page.patchEdit({ action: a }); page.picking = false; }
                    onCancelled: { page.picking = false; if (page.editing && page.editing.action === "") page.editing = null; }
                }
            }
            Row {
                visible: !page.picking
                width: parent.width
                spacing: 10
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - changeB.width - 10
                    spacing: 2
                    Text { text: page.editing ? Actions.describe(page.editing.action).label : ""; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium }
                    Small { width: parent.width; text: page.editing ? page.editing.action : ""; elide: Text.ElideRight }
                }
                GwButton { id: changeB; anchors.verticalCenter: parent.verticalCenter; label: "CHANGE"; small: true; onClicked: page.picking = true }
            }

            // key
            Small { visible: !page.picking; text: "WHEN YOU PRESS"; font.letterSpacing: 1 }
            GwKeyCapture {
                id: capture
                visible: !page.picking
                combo: page.editing ? page.editing.combo : ""
                onChanged: c => page.patchEdit({ combo: c })
            }
            Row {
                visible: !page.picking && page.conflict !== null
                spacing: 8
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.red }
                Text {
                    text: page.conflict ? "Already used for \"" + Actions.describe(page.conflict.action).label + "\" (" + page.conflict.action + "). Saving replaces it." : ""
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
                }
            }

            Row {
                visible: !page.picking
                spacing: 8
                GwButton { label: "SAVE"; active: true; enabled: page.editing !== null && page.editing.combo !== "" && page.editing.action !== ""; onClicked: page.saveEdit() }
                GwButton { label: "CANCEL"; onClicked: page.editing = null }
                Item { width: 12; height: 1 }
                GwButton {
                    visible: page.editing && !page.editing.isNew
                    label: "REMOVE"; danger: true
                    onClicked: { Gluewc.removeBind(page.editing.origMode, page.editing.origCombo); page.editing = null; }
                }
                GwButton {
                    visible: {
                        if (!page.editing || page.editing.isNew) return false;
                        const d = Gluewc.defaultBind(page.editing.origMode, page.editing.origCombo);
                        return d !== null && (d.action !== page.editing.action || page.editing.combo !== page.editing.origCombo);
                    }
                    label: "RESET TO DEFAULT"
                    onClicked: {
                        const d = Gluewc.defaultBind(page.editing.origMode, page.editing.origCombo);
                        page.patchEdit({ action: d.action, combo: page.editing.origCombo, mode: page.editing.origMode });
                    }
                }
            }
        }
    }
    Item { width: 1; height: page.editing !== null ? 14 : 0 }

    // ---- simple list ----
    Repeater {
        model: page.view === "simple" ? page.shown : []
        delegate: Item {
            id: srow
            required property var modelData
            required property int index
            readonly property var desc: Actions.describe(modelData.action)
            readonly property bool groupStart: index === 0 || Actions.describe(page.shown[index - 1].action).group !== desc.group
            readonly property string defAction: page.defaultAction(modelData) ?? ""
            readonly property bool changed: defAction !== "" && defAction !== modelData.action
            width: parent.width
            height: (groupStart ? 30 : 0) + 54

            Text {
                visible: srow.groupStart
                anchors { left: parent.left; top: parent.top; topMargin: 10 }
                text: srow.desc.group.toUpperCase()
                color: Theme.red; font.family: Theme.uiFont; font.pixelSize: 10; font.letterSpacing: 1.2
            }
            Item {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 54
                Rectangle { anchors.fill: parent; radius: 8; color: rma.containsMouse ? "#151515" : "transparent" }
                Chips {
                    id: chips
                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                    combo: srow.modelData.combo
                }
                Column {
                    anchors { left: parent.left; leftMargin: 216; right: tags.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 2
                    Text { width: parent.width; text: srow.desc.label; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; elide: Text.ElideRight }
                    Small { width: parent.width; text: srow.modelData.action; elide: Text.ElideRight }
                }
                Row {
                    id: tags
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    spacing: 8
                    Small { anchors.verticalCenter: parent.verticalCenter; visible: page.isDup(srow.modelData); text: "DUPLICATE"; color: Theme.red }
                    Small { anchors.verticalCenter: parent.verticalCenter; visible: srow.modelData.mode === "normal"; text: "NORMAL"; color: Theme.red }
                    GwButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: srow.changed
                        label: "RESET"; small: true
                        onClicked: Gluewc.setBind(srow.modelData.mode, srow.modelData.combo, srow.defAction)
                    }
                    GwButton { anchors.verticalCenter: parent.verticalCenter; label: "EDIT"; small: true; onClicked: page.startEdit(srow.modelData) }
                }
                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#1a1a1a" }
            }
        }
    }

    // ---- advanced list ----
    Repeater {
        model: page.view === "advanced" ? page.shown : []
        delegate: Item {
            id: brow
            required property var modelData
            width: parent.width; height: 46
            GwField {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 190
                text: brow.modelData.combo
                onCommitted: v => {
                    const c = v.trim();
                    if (c === "" || c === brow.modelData.combo) return;
                    Gluewc.removeBind(brow.modelData.mode, brow.modelData.combo);
                    Gluewc.setBind(brow.modelData.mode, c, brow.modelData.action);
                }
            }
            Small {
                id: modeTag
                anchors { left: parent.left; leftMargin: 198; verticalCenter: parent.verticalCenter }
                width: 52
                text: brow.modelData.mode === "normal" ? "NORMAL" : "INSERT"
                color: brow.modelData.mode === "normal" ? Theme.red : "#9a9a9a"
                font.pixelSize: 10; font.letterSpacing: 0.8
            }
            GwField {
                anchors { left: parent.left; leftMargin: 256; right: drop.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: brow.modelData.action
                onCommitted: v => { if (v.trim() !== "") Gluewc.setBind(brow.modelData.mode, brow.modelData.combo, v.trim()); }
            }
            GwButton {
                id: drop
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                label: "X"; small: true; danger: true; implicitWidth: 26
                onClicked: Gluewc.removeBind(brow.modelData.mode, brow.modelData.combo)
            }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#1a1a1a" }
        }
    }
    Small {
        visible: page.view === "advanced"
        topPadding: 10
        width: parent.width; wrapMode: Text.WordWrap
        text: "Combos are mod / shift / ctrl / alt joined with +, then an XKB key name. Actions are wm:name, wm:name:arg or spawn:command. Use + NEW BIND above to add one."
    }
}

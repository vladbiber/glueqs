import QtQuick
import "GwActions.js" as Actions

// A key combination, either pressed into the box or built from the modifier
// buttons and a key name. Produces gluewc syntax: mod+shift+q, Print,
// XF86AudioRaiseVolume.
Item {
    id: root
    property string combo: ""
    signal changed(string combo)
    readonly property bool capturing: sink.activeFocus
    property string held: ""

    // manual builder state, kept in step with combo
    property bool mSuper: false
    property bool mShift: false
    property bool mCtrl: false
    property bool mAlt: false
    property string mKey: ""

    width: parent.width
    implicitHeight: col.implicitHeight

    onComboChanged: {
        const parts = combo.split("+").filter(p => p !== "");
        const key = parts.length ? parts[parts.length - 1] : "";
        const mods = parts.slice(0, -1).map(p => p.toLowerCase());
        mSuper = mods.some(m => m === "mod" || m === "super" || m === "logo");
        mShift = mods.includes("shift");
        mCtrl = mods.includes("ctrl") || mods.includes("control");
        mAlt = mods.includes("alt");
        mKey = key;
    }
    function focusCapture() { sink.forceActiveFocus() }
    function fromManual() {
        if (mKey.trim() === "") return;
        const parts = [];
        if (mSuper) parts.push("mod");
        if (mShift) parts.push("shift");
        if (mCtrl) parts.push("ctrl");
        if (mAlt) parts.push("alt");
        parts.push(mKey.trim());
        const c = parts.join("+");
        if (c !== combo) { combo = c; changed(c); }
    }

    readonly property var special: ({
        [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "KP_Enter", [Qt.Key_Escape]: "Escape",
        [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab", [Qt.Key_Backspace]: "BackSpace",
        [Qt.Key_Space]: "space", [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert",
        [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up",
        [Qt.Key_PageDown]: "Page_Down", [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right",
        [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down", [Qt.Key_Print]: "Print",
        [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period", [Qt.Key_Minus]: "minus",
        [Qt.Key_Equal]: "equal", [Qt.Key_Plus]: "plus", [Qt.Key_Slash]: "slash",
        [Qt.Key_Backslash]: "backslash", [Qt.Key_Semicolon]: "semicolon",
        [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_BracketLeft]: "bracketleft",
        [Qt.Key_BracketRight]: "bracketright", [Qt.Key_QuoteLeft]: "grave",
        [Qt.Key_Less]: "less", [Qt.Key_Greater]: "greater",
        [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume", [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
        [Qt.Key_VolumeMute]: "XF86AudioMute", [Qt.Key_MicMute]: "XF86AudioMicMute",
        [Qt.Key_MediaPlay]: "XF86AudioPlay", [Qt.Key_MediaPause]: "XF86AudioPause",
        [Qt.Key_MediaTogglePlayPause]: "XF86AudioPlay", [Qt.Key_MediaStop]: "XF86AudioStop",
        [Qt.Key_MediaNext]: "XF86AudioNext", [Qt.Key_MediaPrevious]: "XF86AudioPrev",
        [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp", [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown",
        [Qt.Key_PowerOff]: "XF86PowerOff", [Qt.Key_Sleep]: "XF86Sleep", [Qt.Key_Calculator]: "XF86Calculator",
        [Qt.Key_Search]: "XF86Search"
    })
    // shift on a US row gives the symbol; the bind wants the digit under it
    readonly property var shifted: ({ "!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6", "&": "7", "*": "8", "(": "9", ")": "0" })

    function keyName(e) {
        if (e.key >= Qt.Key_F1 && e.key <= Qt.Key_F35) return "F" + (e.key - Qt.Key_F1 + 1);
        if (special[e.key] !== undefined) return special[e.key];
        if (e.key >= Qt.Key_A && e.key <= Qt.Key_Z) return String.fromCharCode(e.key).toLowerCase();
        if (e.key >= Qt.Key_0 && e.key <= Qt.Key_9) return String.fromCharCode(e.key);
        if (e.text && e.text.length === 1 && e.text > " ") return shifted[e.text] ?? e.text;
        return "";
    }
    function modsOf(m) {
        const out = [];
        if (m & Qt.MetaModifier) out.push("mod");
        if (m & Qt.ShiftModifier) out.push("shift");
        if (m & Qt.ControlModifier) out.push("ctrl");
        if (m & Qt.AltModifier) out.push("alt");
        return out;
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Rectangle {
            width: parent.width; height: 46
            radius: 8
            color: root.capturing ? Qt.alpha(Theme.red, 0.1) : Theme.surface
            border.color: root.capturing ? Theme.red : kma.containsMouse ? Theme.strong : Theme.blockBorder
            border.width: root.capturing ? 2 : 1

            Item {
                id: sink
                anchors.fill: parent
                Keys.onPressed: e => {
                    e.accepted = true;
                    const mods = root.modsOf(e.modifiers);
                    if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].includes(e.key)) {
                        root.held = mods.join("+");
                        return;
                    }
                    if (e.key === Qt.Key_Escape && mods.length === 0) { root.held = ""; sink.focus = false; return; }
                    const name = root.keyName(e);
                    if (name === "") return;
                    const c = mods.concat([name]).join("+");
                    root.held = "";
                    sink.focus = false;
                    if (c !== root.combo) { root.combo = c; root.changed(c); }
                }
                Keys.onReleased: e => { root.held = root.modsOf(e.modifiers).join("+"); e.accepted = true; }
                onActiveFocusChanged: if (!activeFocus) root.held = ""
            }
            MouseArea {
                id: kma
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sink.forceActiveFocus()
            }
            Row {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 6
                Repeater {
                    model: root.capturing && root.held !== "" ? Actions.chips(root.held + "+x").slice(0, -1)
                         : root.capturing || root.combo === "" ? [] : Actions.chips(root.combo)
                    delegate: Rectangle {
                        required property string modelData
                        width: chipText.implicitWidth + 18; height: 26; radius: 6
                        color: Theme.panelSolid; border.color: Theme.strong
                        Text { id: chipText; anchors.centerIn: parent; text: parent.modelData; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.capturing || root.combo === ""
                    text: root.capturing ? (root.held !== "" ? "+ ..." : "Press the keys now, Esc cancels") : "Click, then press the keys"
                    color: root.capturing ? Theme.fg : Theme.muted
                    font.family: Theme.uiFont; font.pixelSize: 12
                }
            }
            Text {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                visible: !root.capturing && root.combo !== ""
                text: root.combo
                color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
            }
        }

        Row {
            spacing: 6
            GwButton { label: "SUPER"; small: true; active: root.mSuper; onClicked: { root.mSuper = !root.mSuper; root.fromManual(); } }
            GwButton { label: "SHIFT"; small: true; active: root.mShift; onClicked: { root.mShift = !root.mShift; root.fromManual(); } }
            GwButton { label: "CTRL"; small: true; active: root.mCtrl; onClicked: { root.mCtrl = !root.mCtrl; root.fromManual(); } }
            GwButton { label: "ALT"; small: true; active: root.mAlt; onClicked: { root.mAlt = !root.mAlt; root.fromManual(); } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "+"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 13 }
            GwField {
                width: 150; height: 26
                text: root.mKey
                placeholder: "q, Return, F5, Print"
                onCommitted: v => { root.mKey = v.trim(); root.fromManual(); }
            }
        }
        Text {
            width: parent.width
            text: "A combo gluewc already uses never reaches this box, the compositor acts on it first; build those with the buttons. Key names are XKB names: Return, space, Page_Up, XF86AudioRaiseVolume."
            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11; wrapMode: Text.WordWrap
        }
    }
}

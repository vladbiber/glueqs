import QtQuick

// Macro editor. The compositor owns execution; this page only writes compact
// macro lines to config.conf, so closing glueqs never stops a running macro.
Column {
    id: root
    width: parent.width
    spacing: 0

    property string originalName: ""
    property string dName: ""
    property string dTrigger: ""
    property string dType: "click"
    property string dMode: "hold"
    property string dButton: "left"
    property int dCps: 10
    property int dInterval: 80
    property int dPress: 10
    property string dSequence: "q,p,o,space"
    property string error: ""
    property bool recording: false
    property var recorded: []
    property double recordLast: 0
    readonly property var stopBinding: Gluewc.binds.find(b => b.mode === "insert" && b.action === "macro:stop_all") ?? null

    function edit(m) {
        originalName = m.name;
        dName = m.name;
        dTrigger = m.trigger;
        dType = m.type;
        dMode = m.mode;
        dButton = m.button;
        dCps = m.cps;
        dInterval = m.interval;
        dPress = m.press;
        dSequence = m.sequence;
        error = "";
        recording = false;
    }
    function create(kind) {
        originalName = "";
        dName = kind === "click" ? "rapid_click" : "new_macro";
        dTrigger = "";
        dType = kind;
        dMode = "hold";
        dButton = "left";
        dCps = 10;
        dInterval = 80;
        dPress = 10;
        dSequence = "q,p,o,space";
        error = "";
        recording = false;
    }
    function save() {
        const name = Gluewc.safeMacroName(dName);
        if (dTrigger.trim() === "") { error = "Choose a trigger first."; return; }
        if (dType === "sequence" && dSequence.trim() === "") { error = "The sequence is empty."; return; }
        const duplicate = Gluewc.macros.find(m => m.name === name && m.name !== originalName);
        if (duplicate) { error = "Another macro already uses that name."; return; }
        const triggerDuplicate = Gluewc.macros.find(m => m.trigger.toLowerCase() === dTrigger.toLowerCase()
                                                   && m.name !== originalName);
        if (triggerDuplicate) { error = "That trigger is already used by " + triggerDuplicate.name + "."; return; }
        Gluewc.setMacro(originalName, {
            name: name, trigger: dTrigger, type: dType, mode: dMode,
            button: dButton, cps: dCps, interval: dInterval,
            press: dPress, sequence: dSequence
        });
        originalName = name;
        dName = name;
        error = "";
    }
    function startRecording() {
        recorded = [];
        recordLast = 0;
        recording = true;
        dType = "sequence";
        dInterval = 0;
        recordSink.forceActiveFocus();
    }
    function stopRecording() {
        recording = false;
        if (recorded.length > 0) dSequence = recorded.join(",");
        recordSink.focus = false;
    }
    function appendRecorded(action) {
        const now = Date.now();
        const out = recorded.slice();
        if (recordLast > 0) {
            const gap = Math.max(1, Math.min(5000, Math.round(now - recordLast - dPress)));
            if (gap > 20) out.push("wait:" + gap);
        }
        out.push(action);
        recorded = out;
        recordLast = now;
    }
    function recordKey(e) {
        e.accepted = true;
        if (e.isAutoRepeat) return;
        const mods = triggerCapture.modsOf(e.modifiers);
        if (e.key === Qt.Key_Escape && mods.length === 0) { stopRecording(); return; }
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta,
             Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].includes(e.key)) return;
        const name = triggerCapture.keyName(e);
        if (name !== "") appendRecorded(mods.concat([name]).join("+"));
    }
    function recordClick(button) {
        const name = button === Qt.RightButton ? "right" : button === Qt.MiddleButton ? "middle" : "left";
        appendRecorded("click:" + name);
    }

    GwTitle {
        first: true
        text: "MACROS"
        sub: "Macros run inside gluewc with no background process. Nothing is polled and no timer runs while every macro is stopped."
    }

    Row {
        spacing: 8
        GwButton { label: "+ AUTOCLICKER"; active: true; onClicked: root.create("click") }
        GwButton { label: "+ SEQUENCE"; onClicked: root.create("sequence") }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Gluewc.macros.length + (Gluewc.macros.length === 1 ? " macro" : " macros")
            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
        }
    }
    Item { width: 1; height: 12 }

    Rectangle {
        width: parent.width
        implicitHeight: macroList.implicitHeight + 2
        radius: 10; color: Theme.card; border.color: Theme.blockBorder
        Column {
            id: macroList
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            Text {
                visible: Gluewc.macros.length === 0
                width: parent.width; height: visible ? 54 : 0
                leftPadding: 14; verticalAlignment: Text.AlignVCenter
                text: "No macros yet. Start with an autoclicker or a sequence."
                color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 12
            }
            Repeater {
                model: Gluewc.macros
                delegate: Item {
                    id: macroRow
                    required property var modelData
                    required property int index
                    width: parent.width; height: 58
                    Rectangle { anchors.fill: parent; color: rowMouse.containsMouse ? Theme.hover : "transparent"; radius: 9 }
                    Column {
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        Text { text: macroRow.modelData.name.replace(/_/g, " "); color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text {
                            text: macroRow.modelData.trigger + "   ·   " + macroRow.modelData.mode
                                  + "   ·   " + (macroRow.modelData.type === "click"
                                      ? macroRow.modelData.cps + " CPS, " + macroRow.modelData.button
                                      : macroRow.modelData.sequence.split(",").length + " steps")
                            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
                        }
                    }
                    Row {
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        GwButton { label: "EDIT"; small: true; onClicked: root.edit(macroRow.modelData) }
                        GwButton {
                            label: "DELETE"; small: true; danger: true
                            onClicked: {
                                Gluewc.removeMacro(macroRow.modelData.name);
                                if (root.originalName === macroRow.modelData.name) root.originalName = "";
                            }
                        }
                    }
                    MouseArea {
                        id: rowMouse
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: parent.right; rightMargin: 150 }
                        hoverEnabled: true
                        onClicked: root.edit(macroRow.modelData)
                    }
                    Rectangle {
                        visible: macroRow.index < Gluewc.macros.length - 1
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
                        height: 1; color: Theme.line
                    }
                }
            }
        }
    }

    GwTitle {
        text: "SAFETY"
        sub: "This shortcut immediately releases every synthetic key and mouse button, then stops all running macros."
    }
    Rectangle {
        width: parent.width; implicitHeight: stopCol.implicitHeight + 28
        radius: 10; color: Theme.card; border.color: Theme.blockBorder
        Column {
            id: stopCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 8
            Text { text: "Stop all macros"; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13 }
            GwKeyCapture {
                width: parent.width
                combo: root.stopBinding ? root.stopBinding.combo : ""
                onChanged: c => {
                    if (root.stopBinding && root.stopBinding.combo !== c)
                        Gluewc.removeBind("insert", root.stopBinding.combo);
                    Gluewc.setBind("insert", c, "macro:stop_all");
                }
            }
        }
    }

    GwTitle {
        visible: root.dName !== ""
        text: root.originalName === "" ? "NEW MACRO" : "EDIT " + root.dName.toUpperCase()
        sub: "Simple controls stay up front; recording and raw sequence editing are below. Changes apply as soon as you save."
    }

    GwCard {
        visible: root.dName !== ""
        GwRow { label: "Name"; hint: "Letters, numbers, dash and underscore"
            GwField { width: 190; text: root.dName; onCommitted: v => root.dName = v } }
        GwRow { label: "Type"; hint: root.dType === "click" ? "Repeat a mouse button" : "Play keys, waits and clicks"
            GwChoice { bound: true; value: root.dType; options: [{v:"click",label:"CLICK"},{v:"sequence",label:"SEQUENCE"}]; onPicked: v => root.dType = v } }
        GwRow { label: "Activation"; hint: root.dMode === "hold" ? "Runs only while the trigger is held" : root.dMode === "toggle" ? "Press once to start, again to stop" : "Runs one pass"
            GwChoice { bound: true; value: root.dMode; options: [{v:"hold",label:"HOLD"},{v:"toggle",label:"TOGGLE"},{v:"once",label:"ONCE"}]; onPicked: v => root.dMode = v } }
    }

    GwTitle { visible: root.dName !== ""; text: "TRIGGER" }
    Rectangle {
        visible: root.dName !== ""
        width: parent.width; implicitHeight: triggerCol.implicitHeight + 28
        radius: 10; color: Theme.card; border.color: Theme.blockBorder
        Column {
            id: triggerCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 8
            Text { text: "Click the box, then press the shortcut"; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13 }
            GwKeyCapture { id: triggerCapture; width: parent.width; combo: root.dTrigger; onChanged: c => root.dTrigger = c }
        }
    }

    GwTitle { visible: root.dName !== "" && root.dType === "click"; text: "AUTOCLICKER" }
    GwCard {
        visible: root.dName !== "" && root.dType === "click"
        GwRow { label: "Mouse button"
            GwChoice { bound: true; value: root.dButton; options: [{v:"left",label:"LEFT"},{v:"right",label:"RIGHT"},{v:"middle",label:"MIDDLE"}]; onPicked: v => root.dButton = v } }
        GwRow { label: "Clicks per second"; hint: Math.round(1000 / Math.max(1, root.dCps)) + " ms between clicks"
            GwNumber { bound: true; value: root.dCps; min: 1; max: 200; unit: "CPS"; onChanged: v => root.dCps = Math.round(v) } }
        GwRow { label: "Press duration"; hint: "How long the button stays down"
            GwNumber { bound: true; value: root.dPress; min: 1; max: 500; unit: "ms"; onChanged: v => root.dPress = Math.round(v) } }
    }

    GwTitle { visible: root.dName !== "" && root.dType === "sequence"; text: "SEQUENCE"; sub: "Record keys, or edit the compact list. wait:120 adds a pause; click:left, click:right and click:middle add mouse actions." }
    Rectangle {
        visible: root.dName !== "" && root.dType === "sequence"
        width: parent.width; implicitHeight: sequenceCol.implicitHeight + 28
        radius: 10; color: Theme.card; border.color: Theme.blockBorder
        Column {
            id: sequenceCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10
            Row {
                spacing: 8
                GwButton { label: root.recording ? "STOP RECORDING" : "RECORD KEYS"; active: root.recording; onClicked: root.recording ? root.stopRecording() : root.startRecording() }
                GwButton { label: "+ LEFT CLICK"; small: true; onClicked: root.dSequence += (root.dSequence === "" ? "" : ",") + "click:left" }
                GwButton { label: "+ WAIT"; small: true; onClicked: root.dSequence += (root.dSequence === "" ? "" : ",") + "wait:100" }
            }
            Rectangle {
                id: recordSink
                width: parent.width; height: root.recording ? 54 : 0
                visible: height > 0; radius: 8
                color: Qt.alpha(Theme.red, 0.1); border.color: Theme.red; border.width: 2
                focus: false
                Keys.onPressed: e => root.recordKey(e)
                Text {
                    anchors.centerIn: parent
                    text: root.recorded.length === 0 ? "Type or click here — Esc stops" : root.recorded.join("  ")
                    width: parent.width - 24; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onPressed: mouse => { root.recordClick(mouse.button); recordSink.forceActiveFocus(); }
                }
            }
            Text { text: "Actions"; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; font.weight: Font.Medium }
            GwField { width: parent.width; text: root.dSequence; placeholder: "q,wait:80,p,wait:80,o,space"; onCommitted: v => root.dSequence = v }
            Row {
                spacing: 16
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Gap after each action"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
                GwNumber { bound: true; value: root.dInterval; min: 0; max: 5000; step: 10; unit: "ms"; onChanged: v => root.dInterval = Math.round(v) }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Key/button down"; color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11 }
                GwNumber { bound: true; value: root.dPress; min: 1; max: 500; unit: "ms"; onChanged: v => root.dPress = Math.round(v) }
            }
        }
    }

    Text {
        visible: root.error !== ""
        width: parent.width; topPadding: 12
        text: root.error; color: Theme.red; font.family: Theme.uiFont; font.pixelSize: 12
    }
    Row {
        visible: root.dName !== ""
        spacing: 8
        GwButton { label: "SAVE MACRO"; active: true; onClicked: root.save() }
        GwButton { label: "CANCEL"; onClicked: { root.originalName = ""; root.dName = ""; root.recording = false; root.error = ""; } }
    }
    Item { width: 1; height: root.dName !== "" ? 24 : 0 }
}

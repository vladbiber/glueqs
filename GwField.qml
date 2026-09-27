import QtQuick

// A plain text field for the gluewc pages. Shows the committed value while
// idle; commits on Enter or focus loss, Escape drops the edit.
Rectangle {
    id: root
    property string text: ""
    property string placeholder: ""
    property int align: Text.AlignLeft
    property bool mono: true
    readonly property bool editing: input.activeFocus
    readonly property alias draft: input.text
    signal committed(string value)

    width: 120; height: 30
    radius: 7
    color: input.activeFocus ? "#1a1a1a" : "#141414"
    border.color: input.activeFocus ? Theme.red : fma.containsMouse ? "#3a3a3a" : Theme.blockBorder
    border.width: 1

    // long values show their start, not their tail
    onTextChanged: if (!input.activeFocus) { input.text = text; input.cursorPosition = 0; }
    Component.onCompleted: input.cursorPosition = 0

    function commit() {
        if (input.text !== root.text) root.committed(input.text);
    }
    function clear() { input.text = ""; root.text = ""; }

    MouseArea {
        id: fma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: { input.forceActiveFocus(); input.selectAll(); }
    }
    Text {
        anchors { fill: parent; leftMargin: 9; rightMargin: 9 }
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: "#6f6f6f"
        font.family: Theme.uiFont
        font.pixelSize: 13
        horizontalAlignment: root.align
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 9; rightMargin: 9 }
        text: root.text
        color: Theme.fg
        font.family: root.mono ? Theme.uiFont : Theme.uiFont
        font.pixelSize: 13
        horizontalAlignment: root.align
        verticalAlignment: Text.AlignVCenter
        selectByMouse: true
        selectionColor: Theme.red
        clip: true
        onEditingFinished: root.commit()
        Keys.onEscapePressed: { text = root.text; focus = false; }
        Keys.onReturnPressed: { root.commit(); focus = false; }
        Keys.onEnterPressed: { root.commit(); focus = false; }
    }
}

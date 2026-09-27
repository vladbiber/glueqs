import QtQuick

// Section heading: dot-matrix title, plain one-line explanation, hairline.
Column {
    property string text: ""
    property string sub: ""
    property bool first: false
    width: parent.width
    spacing: 6
    topPadding: first ? 4 : 30
    bottomPadding: 12
    DotText { text: parent.text; px: 1.3; gap: 1; color: Theme.red }
    Text {
        visible: parent.sub !== ""
        width: parent.width
        text: parent.sub
        color: "#9a9a9a"
        font.family: Theme.uiFont
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}

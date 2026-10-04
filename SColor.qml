import QtQuick

// A colour swatch and its hex code; Enter or leaving the field applies it.
Row {
    id: sc
    property string value: "#000000"
    signal picked(string v)
    spacing: 8
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 26; height: 26; radius: 13
        color: sc.value
        border.color: Theme.strong
    }
    GwField {
        anchors.verticalCenter: parent.verticalCenter
        width: 96
        text: sc.value
        onCommitted: v => { let c = v.trim(); if (!c.startsWith("#")) c = "#" + c; if (/^#[0-9a-fA-F]{6}$/.test(c)) sc.picked(c.toLowerCase()); }
    }
}

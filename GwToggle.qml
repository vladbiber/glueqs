import QtQuick

// On/off for a boolean config key, with the state written out as a word.
Row {
    property string key: ""
    // bound: the caller owns the value and hears about clicks
    property bool bound: false
    property bool value: false
    signal toggled()
    readonly property bool on: bound ? value : Gluewc.getBool(key)
    spacing: 10
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: parent.on ? "ON" : "OFF"
        color: parent.on ? Theme.fg : "#9a9a9a"
        font.family: Theme.uiFont
        font.pixelSize: 12
        font.letterSpacing: 0.6
    }
    DotToggle {
        anchors.verticalCenter: parent.verticalCenter
        on: parent.on
        onToggled: parent.bound ? parent.toggled() : Gluewc.set(parent.key, parent.on ? "false" : "true")
    }
}

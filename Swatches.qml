import QtQuick

// Round colour chips for one string key of the shell settings.
Row {
    id: sw
    property string skey: ""
    property var colors: []
    spacing: 10
    Repeater {
        model: sw.colors
        delegate: Rectangle {
            required property string modelData
            readonly property bool on: Settings.s[sw.skey] === modelData
            width: 28; height: 28; radius: 14
            color: "transparent"
            border.color: on ? Theme.fg : swm.containsMouse ? Theme.strong : Theme.border
            border.width: on ? 2 : 1
            scale: swm.containsMouse ? 1.1 : 1
            Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutBack } }
            Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: parent.modelData; border.color: Theme.border }
            MouseArea { id: swm; anchors.fill: parent; hoverEnabled: true; onClicked: Settings.s[sw.skey] = parent.modelData }
        }
    }
}

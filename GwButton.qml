import QtQuick

// Bordered text button, accent when active, red when dangerous.
Rectangle {
    id: root
    property string label: ""
    property bool active: false
    property bool danger: false
    property bool small: false
    signal clicked()

    implicitWidth: lbl.implicitWidth + (small ? 16 : 22)
    implicitHeight: small ? 24 : 30
    radius: 7
    color: bma.containsMouse ? "#1e1e1e" : active ? "#181818" : "transparent"
    border.color: active ? Theme.red : danger && bma.containsMouse ? Theme.red : Theme.blockBorder
    border.width: 1
    opacity: enabled ? 1 : 0.4

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.label
        color: root.danger && bma.containsMouse ? Theme.red : Theme.fg
        font.family: Theme.uiFont
        font.pixelSize: root.small ? 11 : 12
        font.weight: Font.Medium
        font.letterSpacing: 0.6
    }
    MouseArea {
        id: bma
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}

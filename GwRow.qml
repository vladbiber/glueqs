import QtQuick

// One setting: name and explanation on the left, the control on the right,
// the shipped default underneath and a RESET that appears once it differs.
Item {
    id: row
    property string label: ""
    property string hint: ""
    property string key: ""
    property string unit: ""
    default property alias control: slot.data
    readonly property bool hasDefault: key !== "" && Gluewc.hasDefault(key)
    readonly property bool changed: hasDefault && !Gluewc.isDefault(key)

    width: parent.width
    implicitHeight: Math.max(48, left.implicitHeight + 18, slot.implicitHeight + 18)

    Column {
        id: left
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: parent.width - slot.width - 24
        spacing: 3
        Text {
            width: parent.width
            text: row.label
            color: Theme.fg
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            visible: text !== ""
            width: parent.width
            text: {
                let s = row.hint;
                if (row.hasDefault)
                    s += (s !== "" ? "   ·   " : "") + "default " + Gluewc.defaults[row.key]
                         + (row.unit !== "" ? " " + row.unit : "");
                return s;
            }
            color: "#9a9a9a"
            font.family: Theme.uiFont
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }

    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 10
        GwButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.changed
            label: "RESET"; small: true
            onClicked: Gluewc.reset(row.key)
        }
        Item {
            id: slot
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            width: implicitWidth; height: implicitHeight
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: "#1a1a1a"
    }
}

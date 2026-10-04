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

    // inside a GwCard the row keeps a margin and the last one has no line
    readonly property bool last: parent && parent.children && parent.children[parent.children.length - 1] === row
    readonly property int pad: 14

    width: parent.width
    implicitHeight: Math.max(54, left.implicitHeight + 22, slot.implicitHeight + 22)

    Column {
        id: left
        anchors { left: parent.left; leftMargin: row.pad; verticalCenter: parent.verticalCenter }
        width: parent.width - slot.width - 24 - row.pad * 2
        spacing: 3
        Text {
            width: parent.width
            text: row.label
            color: Theme.fg
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Theme.fontWeight
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
            color: Theme.muted
            font.family: Theme.uiFont
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: row.pad; verticalCenter: parent.verticalCenter }
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
        visible: !row.last
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: row.pad; rightMargin: row.pad }
        height: 1
        color: Theme.line
    }
}

import QtQuick

// Hex colour with a swatch. gluewc reads rrggbb or rrggbbaa without a hash.
Row {
    id: root
    property string key: ""
    readonly property string current: Gluewc.get(key).replace("#", "")
    readonly property bool valid: /^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(current)
    spacing: 8
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 15
        color: Theme.panelSolid
        border.color: Theme.blockBorder
        Rectangle {
            anchors.centerIn: parent
            width: 20; height: 20; radius: 10
            color: root.valid ? "#" + root.current : "transparent"
            border.color: root.valid ? "transparent" : Theme.red
        }
    }
    GwField {
        anchors.verticalCenter: parent.verticalCenter
        width: 104
        text: root.current
        placeholder: "rrggbb"
        onCommitted: v => {
            const s = v.trim().replace("#", "").toLowerCase();
            if (/^[0-9a-f]{6}([0-9a-f]{2})?$/.test(s)) Gluewc.set(root.key, s);
        }
    }
}

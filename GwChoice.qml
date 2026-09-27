import QtQuick

// Segmented choice: one button per option, the current one in the accent.
Row {
    id: root
    property string key: ""
    property var options: []      // [{ v: "bsp", label: "BSP" }]
    property bool bound: false
    property string value: ""
    signal picked(string v)
    readonly property string current: bound ? value : Gluewc.get(key)
    spacing: 4
    Repeater {
        model: root.options
        delegate: GwButton {
            required property var modelData
            label: modelData.label
            active: root.current === modelData.v
            onClicked: root.bound ? root.picked(modelData.v) : Gluewc.set(root.key, modelData.v)
        }
    }
}

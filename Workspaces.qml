import QtQuick

// Nothing-style tag strip: active tag number in accent, occupied white, empty hidden.
// Becomes a vertical stack when the bar is on a side edge.
Block {
    id: root
    property var dwlOutput: null

    readonly property var tags: root.dwlOutput?.tags ?? []
    // only the tags that actually render; telling the Grid about more columns
    // than that makes it reserve a trailing gap and the tile comes out lopsided
    readonly property int shownTags: {
        let n = 0;
        for (const t of tags)
            if (t.active || t.clientCount > 0) n++;
        return n;
    }

    Grid {
        columns: Theme.vertical ? 1 : Math.max(1, root.shownTags)
        spacing: 6
        Repeater {
            model: root.tags
            delegate: Item {
                required property var modelData
                visible: modelData.active || modelData.clientCount > 0
                width: 16; height: 24

                DotText {
                    anchors.centerIn: parent
                    text: String(modelData.index + 1)
                    px: modelData.active ? 1.8 : 1.6; gap: 1
                    color: modelData.active || modelData.urgent ? Theme.red : Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dwlOutput?.setTags(1 << modelData.index, 0)
                }
            }
        }
    }
}

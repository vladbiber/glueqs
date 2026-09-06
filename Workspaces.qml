import QtQuick

// Nothing-style tag strip: active tag number in accent, occupied white, empty hidden.
// Becomes a vertical stack when the bar is on a side edge.
Block {
    id: root
    property string outputName: ""

    readonly property var output: {
        WsState.outputs;  // re-evaluate whenever the state file changes
        return WsState.outputFor(root.outputName);
    }
    readonly property var counts: root.output?.counts ?? []
    readonly property int active: root.output?.ws ?? -1

    // only the tags that actually render; telling the Grid about more columns
    // than that makes it reserve a trailing gap and the tile comes out lopsided
    readonly property int shownTags: {
        let n = 0;
        for (let i = 0; i < counts.length; i++)
            if (i === active || counts[i] > 0) n++;
        return n;
    }

    Grid {
        columns: Theme.vertical ? 1 : Math.max(1, root.shownTags)
        spacing: 6
        Repeater {
            model: root.counts.length
            delegate: Item {
                required property int index
                readonly property bool isActive: index === root.active
                visible: isActive || (root.counts[index] ?? 0) > 0
                width: 16; height: 24

                DotText {
                    anchors.centerIn: parent
                    text: String(parent.index + 1)
                    px: parent.isActive ? 1.8 : 1.6; gap: 1
                    color: parent.isActive ? Theme.red : Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: WsState.view(root.outputName, parent.index + 1)
                }
            }
        }
    }
}

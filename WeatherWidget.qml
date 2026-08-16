import QtQuick

// Dot-art weather tile: condition icon + temperature. Framed; click opens the weather panel.
Block {
    id: root
    border.color: Popups.open === "weather" ? Theme.red : Theme.blockBorder

    Grid {
        columns: 1

        Row {
            visible: !Theme.vertical
            spacing: 10

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: Weather.icon
                px: Theme.pxIcon; gap: 1
                color: Theme.fg
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                DotText {
                    text: Weather.temp.toUpperCase()
                    px: Theme.pxMed; gap: 1
                }
                DotText {
                    text: {
                        const c = Weather.condition.toUpperCase();
                        return c.length > 14 ? c.slice(0, 13) + "." : c;
                    }
                    px: 0.85 * Theme.scale; gap: 0.85
                    color: Theme.mid
                }
            }
        }

        Column {
            visible: Theme.vertical
            spacing: 4
            DotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: Weather.icon
                px: 1.2; gap: 0.9
                color: Theme.fg
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.temp.toUpperCase().replace("C", "")
                px: 1; gap: 0.9
            }
        }
    }

    MouseArea {
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        onClicked: Popups.toggle("weather")
    }
}

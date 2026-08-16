import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// System tray icons. Left click activates, middle click is the secondary
// action, right click opens the app's own menu - the one carrying "Quit" -
// which TrayMenu draws.
Block {
    id: root

    // hand the menu the icon's place inside the bar window so it can open
    // right under the icon that was clicked
    function openMenu(trayItem, tile) {
        const w = QsWindow.window;
        if (!w)
            return;
        const p = tile.mapToItem(w.contentItem, tile.width / 2, tile.height / 2);
        Tray.show(trayItem, p.x, p.y);
    }

    Grid {
        id: tgrid
        // the real item count, not a large constant: Grid reserves a trailing
        // gap for the columns it was told about, which padded the tile
        columns: Theme.vertical ? 1 : Math.max(1, SystemTray.items.values.length)
        spacing: 8
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: titem
                required property var modelData
                width: 18; height: 18

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: 6
                    color: tma.containsMouse ? "#1c1c1c" : "transparent"
                }

                Image {
                    anchors.fill: parent
                    source: titem.modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                }

                MouseArea {
                    id: tma
                    // the icon is only 18px: reach into the tile's padding so
                    // the whole area around it is clickable, like the other tiles
                    anchors.fill: parent
                    anchors.margins: -9
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            titem.modelData.activate();
                        } else if (mouse.button === Qt.MiddleButton) {
                            titem.modelData.secondaryActivate();
                        } else {
                            root.openMenu(titem.modelData, titem);
                        }
                    }
                }
            }
        }
    }
}

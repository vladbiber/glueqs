import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQml
import "DotFont.js" as DotFont

// The menu behind a tray icon: "Quit", "Show window" and whatever else the app
// puts there. Quickshell's own QsMenuAnchor needs QApplication mode, which this
// shell does not run in, so the DBus menu is read through QsMenuOpener and drawn
// like the rest of the panels.
PanelWindow {
    id: root
    // Everything except the bar: a click outside the card dismisses the menu,
    // while the icon that opened it stays clickable and closes it again.
    anchors { top: true; bottom: true; left: true; right: true }
    margins {
        top: Theme.barPos === "top" ? Theme.barHeight : 0
        bottom: Theme.barPos === "bottom" ? Theme.barHeight : 0
        left: Theme.barPos === "left" ? Theme.barHeight : 0
        right: Theme.barPos === "right" ? Theme.barHeight : 0
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Tray.open

    readonly property real rowPx: 1.2 * Theme.scale
    readonly property int rowHeight: Math.round(32 * Theme.scale)

    // One opener per level of the path, not just the deepest one: a menu that
    // is let go closes on the app's side and takes its children with it, which
    // left submenus empty when only the current level was held open.
    Instantiator {
        id: openers
        model: Tray.stack
        delegate: QsMenuOpener {
            required property var modelData
            menu: modelData
        }
    }
    readonly property var entries: {
        const top = openers.count > 0 ? openers.objectAt(openers.count - 1) : null;
        return top?.children?.values ?? [];
    }

    // Menu labels are the app's own, so they can be anything: cap them at a
    // length the card can still show, and let the width follow the longest one.
    function label(entry) {
        const t = (entry.text ?? "").toUpperCase();
        return t.length > 24 ? t.slice(0, 21) + "..." : t;
    }

    readonly property int cardWidth: {
        let cells = 0;
        for (const e of entries)
            if (!e.isSeparator)
                cells = Math.max(cells, DotFont.textCells(label(e)));
        // dot cells are the widest of the two text modes, so sizing by them
        // leaves room for the plain font as well
        return Math.max(190, Math.min(340, Math.round(cells * (rowPx + 1)) + 76));
    }
    readonly property int cardHeight: rows.implicitHeight + 20

    // the anchor is where the icon sits along the bar; the other axis just
    // hugs the bar edge, which is where this window already starts
    readonly property int cardX: Theme.vertical
        ? (Theme.barPos === "left" ? 8 : width - cardWidth - 8)
        : Math.max(8, Math.min(Tray.anchorX - cardWidth / 2, width - cardWidth - 8))
    readonly property int cardY: Theme.vertical
        ? Math.max(8, Math.min(Tray.anchorY - cardHeight / 2, height - cardHeight - 8))
        : (Theme.barPos === "top" ? 8 : height - cardHeight - 8)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: Tray.close()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Tray.close()
    }

    Rectangle {
        id: card
        x: root.cardX
        y: root.cardY
        width: root.cardWidth
        height: root.cardHeight
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        Column {
            id: rows
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 2

            // one row back out of a submenu; the top level has none
            Rectangle {
                visible: Tray.stack.length > 1
                width: rows.width
                height: visible ? root.rowHeight : 0
                radius: 8
                color: backArea.containsMouse ? "#1c1c1c" : "transparent"

                DotIcon {
                    id: backIcon
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    name: "prev"; px: root.rowPx; gap: 1
                    color: Theme.red
                }
                DotText {
                    anchors { left: backIcon.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: "BACK"
                    px: root.rowPx; gap: 1
                    color: Theme.fg
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Tray.back()
                }
            }

            Repeater {
                model: root.entries
                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property bool separator: modelData.isSeparator

                    width: rows.width
                    height: separator ? 9 : root.rowHeight

                    Rectangle {
                        visible: row.separator
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        height: 1
                        color: Theme.blockBorder
                    }

                    Rectangle {
                        visible: !row.separator
                        anchors.fill: parent
                        radius: 8
                        color: area.containsMouse && row.modelData.enabled ? "#1c1c1c" : "transparent"

                        Image {
                            id: rowIcon
                            readonly property string src: row.modelData.icon ?? ""

                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            width: src === "" ? 0 : 16
                            height: 16
                            source: src
                            sourceSize.width: 16
                            sourceSize.height: 16
                        }
                        DotText {
                            anchors {
                                left: rowIcon.right
                                leftMargin: rowIcon.width === 0 ? 10 : 8
                                right: mark.left
                                rightMargin: 8
                                verticalCenter: parent.verticalCenter
                            }
                            text: root.label(row.modelData)
                            px: root.rowPx; gap: 1
                            color: row.modelData.enabled ? Theme.fg : Theme.offDot
                        }

                        // checkbox / radio state, and the arrow that says the
                        // entry opens a submenu instead of doing something
                        Item {
                            id: mark
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            width: 12
                            height: 12

                            Rectangle {
                                visible: row.modelData.buttonType !== QsMenuButtonType.None
                                anchors.centerIn: parent
                                width: 10; height: 10
                                radius: row.modelData.buttonType === QsMenuButtonType.RadioButton ? 5 : 3
                                color: row.modelData.checkState === Qt.Checked ? Theme.red : "transparent"
                                border.color: row.modelData.checkState === Qt.Checked ? Theme.red : Theme.offDot
                                border.width: 1
                            }
                            DotIcon {
                                visible: row.modelData.hasChildren
                                anchors.centerIn: parent
                                name: "next"; px: root.rowPx; gap: 1
                                color: Theme.fg
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: row.modelData.enabled
                            onClicked: {
                                if (row.modelData.hasChildren) {
                                    Tray.enter(row.modelData);
                                    return;
                                }
                                // trigger before closing: closing drops the
                                // menu the entry belongs to, and the entry
                                // goes with it before it can send anything
                                row.modelData.triggered();
                                Tray.close();
                            }
                        }
                    }
                }
            }
        }
    }
}

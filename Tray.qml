pragma Singleton
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// Which tray icon has its menu open, where its icon sits inside the bar, and
// how deep into the app's submenus we are. TrayMenu draws whatever is on top
// of the stack.
Singleton {
    id: root

    property var item: null    // the SystemTrayItem being shown
    property var stack: []     // [item.menu, submenu, ...]
    property real anchorX: 0   // centre of the icon inside the bar window
    property real anchorY: 0

    readonly property bool open: item !== null && stack.length > 0
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : null

    function show(trayItem, x, y) {
        if (!trayItem || !trayItem.hasMenu)
            return;
        if (item === trayItem) {
            close();
            return;
        }
        item = trayItem;
        stack = [trayItem.menu];
        anchorX = x;
        anchorY = y;
    }

    function close() {
        item = null;
        stack = [];
    }

    function enter(entry) { stack = stack.concat([entry]); }
    function back() { if (stack.length > 1) stack = stack.slice(0, -1); }

    // Quitting from the menu takes the item with it, so drop the menu before
    // it is left pointing at a dead DBus service.
    Connections {
        target: SystemTray.items
        function onObjectRemovedPre(gone, index) {
            if (gone === root.item)
                root.close();
        }
    }
}

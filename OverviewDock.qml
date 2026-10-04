import Quickshell
import Quickshell.Wayland
import QtQuick

// GNOME-style dash for the compositor overview: pinned apps, then whatever is
// running, then an apps button on the right that opens a grid you can pin from.
// Only ever visible while gluewc reports the overview is up.
PanelWindow {
    id: root
    // sit on the edge opposite the bar so the two never overlap
    readonly property bool atTop: Theme.barPos === "bottom"
    anchors.top: atTop
    anchors.bottom: !atTop
    margins.top: atTop ? Theme.barHeight + 18 : 0
    margins.bottom: atTop ? 0 : 26
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // only grab the keyboard while the search box is up, so the overview keeps
    // its own keys the rest of the time
    WlrLayershell.keyboardFocus: appsOpen ? WlrKeyboardFocus.OnDemand
                                          : WlrKeyboardFocus.None
    visible: Overview.active

    property bool appsOpen: false
    onVisibleChanged: if (!visible) appsOpen = false
    onAppsOpenChanged: {
        search.text = "";
        if (appsOpen) search.forceActiveFocus();
    }

    readonly property int slot: 58
    readonly property int gridCols: 6

    // the window is wider and taller than the dash so a hover label can stick
    // out of it whole; the mask keeps clicks outside the dash going through
    readonly property int dashWidth: Math.max(slot + 24, dash.implicitWidth + 24)
    readonly property int labelRoom: 40
    implicitWidth: appsOpen ? 640 : (root.screen?.width ?? 1920)
    implicitHeight: appsOpen ? 470 : 76 + labelRoom
    mask: Region { item: content }

    // ---- pinned apps ----
    readonly property var pinnedIds: Settings.s.dockPinned.split(",").filter(x => x !== "")
    readonly property var pinned: {
        // touch the model so this re-runs once the entries are loaded; byId()
        // is a plain call and would otherwise be resolved against an empty
        // database at startup and never looked at again
        DesktopEntries.applications.values.length;
        return pinnedIds.map(id => DesktopEntries.byId(id)).filter(e => e);
    }

    function isPinned(id) { return pinnedIds.indexOf(id) >= 0 }

    // ---- how often each app gets launched from here, so the grid can put the
    // ones actually in use at the top ----
    readonly property var usage: {
        const m = ({});
        for (const pair of Settings.s.dockUsage.split(",")) {
            const i = pair.lastIndexOf("=");
            if (i > 0) m[pair.slice(0, i)] = parseInt(pair.slice(i + 1)) || 0;
        }
        return m;
    }
    function useCount(id) { return usage[id] ?? 0 }
    function bumpUsage(id) {
        if (!id) return;
        const m = usage;
        m[id] = (m[id] ?? 0) + 1;
        const out = [];
        for (const k in m) out.push(k + "=" + m[k]);
        Settings.s.dockUsage = out.join(",");
    }
    function launch(entry) {
        if (!entry) return;
        bumpUsage(entry.id);
        entry.execute();
    }
    function togglePin(id) {
        if (!id) return;
        const l = pinnedIds.slice();
        const i = l.indexOf(id);
        if (i >= 0) l.splice(i, 1); else l.push(id);
        Settings.s.dockPinned = l.join(",");
    }

    // ---- running windows, one entry per app ----
    readonly property var running: {
        const seen = ({});
        const out = [];
        for (const t of ToplevelManager.toplevels.values) {
            const key = (t.appId ?? "").toLowerCase();
            if (key === "" || seen[key]) continue;
            seen[key] = true;
            out.push(t);
        }
        return out;
    }
    function entryFor(appId) {
        return DesktopEntries.heuristicLookup(appId) ?? null;
    }
    function toplevelFor(entry) {
        if (!entry) return null;
        for (const t of ToplevelManager.toplevels.values) {
            const e = root.entryFor(t.appId ?? "");
            if (e && e.id === entry.id) return t;
        }
        return null;
    }
    function runningPinned(entry) { return toplevelFor(entry) !== null }

    function iconFor(entry, appId) {
        if (entry && entry.icon)
            return Quickshell.iconPath(entry.icon, true);
        return Quickshell.iconPath(appId ?? "", true);
    }

    Rectangle {
        id: content
        width: root.appsOpen ? parent.width : root.dashWidth
        height: root.appsOpen ? parent.height : 76
        x: Math.round((parent.width - width) / 2)
        y: root.atTop ? 0 : parent.height - height
        radius: 18
        color: Theme.panel
        border.color: Theme.blockBorder
        border.width: 1

        // ---------- app grid ----------
        Item {
            anchors { fill: parent; margins: 16 }
            anchors.topMargin: root.atTop ? 92 : 16
            anchors.bottomMargin: root.atTop ? 16 : 92
            visible: root.appsOpen

            // search box: type to filter, Enter launches the first match
            Rectangle {
                id: searchBox
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 30
                radius: 8
                color: Theme.surface
                border.color: search.activeFocus ? Theme.red : Theme.blockBorder
                border.width: 1

                DotIcon {
                    id: searchIcon
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    name: "grid"
                    px: 0.9; gap: 0.9; color: Theme.dim
                }
                DotText {
                    anchors { left: searchIcon.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: search.text === "" ? "SEARCH APPLICATIONS"
                                             : search.text.toUpperCase()
                    px: 1; gap: 1
                    color: search.text === "" ? Theme.dim : Theme.fg
                }
                TextInput {
                    id: search
                    width: 1; height: 1
                    opacity: 0
                    focus: root.appsOpen
                    Keys.onEscapePressed: root.appsOpen = false
                    function launchFirst() {
                        const l = appGrid.model;
                        if (l && l.length > 0) {
                            root.launch(l[0]);
                            root.appsOpen = false;
                        }
                    }
                    Keys.onReturnPressed: launchFirst()
                    Keys.onEnterPressed: launchFirst()
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: search.forceActiveFocus()
                }
            }

            DotText {
                id: gridTitle
                anchors { top: searchBox.bottom; topMargin: 8; left: parent.left }
                text: appGrid.count + " APPS"
                px: 0.8; gap: 0.8; color: Theme.dim
            }
            DotText {
                anchors { top: searchBox.bottom; topMargin: 8; right: parent.right }
                text: "RIGHT CLICK TO PIN   SCROLL FOR MORE"
                px: 0.75; gap: 0.75; color: Theme.hint
            }

            GridView {
                id: appGrid
                anchors { top: gridTitle.bottom; topMargin: 8; left: parent.left
                          right: parent.right; bottom: parent.bottom }
                anchors.rightMargin: 6
                clip: true
                cellWidth: Math.floor(width / root.gridCols)
                cellHeight: 74
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 6000
                maximumFlickVelocity: 3000

                // most launched first, the rest alphabetically after them
                model: {
                    const q = search.text.toLowerCase();
                    const l = DesktopEntries.applications.values.filter(a =>
                        !a.noDisplay && (q === "" || a.name.toLowerCase().includes(q)));
                    l.sort((a, b) => {
                        const ua = root.useCount(a.id), ub = root.useCount(b.id);
                        if (ua !== ub) return ub - ua;
                        return a.name.localeCompare(b.name);
                    });
                    return l;
                }


                delegate: Item {
                    id: gcell
                    required property var modelData
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    Rectangle {
                        anchors { fill: parent; margins: 3 }
                        radius: 10
                        color: gma.containsMouse ? Theme.hover : "transparent"
                        border.color: root.isPinned(gcell.modelData.id)
                                    ? Theme.red : "transparent"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: root.iconFor(gcell.modelData, gcell.modelData.id)
                                sourceSize.width: 34; sourceSize.height: 34
                                width: 34; height: 34
                                asynchronous: true
                            }
                            DotText {
                                id: gname
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: gcell.modelData.name.toUpperCase()
                                maxWidth: gcell.width - 8
                                px: 0.7; gap: 0.7
                                color: gma.containsMouse ? Theme.fg : Theme.mid
                            }
                        }
                        MouseArea {
                            id: gma
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse) gridTip.cell = gname;
                                else if (gridTip.cell === gname) gridTip.cell = null;
                            }
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.togglePin(gcell.modelData.id);
                                else {
                                    root.launch(gcell.modelData);
                                    root.appsOpen = false;
                                }
                            }
                        }
                    }
                }
            }

            // scroll position indicator, outside the view so it stays put
            Rectangle {
                x: appGrid.x + appGrid.width + 1
                width: 3
                radius: 1.5
                visible: appGrid.contentHeight > appGrid.height
                color: Theme.dim
                height: Math.max(24, appGrid.height * appGrid.height
                                   / Math.max(1, appGrid.contentHeight))
                y: appGrid.y + (appGrid.contentHeight > appGrid.height
                   ? (appGrid.contentY / (appGrid.contentHeight - appGrid.height))
                     * (appGrid.height - height)
                   : 0)
            }
        }

        // full name of a hovered app whose label in the grid got cut short,
        // drawn over the grid so it is not clipped by the cell or the view
        Rectangle {
            id: gridTip
            property var cell: null
            parent: content
            visible: root.appsOpen && cell !== null && cell.cut
            readonly property point at: {
                appGrid.contentY;
                return cell ? cell.mapToItem(content, cell.width / 2, 0) : Qt.point(0, 0);
            }
            width: tipText.implicitWidth + 12
            height: tipText.implicitHeight + 8
            x: Math.max(4, Math.min(content.width - width - 4, Math.round(at.x - width / 2)))
            y: Math.round(at.y - 4)
            z: 10
            radius: 6
            color: Qt.alpha(Theme.panelSolid, 0.94)
            border.color: Theme.blockBorder
            DotText {
                id: tipText
                anchors.centerIn: parent
                text: gridTip.cell ? gridTip.cell.text : ""
                px: 0.7; gap: 0.7
            }
        }

        // ---------- the dash itself ----------
        Row {
            id: dash
            anchors.horizontalCenter: parent.horizontalCenter
            // plain y rather than conditional anchors: clearing one anchor with
            // undefined does not reliably hand over to the other
            y: root.atTop ? 12 : parent.height - height - 12
            height: 52
            spacing: 8

            // pinned
            Repeater {
                model: root.pinned
                delegate: DockItem {
                    required property var modelData
                    entry: modelData
                    running: root.runningPinned(modelData)
                    onActivated: {
                        const t = root.toplevelFor(modelData);
                        if (t) t.activate(); else root.launch(modelData);
                    }
                    onPinToggled: root.togglePin(modelData.id)
                }
            }

            // separator, only when both sides have something
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 30
                color: Theme.blockBorder
                visible: root.pinned.length > 0 && unpinned.count > 0
            }

            // running but not pinned
            Repeater {
                id: unpinned
                model: root.running.filter(t => {
                    const e = root.entryFor(t.appId ?? "");
                    return !e || !root.isPinned(e.id);
                })
                delegate: DockItem {
                    required property var modelData
                    entry: root.entryFor(modelData.appId ?? "")
                    appId: modelData.appId ?? ""
                    running: true
                    onActivated: modelData.activate()
                    onPinToggled: {
                        const e = root.entryFor(modelData.appId ?? "");
                        if (e) root.togglePin(e.id);
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 30
                color: Theme.blockBorder
            }

            // apps button
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 46; height: 46
                radius: 12
                color: root.appsOpen ? Theme.hover : (ama.containsMouse ? Theme.hover : "transparent")
                border.color: root.appsOpen ? Theme.red : Theme.blockBorder
                border.width: 1
                DotIcon {
                    anchors.centerIn: parent
                    name: "grid"
                    px: 1.6; gap: 1.2
                    color: root.appsOpen || ama.containsMouse ? Theme.fg : Theme.mid
                }
                MouseArea {
                    id: ama
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.appsOpen = !root.appsOpen
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== "" && root.visible
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/dock-" + root.screen.name + ".png"))
    }

    // one dash tile: icon, hover label, running dot, right click pins
    component DockItem: Item {
        id: item
        property var entry: null
        property string appId: ""
        property bool running: false
        signal activated()
        signal pinToggled()

        width: 46
        height: 46
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: ima.containsMouse ? Theme.hover : "transparent"
            border.color: ima.containsMouse ? Theme.blockBorder : "transparent"
            border.width: 1

            Image {
                anchors.centerIn: parent
                width: 30; height: 30
                sourceSize.width: 30; sourceSize.height: 30
                source: root.iconFor(item.entry, item.appId)
                asynchronous: true
            }
            MouseArea {
                id: ima
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) item.pinToggled();
                    else item.activated();
                }
            }
        }

        // running indicator
        Rectangle {
            visible: item.running
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 2 }
            width: 5; height: 5; radius: 2.5
            color: Theme.red
        }

        // hover label on the open side of the tile (above, or below when the
        // dash sits at the top), kept inside the window
        Rectangle {
            visible: ima.containsMouse
            readonly property real wantX: (item.width - width) / 2
            x: {
                const p = item.mapToItem(null, 0, 0);
                return Math.max(4 - p.x, Math.min(root.width - 4 - p.x - width, wantX));
            }
            y: root.atTop ? item.height + 10 : -height - 6
            width: lbl.implicitWidth + 12
            height: lbl.implicitHeight + 8
            radius: 6
            color: Qt.alpha(Theme.panelSolid, 0.87)
            border.color: Theme.blockBorder
            DotText {
                id: lbl
                anchors.centerIn: parent
                text: (item.entry ? item.entry.name : item.appId).toUpperCase()
                px: 0.8; gap: 0.8
            }
        }
    }
}

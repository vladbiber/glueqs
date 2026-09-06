import Quickshell
import Quickshell.Wayland
import QtQuick

// App launcher: type to filter, Enter/click to launch, Esc to close.
PanelWindow {
    id: root
    anchors { top: true; left: true }
    margins { top: Theme.popupTop; left: Theme.popupLeft }
    implicitWidth: 300
    implicitHeight: 396
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "launcher"

    property int sel: 0
    onVisibleChanged: {
        if (visible) {
            input.text = "";
            sel = 0;
            input.forceActiveFocus();
        }
    }

    // launch counts, shared with the overview dock so both rank the same way
    readonly property var usage: {
        const m = ({});
        for (const pair of Settings.s.dockUsage.split(",")) {
            const i = pair.lastIndexOf("=");
            if (i > 0) m[pair.slice(0, i)] = parseInt(pair.slice(i + 1)) || 0;
        }
        return m;
    }
    function useCount(e) { return usage[e.id] ?? 0 }
    function bumpUsage(id) {
        if (!id) return;
        const m = usage;
        m[id] = (m[id] ?? 0) + 1;
        const out = [];
        for (const k in m) out.push(k + "=" + m[k]);
        Settings.s.dockUsage = out.join(",");
    }

    // whole list, no cap: the view scrolls. Most-launched first, then a name
    // sort; while typing, entries whose name starts with the query win outright
    // so the obvious match stays on top of a frequently used but weaker one.
    readonly property var apps: {
        const q = input.text.toLowerCase();
        const out = DesktopEntries.applications.values
            .filter(a => !a.noDisplay && a.name.toLowerCase().includes(q));
        out.sort((a, b) => {
            if (q !== "") {
                const pa = a.name.toLowerCase().startsWith(q) ? 0 : 1;
                const pb = b.name.toLowerCase().startsWith(q) ? 0 : 1;
                if (pa !== pb) return pa - pb;
            }
            const ua = root.useCount(a), ub = root.useCount(b);
            if (ua !== ub) return ub - ua;
            return a.name.localeCompare(b.name);
        });
        return out;
    }

    // keyboard selection: clamp, then scroll just enough to keep the row visible
    function select(i) {
        sel = Math.max(0, Math.min(i, apps.length - 1));
        list.positionViewAtIndex(sel, ListView.Contain);
    }

    function launch(entry) {
        if (!entry) return;
        bumpUsage(entry.id);
        entry.execute();
        Popups.open = "";
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        TextInput {
            id: input
            width: 1; height: 1
            opacity: 0
            focus: true
            onTextChanged: { root.sel = 0; list.positionViewAtBeginning(); }
            Keys.onEscapePressed: Popups.open = ""
            Keys.onReturnPressed: root.launch(root.apps[root.sel])
            Keys.onEnterPressed: root.launch(root.apps[root.sel])
            Keys.onDownPressed: root.select(root.sel + 1)
            Keys.onUpPressed: root.select(root.sel - 1)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_PageDown) { root.select(root.sel + 8); e.accepted = true; }
                else if (e.key === Qt.Key_PageUp) { root.select(root.sel - 8); e.accepted = true; }
                else if (e.key === Qt.Key_Home) { root.select(0); e.accepted = true; }
                else if (e.key === Qt.Key_End) { root.select(root.apps.length - 1); e.accepted = true; }
            }
        }

        Column {
            id: col
            anchors { fill: parent; margins: 16 }
            spacing: 8

            Rectangle {
                width: parent.width; height: 32
                radius: 8
                color: "#161616"
                border.color: Theme.blockBorder
                Row {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    DotText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ">"
                        px: 1.4; gap: 1; color: Theme.red
                    }
                    DotText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: input.text.toUpperCase()
                        px: 1.4; gap: 1
                    }
                    Rectangle { // cursor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 14
                        color: Theme.fg
                        SequentialAnimation on opacity {
                            running: root.visible; loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: col.height - 32 - col.spacing

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 2
                    model: root.apps
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width - (list.contentHeight > list.height ? 8 : 0)
                        height: 28
                        radius: 6
                        color: index === root.sel || ma.containsMouse ? "#1c1c1c" : "transparent"
                        border.color: index === root.sel ? Theme.red : "transparent"
                        border.width: 1
                        DotText {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            // modelData is briefly undefined while the view
                            // re-binds delegates after a model reset
                            text: (row.modelData?.name ?? "").toUpperCase()
                            maxWidth: row.width - 20
                            px: 1.2; gap: 1
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launch(row.modelData)
                        }
                    }
                }

                // dot-matrix scrollbar, only while there is something to scroll
                Rectangle {
                    visible: list.contentHeight > list.height
                    anchors.right: parent.right
                    width: 3
                    radius: 1.5
                    y: list.visibleArea.yPosition * parent.height
                    height: Math.max(20, list.visibleArea.heightRatio * parent.height)
                    color: Theme.red
                }
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 3000
        onTriggered: { Popups.open = "launcher"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1200
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/launcher-" + root.screen.name + ".png"))
    }
}

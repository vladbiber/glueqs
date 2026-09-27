import Quickshell
import QtQuick
import "GwActions.js" as Actions

// Pick what a bind does: a window manager action, an installed application
// (spawn: its Exec line) or a command typed by hand.
Column {
    id: root
    signal picked(string action)
    signal cancelled()
    property string query: ""
    property string tab: "wm"     // wm | apps | custom

    readonly property var wmAll: Actions.catalogue()
    readonly property var wmShown: {
        const q = query.toLowerCase();
        return q === "" ? wmAll : wmAll.filter(a => a.label.toLowerCase().includes(q) || a.action.includes(q) || a.group.toLowerCase().includes(q));
    }
    readonly property var apps: {
        const q = query.toLowerCase();
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const l = q === "" ? all : all.filter(e => (e.name ?? "").toLowerCase().includes(q) || (e.genericName ?? "").toLowerCase().includes(q));
        return l.slice().sort((a, b) => a.name.localeCompare(b.name));
    }
    function execOf(e) {
        const s = e.execString ?? (e.command ? e.command.join(" ") : "");
        return Actions.cleanExec(s);
    }

    spacing: 10

    Row {
        width: parent.width
        spacing: 8
        GwChoice {
            anchors.verticalCenter: parent.verticalCenter
            bound: true; value: root.tab
            options: [{ v: "wm", label: "WINDOW MANAGER" }, { v: "apps", label: "APPLICATIONS" }, { v: "custom", label: "CUSTOM COMMAND" }]
            onPicked: v => root.tab = v
        }
        Item { width: 1; height: 1 }
        GwButton { anchors.verticalCenter: parent.verticalCenter; label: "CANCEL"; small: true; onClicked: root.cancelled() }
    }
    GwField {
        visible: root.tab !== "custom"
        width: parent.width
        placeholder: root.tab === "wm" ? "search actions: close, workspace, focus..." : "search applications"
        text: root.query
        onCommitted: v => root.query = v
    }

    // window manager actions, grouped
    Rectangle {
        visible: root.tab === "wm"
        width: parent.width; height: 360
        radius: 8; color: "#0e0e0e"; border.color: Theme.blockBorder
        clip: true
        ListView {
            anchors { fill: parent; margins: 1 }
            model: root.wmShown
            boundsBehavior: Flickable.StopAtBounds
            section.property: "group"
            section.delegate: Rectangle {
                required property string section
                width: ListView.view.width; height: 26
                color: "#0e0e0e"
                Text { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } text: section.toUpperCase(); color: Theme.red; font.family: Theme.uiFont; font.pixelSize: 10; font.letterSpacing: 1.2 }
            }
            delegate: Rectangle {
                id: arow
                required property var modelData
                width: ListView.view.width; height: 32
                color: ama.containsMouse ? "#1a1a1a" : "transparent"
                Text {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    text: arow.modelData.label
                    color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
                }
                Text {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: arow.modelData.action
                    color: "#7a7a7a"; font.family: Theme.uiFont; font.pixelSize: 11
                }
                MouseArea { id: ama; anchors.fill: parent; hoverEnabled: true; onClicked: root.picked(arow.modelData.action) }
            }
        }
    }

    // applications
    Rectangle {
        visible: root.tab === "apps"
        width: parent.width; height: 360
        radius: 8; color: "#0e0e0e"; border.color: Theme.blockBorder
        clip: true
        ListView {
            anchors { fill: parent; margins: 1 }
            model: root.apps
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: prow
                required property var modelData
                width: ListView.view.width; height: 38
                color: pma.containsMouse ? "#1a1a1a" : "transparent"
                Image {
                    id: icon
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 22; height: 22
                    source: Quickshell.iconPath(prow.modelData.icon ?? "", true)
                    sourceSize.width: 22; sourceSize.height: 22
                    asynchronous: true
                }
                Column {
                    anchors { left: icon.right; leftMargin: 10; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Text { width: parent.width; text: prow.modelData.name; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12; elide: Text.ElideRight }
                    Text { width: parent.width; text: root.execOf(prow.modelData); color: "#7a7a7a"; font.family: Theme.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                }
                MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: root.picked("spawn:" + root.execOf(prow.modelData)) }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: root.apps.length === 0
            text: "No applications found"
            color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12
        }
    }

    // custom
    Column {
        visible: root.tab === "custom"
        width: parent.width
        spacing: 8
        Text { text: "Runs through sh -c, so pipes and $VARS work."; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11 }
        Row {
            width: parent.width
            spacing: 8
            GwField { id: custom; width: parent.width - useB.width - 8; placeholder: "foot -e htop" }
            GwButton { id: useB; label: "USE"; onClicked: { const c = custom.draft.trim(); if (c !== "") root.picked("spawn:" + c); } }
        }
        Text { text: "Or a raw action, e.g. wm:ratio:+0.1"; color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11 }
        Row {
            width: parent.width
            spacing: 8
            GwField { id: raw; width: parent.width - rawB.width - 8; placeholder: "wm:..." }
            GwButton { id: rawB; label: "USE"; onClicked: { const c = raw.draft.trim(); if (c !== "") root.picked(c); } }
        }
    }
}

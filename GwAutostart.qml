import QtQuick

// Autostart page: the commands gluewc runs at login, one per line.
Column {
    id: page
    spacing: 0
    property string draft: ""

    function replaceAt(i, cmd) {
        const l = Gluewc.autostarts.map(a => a.cmd);
        if (cmd.trim() === "") l.splice(i, 1); else l[i] = cmd.trim();
        Gluewc.setAutostarts(l);
    }
    function add(cmd) {
        if (cmd.trim() === "") return;
        Gluewc.setAutostarts(Gluewc.autostarts.map(a => a.cmd).concat([cmd.trim()]));
    }

    GwTitle {
        first: true
        text: "AUTOSTART"
        sub: "Run once when the session starts, through sh -c. New lines apply at the next login; removing one does not stop what is already running."
    }

    Repeater {
        model: Gluewc.autostarts
        delegate: Item {
            id: arow
            required property var modelData
            required property int index
            width: parent.width; height: 46
            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 26
                text: String(arow.index + 1)
                color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12
            }
            GwField {
                anchors { left: parent.left; leftMargin: 26; right: rm.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: arow.modelData.cmd
                onCommitted: v => page.replaceAt(arow.index, v)
            }
            GwButton {
                id: rm
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                label: "REMOVE"; small: true; danger: true
                onClicked: page.replaceAt(arow.index, "")
            }
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#1a1a1a" }
        }
    }

    Item {
        width: parent.width; height: 12
        visible: Gluewc.autostarts.length === 0
    }
    Text {
        visible: Gluewc.autostarts.length === 0
        text: "Nothing starts with the session yet."
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 12
    }

    Item { width: 1; height: 14 }
    Row {
        width: parent.width
        spacing: 10
        GwField {
            id: newCmd
            width: parent.width - addBtn.width - 10
            placeholder: "command to add, e.g. nm-applet"
            onCommitted: v => { page.add(v); clear(); }
        }
        GwButton {
            id: addBtn
            label: "ADD"
            onClicked: { page.add(newCmd.draft); newCmd.clear(); }
        }
    }
    Item { width: 1; height: 8 }
    Text {
        width: parent.width
        text: "The glueqs bar itself is one of these lines (qs -c glueqs). Wallpaper daemons are not needed: the shell paints the wallpaper."
        color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11; wrapMode: Text.WordWrap
    }
}

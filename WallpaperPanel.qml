import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel

// The wallpaper picker: a grid of the pictures in a folder, the one on screen
// marked in the accent, applied with a click or Enter. Fill mode, transition,
// shuffle and the "all screens or just this one" choice sit underneath.
// Opened from the bar's settings, Mod+W, or `qs -c glueqs ipc call glueqs wallpaper`.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 780
    implicitHeight: 560
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "wallpaper"

    readonly property string screenName: root.screen?.name ?? ""
    // "" = every screen, otherwise this screen only
    property string target: ""
    property int sel: -1

    readonly property var files: Wallpapers.files
    readonly property string current: Wallpapers.pathFor(root.screenName)

    onVisibleChanged: {
        if (visible) {
            Wallpapers.refresh();
            sel = Math.max(0, files.indexOf(current));
            keys.forceActiveFocus();
        }
    }

    function shortDir(p) {
        const h = Wallpapers.homeDir;
        return (h !== "" && p.startsWith(h) ? "~" + p.slice(h.length) : p).toUpperCase();
    }
    function parentDir(p) {
        const i = p.lastIndexOf("/");
        return i <= 0 ? "/" : p.slice(0, i);
    }
    function baseName(p) {
        const i = p.lastIndexOf("/");
        const n = i >= 0 ? p.slice(i + 1) : p;
        const d = n.lastIndexOf(".");
        return (d > 0 ? n.slice(0, d) : n).replace(/[-_]+/g, " ").toUpperCase();
    }
    function apply(path) {
        if (!path) return;
        Wallpapers.set(path, root.target);
    }
    function select(i) {
        if (files.length === 0) return;
        sel = Math.max(0, Math.min(i, files.length - 1));
        grid.positionViewAtIndex(sel, GridView.Contain);
    }

    // a small labelled pill, lit when `on`
    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool on: false
        signal clicked()
        width: chipLabel.implicitWidth + 16; height: 22
        radius: 6
        color: chip.on ? Theme.red : (cma.containsMouse ? "#1c1c1c" : "transparent")
        border.color: chip.on ? Theme.red : (cma.containsMouse ? Theme.fg : Theme.blockBorder)
        border.width: 1
        DotText {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.label
            px: 0.8; gap: 0.8
            color: chip.on ? "#000000" : (cma.containsMouse ? Theme.fg : Theme.mid)
        }
        MouseArea {
            id: cma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: chip.clicked()
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        // keyboard: arrows move, Enter applies, R shuffles, Esc closes
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: Popups.open = ""
            Keys.onReturnPressed: root.apply(root.files[root.sel])
            Keys.onEnterPressed: root.apply(root.files[root.sel])
            Keys.onLeftPressed: root.select(root.sel - 1)
            Keys.onRightPressed: root.select(root.sel + 1)
            Keys.onUpPressed: root.select(root.sel - 4)
            Keys.onDownPressed: root.select(root.sel + 4)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_R) { Wallpapers.random(root.target); e.accepted = true; }
                else if (e.key === Qt.Key_N) { Wallpapers.next(root.target); e.accepted = true; }
                else if (e.key === Qt.Key_Backspace) { Settings.s.wallpaperDir = root.parentDir(Wallpapers.dir); e.accepted = true; }
            }
        }

        Column {
            id: col
            anchors { fill: parent; margins: 16 }
            spacing: 8

            // title, folder, up
            Item {
                width: parent.width; height: 26
                DotText {
                    id: title
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "WALLPAPER"
                    px: 1.5; gap: 1.2
                }
                DotText {
                    anchors { left: title.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    text: root.shortDir(Wallpapers.dir)
                    px: 0.85; gap: 0.85; color: Theme.mid
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Chip { label: "UP"; onClicked: Settings.s.wallpaperDir = root.parentDir(Wallpapers.dir) }
                    Chip { label: "SHUFFLE"; onClicked: Wallpapers.random(root.target) }
                    Chip { label: "CLOSE"; onClicked: Popups.open = "" }
                }
            }

            // subfolders, click to go in
            FolderListModel {
                id: dirs
                folder: "file://" + Wallpapers.dir
                showFiles: false
                showDotAndDotDot: false
                sortField: FolderListModel.Name
            }
            Flow {
                width: parent.width
                spacing: 4
                visible: dirs.count > 0
                Repeater {
                    model: dirs
                    delegate: Chip {
                        required property string fileName
                        required property string filePath
                        label: fileName.toUpperCase()
                        onClicked: Settings.s.wallpaperDir = filePath
                    }
                }
            }

            // the pictures
            GridView {
                id: grid
                width: parent.width
                height: parent.height - y - footer.height - col.spacing
                clip: true
                cellWidth: Math.floor(width / 4)
                cellHeight: Math.round(cellWidth * 0.5625) + 6
                model: root.files
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.sel

                delegate: Item {
                    id: cell
                    required property string modelData
                    required property int index
                    readonly property bool isCurrent: cell.modelData === root.current
                    readonly property bool isSel: cell.index === root.sel
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors { fill: parent; margins: 4 }
                        radius: 10
                        color: "#161616"
                        border.color: cell.isCurrent ? Theme.red
                                    : (cell.isSel || wma.containsMouse) ? Theme.fg : Theme.blockBorder
                        border.width: cell.isCurrent || cell.isSel ? 2 : 1
                        clip: true

                        Image {
                            anchors { fill: parent; margins: 2 }
                            source: "file://" + cell.modelData
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 360
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                        // the one on screen gets a dot in the corner
                        Rectangle {
                            visible: cell.isCurrent
                            anchors { top: parent.top; right: parent.right; margins: 8 }
                            width: 10; height: 10; radius: 5
                            color: Theme.red
                            border.color: "#000000"; border.width: 1
                        }
                        // name band, only while hovered or selected
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 18
                            visible: wma.containsMouse || cell.isSel
                            color: "#cc000000"
                            DotText {
                                anchors.centerIn: parent
                                text: root.baseName(cell.modelData).slice(0, 22)
                                px: 0.7; gap: 0.7
                            }
                        }
                        MouseArea {
                            id: wma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.sel = cell.index; root.apply(cell.modelData); }
                        }
                    }
                }
            }

            DotText {
                visible: root.files.length === 0
                text: "NO PICTURES HERE. PUT SOME IN " + root.shortDir(Wallpapers.dir)
                px: 0.9; gap: 0.9; color: Theme.dim
            }

            // options
            Column {
                id: footer
                width: parent.width
                spacing: 6

                Row {
                    spacing: 6
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "FILL"; px: 0.85; gap: 0.85; color: Theme.mid; width: 52 }
                    Repeater {
                        model: ["crop", "fit", "stretch", "center", "tile"]
                        delegate: Chip {
                            required property string modelData
                            label: modelData.toUpperCase()
                            on: Settings.s.wallpaperFill === modelData
                            onClicked: Settings.s.wallpaperFill = modelData
                        }
                    }
                    Item { width: 14; height: 1 }
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "SET ON"; px: 0.85; gap: 0.85; color: Theme.mid }
                    Chip { label: "ALL SCREENS"; on: root.target === ""; onClicked: root.target = "" }
                    Chip { label: root.screenName.toUpperCase(); on: root.target !== ""; onClicked: root.target = root.screenName }
                }
                Row {
                    spacing: 6
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "FX"; px: 0.85; gap: 0.85; color: Theme.mid; width: 52 }
                    Repeater {
                        model: ["fade", "wipe", "slide", "zoom", "random"]
                        delegate: Chip {
                            required property string modelData
                            label: modelData.toUpperCase()
                            on: Settings.s.wallpaperTransition === modelData
                            onClicked: Settings.s.wallpaperTransition = modelData
                        }
                    }
                    Item { width: 14; height: 1 }
                    DotText { anchors.verticalCenter: parent.verticalCenter; text: "SHUFFLE"; px: 0.85; gap: 0.85; color: Theme.mid }
                    Repeater {
                        model: [0, 5, 15, 30, 60]
                        delegate: Chip {
                            required property int modelData
                            label: modelData === 0 ? "OFF" : modelData + " MIN"
                            on: Settings.s.wallpaperRandomMin === modelData
                            onClicked: Settings.s.wallpaperRandomMin = modelData
                        }
                    }
                }
                DotText {
                    text: "CLICK OR ENTER TO APPLY. R SHUFFLES, N IS NEXT, BACKSPACE GOES UP A FOLDER."
                    px: 0.7; gap: 0.7; color: Theme.hint
                }
            }
        }
    }
}

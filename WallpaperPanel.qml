import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel

// The wallpaper picker and browser: breadcrumbs, the subfolders, a typed
// path and a centred grid of the pictures in the folder being looked at, the
// one on screen marked in the accent, applied with one click or Enter.
// Browsing does not move the shuffle folder until USE THIS FOLDER is
// pressed. Typing filters the names; fill mode, transition, shuffle and
// "all screens or just this one" sit underneath. Opened from the bar's
// settings, Mod+W, or `qs -c glueqs ipc call glueqs wallpaper`.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "wallpaper"

    readonly property string screenName: root.screen?.name ?? ""
    // "" = every screen, otherwise this screen only
    property string target: ""
    property int sel: -1
    property string filter: ""
    // the folder on show; empty means the shuffle folder from settings
    property string browseDir: ""
    readonly property string dir: browseDir !== "" ? browseDir : Wallpapers.dir

    readonly property string current: Wallpapers.pathFor(root.screenName)
    property var allFiles: []
    readonly property var files: {
        const q = filter.toLowerCase();
        return q === "" ? allFiles : allFiles.filter(p => root.baseName(p).toLowerCase().includes(q));
    }
    readonly property var crumbs: {
        const h = Wallpapers.homeDir;
        const out = [{ label: "/", path: "/" }];
        let acc = "";
        for (const part of root.dir.split("/").filter(x => x !== "")) {
            acc += "/" + part;
            out.push({ label: acc === h ? "~" : part.toUpperCase(), path: acc });
        }
        return out;
    }
    function go(path) {
        let p = path.trim();
        if (p === "") return;
        if (p.startsWith("~")) p = Wallpapers.homeDir + p.slice(1);
        if (p.length > 1 && p.endsWith("/")) p = p.slice(0, -1);
        if (Wallpapers.isImage(p)) { root.apply(p); return; }
        root.browseDir = p;
        root.filter = "";
        root.sel = 0;
        keys.forceActiveFocus();
    }

    // the card sits in the middle and takes what the screen allows
    readonly property int cardW: Math.min(960, Math.round(width * 0.78))
    readonly property int cardH: Math.min(680, Math.round(height * 0.82))
    readonly property int columns: Math.max(3, Math.floor((cardW - 32) / 210))

    onVisibleChanged: {
        if (visible) {
            filter = "";
            browseDir = "";
            Wallpapers.refresh();
            sel = Math.max(0, allFiles.indexOf(current));
            keys.forceActiveFocus();
            grid.positionViewAtIndex(sel, GridView.Contain);
        }
    }

    // the pictures of the folder on show
    FolderListModel {
        id: pics
        folder: "file://" + root.dir
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        nameFilters: Wallpapers.extensions.map(e => "*." + e).concat(Wallpapers.extensions.map(e => "*." + e.toUpperCase()))
        onCountChanged: root.refreshFiles()
        onStatusChanged: if (status === FolderListModel.Ready) root.refreshFiles()
    }
    function refreshFiles() {
        const out = [];
        for (let i = 0; i < pics.count; i++) out.push(pics.get(i, "filePath"));
        if (out.join("\n") !== allFiles.join("\n")) allFiles = out;
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
            maxWidth: 160
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

    // a click outside the card closes it
    MouseArea {
        anchors.fill: parent
        onClicked: Popups.open = ""
    }

    // GLUEQS_SHOT_DIR + GLUEQS_SHOT_WALL=1 grabs the browser for screenshots
    Timer {
        running: (Quickshell.env("GLUEQS_SHOT_DIR") ?? "") !== "" && (Quickshell.env("GLUEQS_SHOT_WALL") ?? "") !== ""
        interval: 4500
        onTriggered: { Popups.open = "wallpaper"; wallShot.start(); }
    }
    Timer {
        id: wallShot
        interval: 2500
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT_DIR") + "/wallpaper-" + root.screenName + ".png"))
    }

    Rectangle {
        id: content
        anchors.centerIn: parent
        width: root.cardW
        height: root.cardH
        radius: 16
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        MouseArea { anchors.fill: parent }   // swallow clicks inside the card

        // keyboard: letters filter, arrows move, Enter applies, R shuffles,
        // N is next, Backspace clears the filter or goes up a folder, Esc closes
        Item {
            id: keys
            focus: true
            Keys.onEscapePressed: {
                if (root.filter !== "") root.filter = "";
                else Popups.open = "";
            }
            Keys.onReturnPressed: root.apply(root.files[root.sel])
            Keys.onEnterPressed: root.apply(root.files[root.sel])
            Keys.onLeftPressed: root.select(root.sel - 1)
            Keys.onRightPressed: root.select(root.sel + 1)
            Keys.onUpPressed: root.select(root.sel - root.columns)
            Keys.onDownPressed: root.select(root.sel + root.columns)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Backspace) {
                    if (root.filter !== "") root.filter = root.filter.slice(0, -1);
                    else root.go(root.parentDir(root.dir));
                    e.accepted = true;
                } else if (e.key === Qt.Key_Home) { root.select(0); e.accepted = true; }
                else if (e.key === Qt.Key_End) { root.select(root.files.length - 1); e.accepted = true; }
                else if (e.key === Qt.Key_PageDown) { root.select(root.sel + root.columns * 3); e.accepted = true; }
                else if (e.key === Qt.Key_PageUp) { root.select(root.sel - root.columns * 3); e.accepted = true; }
                else if (e.modifiers & Qt.ControlModifier) {
                    if (e.key === Qt.Key_R) { Wallpapers.random(root.target); e.accepted = true; }
                    else if (e.key === Qt.Key_N) { Wallpapers.next(root.target); e.accepted = true; }
                } else if (e.text !== "" && e.text >= " " && e.text.length === 1) {
                    root.filter += e.text;
                    root.sel = 0;
                    e.accepted = true;
                }
            }
        }

        Column {
            id: col
            anchors { fill: parent; margins: 16 }
            spacing: 8

            // title, folder, filter, buttons
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
                    visible: root.filter !== ""
                    text: "FILTER  " + root.filter.toUpperCase()
                    maxWidth: buttons.x - title.width - 18 - 18 - 12
                    px: 0.85; gap: 0.85
                }
                Row {
                    id: buttons
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Chip { label: "NEXT"; onClicked: Wallpapers.next(root.target) }
                    Chip { label: "SHUFFLE"; onClicked: Wallpapers.random(root.target) }
                    Chip { label: "CLOSE"; onClicked: Popups.open = "" }
                }
            }

            // where we are: breadcrumbs, a typed path, and the shuffle folder switch
            Flow {
                width: parent.width
                spacing: 4
                Chip { label: "UP"; onClicked: root.go(root.parentDir(root.dir)) }
                Chip { label: "PICTURES"; onClicked: root.go(Wallpapers.homeDir + "/Pictures") }
                Item { width: 6; height: 1 }
                Repeater {
                    model: root.crumbs
                    delegate: Row {
                        required property var modelData
                        required property int index
                        spacing: 4
                        DotText { visible: index > 0; anchors.verticalCenter: parent.verticalCenter; text: ">"; px: 0.7; gap: 0.7; color: Theme.mid }
                        Chip {
                            label: modelData.label
                            on: index === root.crumbs.length - 1
                            onClicked: root.go(modelData.path)
                        }
                    }
                }
            }
            Row {
                width: parent.width
                spacing: 8
                GwField {
                    id: pathField
                    width: parent.width - useFolder.width - 8
                    height: 28
                    text: root.dir
                    placeholder: "type a folder, or a picture's path, and press Enter"
                    onCommitted: v => root.go(v)
                }
                Chip {
                    id: useFolder
                    anchors.verticalCenter: parent.verticalCenter
                    label: root.dir === Wallpapers.dir ? "SHUFFLE FOLDER" : "USE THIS FOLDER"
                    on: root.dir === Wallpapers.dir
                    onClicked: Settings.s.wallpaperDir = root.dir
                }
            }

            // subfolders, click to go in
            FolderListModel {
                id: dirs
                folder: "file://" + root.dir
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
                        label: "/ " + fileName.toUpperCase()
                        onClicked: root.go(filePath)
                    }
                }
            }

            // the pictures
            GridView {
                id: grid
                width: parent.width
                height: parent.height - y - footer.height - col.spacing
                clip: true
                cellWidth: Math.floor(width / root.columns)
                cellHeight: Math.round(cellWidth * 0.5625) + 8
                model: root.files
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.sel
                cacheBuffer: cellHeight * 4

                delegate: Item {
                    id: cell
                    required property string modelData
                    required property int index
                    readonly property bool isCurrent: cell.modelData === root.current
                    readonly property bool isSel: cell.index === root.sel
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: frame
                        anchors { fill: parent; margins: 4 }
                        radius: 10
                        color: "#161616"
                        border.color: cell.isCurrent ? Theme.red
                                    : (cell.isSel || wma.containsMouse) ? Theme.fg : Theme.blockBorder
                        border.width: cell.isCurrent || cell.isSel ? 2 : 1
                        clip: true
                        scale: wma.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Image {
                            anchors { fill: parent; margins: 2 }
                            source: "file://" + cell.modelData
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 400
                            asynchronous: true
                            cache: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                        // the one on screen is tagged
                        Rectangle {
                            visible: cell.isCurrent
                            anchors { top: parent.top; right: parent.right; margins: 8 }
                            width: nowLbl.implicitWidth + 12; height: 16; radius: 4
                            color: Theme.red
                            DotText {
                                id: nowLbl
                                anchors.centerIn: parent
                                text: "NOW"
                                px: 0.7; gap: 0.7; color: "#000000"
                            }
                        }
                        // name band, always there so the pictures can be told apart
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 18
                            color: wma.containsMouse || cell.isSel ? "#dd000000" : "#99000000"
                            DotText {
                                anchors.centerIn: parent
                                text: root.baseName(cell.modelData)
                                maxWidth: parent.width - 12
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
                text: root.filter !== "" ? "NOTHING MATCHES " + root.filter.toUpperCase()
                                         : "NO PICTURES IN " + root.shortDir(root.dir) + ". OPEN A FOLDER ABOVE OR TYPE A PATH."
                maxWidth: parent.width
                px: 0.9; gap: 0.9; color: Theme.dim
            }

            // options
            Column {
                id: footer
                width: parent.width
                spacing: 6

                Flow {
                    width: parent.width
                    spacing: 6
                    DotText { text: "FILL"; px: 0.85; gap: 0.85; color: Theme.mid; width: 52; height: 22 }
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
                    DotText { text: "SET ON"; px: 0.85; gap: 0.85; color: Theme.mid; height: 22 }
                    Chip { label: "ALL SCREENS"; on: root.target === ""; onClicked: root.target = "" }
                    Chip { label: root.screenName.toUpperCase(); on: root.target !== ""; onClicked: root.target = root.screenName }
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    DotText { text: "FX"; px: 0.85; gap: 0.85; color: Theme.mid; width: 52; height: 22 }
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
                    DotText { text: "SHUFFLE"; px: 0.85; gap: 0.85; color: Theme.mid; height: 22 }
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
                    text: "CLICK OR ENTER APPLIES. TYPE TO FILTER. CTRL+R SHUFFLES, CTRL+N IS NEXT, BACKSPACE GOES UP A FOLDER."
                    maxWidth: parent.width
                    px: 0.7; gap: 0.7; color: Theme.hint
                }
            }
        }
    }
}

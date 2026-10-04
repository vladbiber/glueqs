import Quickshell
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel

// The wallpaper picker, after the hypr one: a band of slanted cards across the
// whole screen, the focused one wide in the middle, and a floating bar above
// with colour filters, a name search, which screen, the folder and the
// options. Left/Right browse, Enter or a click applies, Tab walks the colour
// filters, typing searches, Ctrl+R shuffles, Esc closes. Opened from the bar,
// the settings, Mod+W, or `qs -c glueqs ipc call glueqs wallpaper`.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    visible: Popups.open === "wallpaper"

    readonly property string screenName: root.screen?.name ?? ""
    property string target: ""          // "" = every screen
    property string filter: "all"       // all | a colour bucket
    property string query: ""
    property string browseDir: ""
    property bool drawer: false         // folder and options
    readonly property string dir: browseDir !== "" ? browseDir : Wallpapers.dir
    readonly property string current: Wallpapers.pathFor(root.screenName)

    // a scale like the hypr one: relative to a 1080p screen
    readonly property real s: Math.max(0.55, Math.min(1.3, Math.min(width / 1920, height / 1080)))
    function px(v) { return Math.round(v * s) }

    property var allFiles: []
    readonly property var files: {
        // colours only matter under a colour filter; reading the counter
        // otherwise would rebuild the band for every new thumbnail
        if (filter !== "all") WallThumbs.version;
        const q = query.toLowerCase();
        return allFiles.filter(p => (q === "" || baseName(p).toLowerCase().includes(q))
                                 && (filter === "all" || WallThumbs.bucket(WallThumbs.colors[p]) === filter));
    }
    function baseName(p) {
        const i = p.lastIndexOf("/");
        const n = i >= 0 ? p.slice(i + 1) : p;
        const d = n.lastIndexOf(".");
        return (d > 0 ? n.slice(0, d) : n).replace(/[-_]+/g, " ");
    }
    function go(path) {
        let p = path.trim();
        if (p === "") return;
        if (p.startsWith("~")) p = Wallpapers.homeDir + p.slice(1);
        if (p.length > 1 && p.endsWith("/")) p = p.slice(0, -1);
        if (Wallpapers.isImage(p)) { apply(p); return; }
        browseDir = p;
        query = "";
        filter = "all";
    }
    function apply(path) {
        if (!path) return;
        Wallpapers.set(path, target);
    }
    readonly property var filterOrder: ["all"].concat(WallThumbs.buckets.map(b => b.id))
    function cycleFilter(d) {
        const i = filterOrder.indexOf(filter);
        filter = filterOrder[(i + d + filterOrder.length) % filterOrder.length];
    }

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
        if (out.join("\n") !== allFiles.join("\n")) { allFiles = out; WallThumbs.load(root.dir); }
    }

    onVisibleChanged: {
        if (visible) {
            query = ""; filter = "all"; browseDir = ""; drawer = false;
            Wallpapers.refresh();
            WallThumbs.load(root.dir);
            keys.forceActiveFocus();
            strip.focusOn(root.current);
        }
    }

    // a soft veil so the cards read on any desktop; a click on it closes
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.bg, 0.0) }
            GradientStop { position: 0.5; color: Qt.alpha(Theme.bg, 0.55) }
            GradientStop { position: 1; color: Qt.alpha(Theme.bg, 0.0) }
        }
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }
        MouseArea { anchors.fill: parent; onClicked: { if (root.drawer) root.drawer = false; else Popups.open = ""; } }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: {
            if (root.drawer) root.drawer = false;
            else if (root.query !== "") root.query = "";
            else Popups.open = "";
        }
        Keys.onReturnPressed: root.apply(strip.focused)
        Keys.onEnterPressed: root.apply(strip.focused)
        Keys.onLeftPressed: strip.step(-1)
        Keys.onRightPressed: strip.step(1)
        Keys.onTabPressed: root.cycleFilter(1)
        Keys.onBacktabPressed: root.cycleFilter(-1)
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Backspace) {
                if (root.query !== "") root.query = root.query.slice(0, -1);
                e.accepted = true;
            } else if (e.key === Qt.Key_Home) { strip.jump(0); e.accepted = true; }
            else if (e.key === Qt.Key_End) { strip.jump(root.files.length - 1); e.accepted = true; }
            else if (e.modifiers & Qt.ControlModifier) {
                if (e.key === Qt.Key_R) { Wallpapers.random(root.target); strip.focusOn(Wallpapers.pathFor(root.screenName)); e.accepted = true; }
                else if (e.key === Qt.Key_N) { Wallpapers.next(root.target); e.accepted = true; }
                else if (e.key === Qt.Key_O) { root.drawer = !root.drawer; e.accepted = true; }
            } else if (e.text !== "" && e.text >= " " && e.text.length === 1) {
                root.query += e.text;
                e.accepted = true;
            }
        }
    }

    // ---------- the band of cards ----------
    WallStrip {
        id: strip
        picker: root
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; verticalCenterOffset: root.px(30) }
        height: root.px(560)
    }

    // ---------- the floating bar ----------
    WallBar {
        id: wbar
        picker: root
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.visible ? strip.y - height - root.px(26) : strip.y - height - root.px(120)
        opacity: root.visible ? 1 : 0
        Behavior on y { NumberAnimation { duration: Theme.ms(600); easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Theme.ms(500); easing.type: Easing.OutCubic } }
    }

    // the name of the focused picture and the keys, under the band
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: strip.bottom; topMargin: root.px(18) }
        spacing: 8
        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: strip.focused ? root.baseName(strip.focused).toUpperCase() : (root.query !== "" ? "NOTHING MATCHES " + root.query.toUpperCase() : "NO PICTURES HERE")
            maxWidth: root.width - 80
            px: 1.3; gap: 1
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "←  →  browse     enter  apply     tab  colour     type  search     ctrl+r  random     ctrl+o  folder     esc  close"
            color: Theme.muted; font.family: Theme.uiFont; font.pixelSize: 11
        }
    }

    // ---------- folder and options ----------
    WallDrawer {
        picker: root
        anchors.horizontalCenter: parent.horizontalCenter
        y: wbar.y + wbar.height + 10
        visible: opacity > 0.01
        opacity: root.drawer ? 1 : 0
        scale: root.drawer ? 1 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic } }
    }

    // GLUEQS_SHOT_DIR + GLUEQS_SHOT_WALL=1 grabs the picker for screenshots
    Timer {
        running: (Quickshell.env("GLUEQS_SHOT_DIR") ?? "") !== "" && (Quickshell.env("GLUEQS_SHOT_WALL") ?? "") !== ""
        interval: 4500
        onTriggered: { Popups.open = "wallpaper"; wallShot.start(); }
    }
    Timer {
        id: wallShot
        interval: 3000
        onTriggered: root.contentItem.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT_DIR") + "/wallpaper-" + root.screenName + ".png"))
    }
}

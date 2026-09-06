pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which wallpaper goes on which screen. The shell paints the wallpaper itself
// (see Wallpaper.qml), so there is no daemon to run and no external tool to
// keep in step; the choice lives in settings.json like everything else.
//
//   wallpaper            path used on every screen
//   wallpaperPerMonitor  "name=path;name=path" overrides for single screens
//   wallpaperFill        crop | fit | stretch | center | tile
//   wallpaperTransition  fade | wipe | slide | zoom | random
//   wallpaperTransitionMs
//   wallpaperRandomMin   minutes between random changes, 0 = off
Singleton {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    readonly property string dir: Settings.s.wallpaperDir !== ""
                                ? Settings.s.wallpaperDir
                                : homeDir + "/Pictures/Wallpapers"
    readonly property var extensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif", "avif", "jxl"]

    function isImage(name) {
        const i = name.lastIndexOf(".");
        return i > 0 && extensions.includes(name.slice(i + 1).toLowerCase());
    }

    // the overrides as a map, parsed once per change
    readonly property var perMonitor: {
        const m = ({});
        for (const pair of Settings.s.wallpaperPerMonitor.split(";")) {
            const i = pair.indexOf("=");
            if (i > 0) m[pair.slice(0, i)] = pair.slice(i + 1);
        }
        return m;
    }

    function pathFor(screenName) {
        return perMonitor[screenName] ?? Settings.s.wallpaper;
    }

    function writePerMonitor(m) {
        const out = [];
        for (const k in m) if (m[k] !== "") out.push(k + "=" + m[k]);
        Settings.s.wallpaperPerMonitor = out.join(";");
    }

    // set on one screen, or everywhere when screenName is empty. Setting it
    // everywhere also drops the single-screen overrides, so "all" means all.
    function set(path, screenName) {
        if (!path || path === "") return;
        if (screenName && screenName !== "") {
            if (pathFor(screenName) === path) return;
            const m = perMonitor;
            m[screenName] = path;
            writePerMonitor(m);
            if (Settings.s.wallpaper === "") Settings.s.wallpaper = path;
        } else {
            if (Settings.s.wallpaperPerMonitor === "" && Settings.s.wallpaper === path) return;
            Settings.s.wallpaperPerMonitor = "";
            Settings.s.wallpaper = path;
        }
    }

    // the images in the current folder, for the picker and the random timer
    property var files: []
    Process {
        id: lister
        command: ["sh", "-c",
            "cd \"$1\" 2>/dev/null || exit 0; for f in *; do [ -f \"$f\" ] && printf '%s\\n' \"$f\"; done",
            "glueqs", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const name of text.split("\n"))
                    if (name !== "" && root.isImage(name)) out.push(root.dir + "/" + name);
                out.sort((a, b) => a.localeCompare(b));
                // only publish a change: reassigning the same list would
                // rebuild every thumbnail in the picker for nothing
                if (out.join("\n") !== root.files.join("\n"))
                    root.files = out;
            }
        }
    }
    function refresh() { lister.running = true }
    Component.onCompleted: refresh()
    onDirChanged: refresh()

    function next(screenName) {
        if (files.length === 0) return;
        const cur = pathFor(screenName ?? "");
        let i = files.indexOf(cur);
        i = (i + 1) % files.length;
        set(files[i], screenName ?? "");
    }

    function random(screenName) {
        if (files.length === 0) return;
        const cur = pathFor(screenName ?? "");
        let pick = files[Math.floor(Math.random() * files.length)];
        if (files.length > 1 && pick === cur)
            pick = files[(files.indexOf(pick) + 1) % files.length];
        set(pick, screenName ?? "");
    }

    Timer {
        interval: Math.max(1, Settings.s.wallpaperRandomMin) * 60000
        running: Settings.s.wallpaperRandomMin > 0 && root.files.length > 1
        repeat: true
        onTriggered: { root.refresh(); root.random(""); }
    }
}

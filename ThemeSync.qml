pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// One debounced palette drives compositor borders and opted-in terminals.
Singleton {
    id: root
    property var terminals: ({})
    property string status: ""
    readonly property string palette: {
        const p = Object.assign({}, Theme.p);
        p.accent = String(Theme.red);
        return JSON.stringify(p);
    }
    readonly property string choices: Settings.s.themeAlacritty + ":" + Settings.s.themeKitty + ":" + Settings.s.themeWindowBorders + ":" + Settings.s.themeTerminalText
    readonly property bool ready: Settings.ready && (Settings.s.themeScheme !== "wallpaper" || Theme.wallReady)
    onPaletteChanged: sync.restart()
    onChoicesChanged: sync.restart()
    onReadyChanged: sync.restart()
    Component.onCompleted: detect()

    function detect() { probe.running = true }
    function apply() { sync.restart() }
    function found(name) { return terminals[name]?.installed || terminals[name]?.configured || false }
    function description(name) {
        const t = terminals[name];
        return !t ? "Detecting…" : found(name) ? t.path : "Not detected";
    }
    function borderColor(key, color) {
        const old = Gluewc.get(key).replace(/^(#|0x)/, "");
        return String(color).slice(1, 7) + (/^[0-9a-fA-F]{8}$/.test(old) ? old.slice(6) : "");
    }
    function borders() {
        if (!root.ready || !Settings.s.themeWindowBorders || !Gluewc.available || !Gluewc.loaded) return;
        const values = { border_focus: Theme.red, border_normal: Theme.border, normal_mode_color: Theme.fg };
        for (const key in values) {
            const value = borderColor(key, values[key]);
            if (Gluewc.get(key).replace(/^(#|0x)/, "").toLowerCase() !== value.toLowerCase())
                Gluewc.set(key, value);
        }
    }
    Connections {
        target: Gluewc
        function onLoadedChanged() { sync.restart() }
        function onAvailableChanged() { sync.restart() }
        function onValuesChanged() { borderSync.restart() }
    }
    Timer { id: borderSync; interval: 250; onTriggered: root.borders() }
    Process {
        id: probe
        command: ["python3", Quickshell.shellPath("theme_tools.py"), "detect"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.terminals = JSON.parse(text); sync.restart(); }
                catch (e) { root.status = "Terminal detection needs Python 3.11 or newer."; }
            }
        }
    }
    Timer {
        id: sync
        interval: 350
        onTriggered: {
            if (!root.ready) return;
            root.borders();
            if (writer.running) { writer.pending = true; return; }
            const names = [];
            if (Settings.s.themeAlacritty && root.found("alacritty")) names.push("alacritty");
            if (Settings.s.themeKitty && root.found("kitty")) names.push("kitty");
            if (names.length === 0) return;
            writer.command = ["python3", Quickshell.shellPath("theme_tools.py"), "apply", root.palette].concat(names).concat(Settings.s.themeTerminalText ? [] : ["--keep-text"]);
            writer.running = true;
        }
    }
    Process {
        id: writer
        property bool pending: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    root.status = result.error || (result.errors.length ? result.errors.join(" · ")
                        : "Colours applied to " + result.applied.join(" and ") + (Settings.s.themeTerminalText ? ". Transparency preserved." : ". Text colours and transparency preserved."));
                } catch (e) { root.status = "Could not apply terminal colours."; }
            }
        }
        onExited: {
            if (pending) { pending = false; sync.restart(); }
        }
    }
}

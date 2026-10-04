pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The workspaces of every output, read from the file gluewc keeps up to date
// in its state dir ("name active workspace count,count,... layout", one line
// per output) and switched through gluewc-msg, which speaks the compositor's
// dwl-ipc protocol. Nothing here needs a Quickshell module that upstream does
// not ship, so the strip works on any distribution's quickshell.
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") !== ""
                                     && Quickshell.env("XDG_STATE_HOME") !== null
                                        ? Quickshell.env("XDG_STATE_HOME")
                                        : Quickshell.env("HOME") + "/.local/state") + "/gluewc"

    // output name -> { active, ws, counts, layout }
    property var outputs: ({})
    property bool available: false

    function outputFor(name) { return outputs[name] ?? null }

    function parse(text) {
        // gluewc writes in place: an event can arrive between truncate and
        // close. Keep the last complete snapshot instead of hiding the strip.
        if (!text.trim() || !text.endsWith("\n")) return false;
        const out = ({});
        for (const line of text.split("\n")) {
            if (!line.trim()) continue;
            const f = line.trim().split(" ");
            if (f.length < 4 || !/^[01]$/.test(f[1]) || !/^\d+$/.test(f[2])
                || !/^\d+(,\d+)*$/.test(f[3])) return false;
            out[f[0]] = {
                name: f[0],
                active: f[1] === "1",
                ws: parseInt(f[2]) || 0,
                counts: f[3].split(",").map(x => parseInt(x) || 0),
                layout: f[4] ?? "bsp"
            };
        }
        if (JSON.stringify(outputs) !== JSON.stringify(out)) outputs = out;
        available = Object.keys(out).length > 0;
        return true;
    }

    property int readRetries: 0
    Timer { id: readDelay; interval: 35; onTriggered: stateFile.reload() }
    function retryRead() {
        if (readRetries++ < 3) readDelay.restart();
    }
    FileView {
        id: stateFile
        path: root.stateDir + "/workspaces"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: { root.readRetries = 0; readDelay.restart(); }
        onLoaded: if (!root.parse(text())) root.retryRead()
        onLoadFailed: root.retryRead()
    }

    // gluewc-msg is installed next to the compositor; a prefix that is not on
    // PATH for the shell still works through the fallbacks
    readonly property var msgCandidates: ["gluewc-msg", "/usr/local/bin/gluewc-msg", "/usr/bin/gluewc-msg"]

    function view(output, n) {
        Quickshell.execDetached(["sh", "-c",
            "for m in gluewc-msg /usr/local/bin/gluewc-msg /usr/bin/gluewc-msg; do "
            + "command -v \"$m\" >/dev/null 2>&1 && exec \"$m\" -o \"$1\" workspace \"$2\"; done",
            "glueqs", output, String(n)]);
    }
}

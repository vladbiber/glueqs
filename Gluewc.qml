pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// gluewc's side of the shell: the compositor's config.conf, read and written
// line by line so comments and unknown keys survive, the shipped defaults for
// comparison, and the outputs state file the compositor keeps up to date.
// Nothing here appears unless the shell is actually running under gluewc.
Singleton {
    id: root

    function envOr(name, fallback) {
        const v = Quickshell.env(name);
        return v !== null && v !== undefined && v !== "" ? v : fallback;
    }
    readonly property string home: envOr("HOME", "")
    readonly property string configDir: envOr("XDG_CONFIG_HOME", home + "/.config")
    readonly property string stateDir: envOr("XDG_STATE_HOME", home + "/.local/state") + "/gluewc"
    readonly property string configPath: configDir + "/gluewc/config.conf"
    readonly property bool available: Quickshell.env("XDG_CURRENT_DESKTOP") === "gluewc"
                                      || WsState.available || outputsLoaded

    // ---- config.conf ----
    property var lines: []          // the file, one string per line
    property var values: ({})       // scalar key -> value, last assignment wins
    property var binds: []          // { mode, combo, action, line }
    property var macros: []         // { name, trigger, type, mode, ... line }
    property var autostarts: []     // { cmd, line }
    property var outputCfg: ({})    // output name -> { key: value }
    property var defaults: ({})     // scalars from config.def.conf
    property var defaultBinds: []   // { mode, combo, action } from config.def.conf
    property bool loaded: false
    readonly property string header: "# Written by glueqs"

    readonly property var scalarKeys: [
        "corner_radius", "blur", "blur_passes", "blur_radius", "opacity", "animations",
        "animation_duration", "animation_type_open", "animation_type_close",
        "animation_duration_open", "animation_duration_close", "zoom_initial_ratio",
        "zoom_end_ratio", "animation_curve_open", "animation_curve_close", "gap", "border",
        "border_focus", "border_normal", "normal_mode_color", "unfocused_borders",
        "root_color", "layout", "remember_layout", "start_in_overview", "drift_snap",
        "drift_nudge", "drift_zoom_min", "drift_zoom_max", "drift_zoom_step",
        "drift_pan_speed", "warp_pointer", "repeat_rate", "repeat_delay", "xkb_layout",
        "xkb_variant", "xkb_options"
    ]

    // "key = value" split at the first '=', or null for comments and blanks
    function splitLine(line) {
        const t = line.trim();
        if (t === "" || t.startsWith("#")) return null;
        const i = t.indexOf("=");
        if (i < 0) return null;
        return { key: t.slice(0, i).trim(), value: t.slice(i + 1).trim() };
    }

    function parseOutputTokens(s) {
        const parts = s.split(/\s+/).filter(x => x !== "");
        const name = parts.shift() ?? "";
        const kv = ({});
        for (const p of parts) {
            const i = p.indexOf("=");
            if (i > 0) kv[p.slice(0, i)] = p.slice(i + 1);
        }
        return { name: name, kv: kv };
    }

    function parseScalars(text) {
        const out = ({});
        for (const line of text.split("\n")) {
            const kv = splitLine(line);
            if (!kv) continue;
            if (["bind_insert", "bind_normal", "autostart", "output", "macro"].includes(kv.key)) continue;
            out[kv.key] = kv.value;
        }
        return out;
    }
    function parseBinds(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const kv = splitLine(line);
            if (!kv || (kv.key !== "bind_insert" && kv.key !== "bind_normal")) continue;
            const j = kv.value.indexOf("=");
            if (j < 0) continue;
            out.push({ mode: kv.key === "bind_insert" ? "insert" : "normal",
                       combo: kv.value.slice(0, j).trim(), action: kv.value.slice(j + 1).trim() });
        }
        return out;
    }
    function defaultBind(mode, combo) {
        return defaultBinds.find(b => b.mode === mode && b.combo === combo) ?? null;
    }

    function parseMacro(value, line) {
        const parts = value.split(/\s+/).filter(x => x !== "");
        if (parts.length === 0) return null;
        const m = ({ name: parts.shift(), trigger: "", type: "sequence", mode: "hold",
                    button: "left", cps: 10, interval: 80, press: 10,
                    sequence: "q,p,o,space", line: line });
        for (const p of parts) {
            const i = p.indexOf("=");
            if (i <= 0) continue;
            const k = p.slice(0, i), v = p.slice(i + 1);
            if (["trigger", "type", "mode", "button", "sequence"].includes(k)) m[k] = v;
            else if (["cps", "interval", "press"].includes(k)) {
                const n = parseInt(v);
                if (!isNaN(n)) m[k] = n;
            }
        }
        return m;
    }

    function parse(text) {
        const ls = text.split("\n");
        if (ls.length > 0 && ls[ls.length - 1] === "") ls.pop();
        const vals = ({}), bs = [], ms = [], as = [], oc = ({});
        for (let n = 0; n < ls.length; n++) {
            const kv = splitLine(ls[n]);
            if (!kv) continue;
            if (kv.key === "macro") {
                const m = parseMacro(kv.value, n);
                if (m) ms.push(m);
            } else if (kv.key === "bind_insert" || kv.key === "bind_normal") {
                const j = kv.value.indexOf("=");
                if (j < 0) continue;
                bs.push({ mode: kv.key === "bind_insert" ? "insert" : "normal",
                          combo: kv.value.slice(0, j).trim(),
                          action: kv.value.slice(j + 1).trim(), line: n });
            } else if (kv.key === "autostart") {
                as.push({ cmd: kv.value, line: n });
            } else if (kv.key === "output") {
                const o = parseOutputTokens(kv.value);
                if (o.name === "") continue;
                const cur = oc[o.name] ?? ({});
                for (const k in o.kv) cur[k] = o.kv[k];
                oc[o.name] = cur;
            } else {
                vals[kv.key] = kv.value;
            }
        }
        lines = ls;
        values = vals;
        binds = bs;
        macros = ms;
        autostarts = as;
        outputCfg = oc;
        loaded = true;
    }

    FileView {
        id: cfg
        path: root.configPath
        watchChanges: true
        preload: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.parse("")
    }

    // edits land in memory first, then in the file a moment later, so a burst
    // of changes is one write and one compositor reload
    Timer {
        id: flush
        interval: 150
        onTriggered: cfg.setText(root.lines.join("\n") + "\n")
    }
    function commit(ls) {
        if (!loaded) return;
        parse(ls.join("\n"));
        flush.restart();
    }

    function appendUnderHeader(ls, newLines) {
        if (!ls.includes(header)) {
            if (ls.length > 0 && ls[ls.length - 1].trim() !== "") ls.push("");
            ls.push(header);
        }
        for (const l of newLines) ls.push(l);
    }

    // ---- scalars ----
    function get(key) { return values[key] ?? defaults[key] ?? "" }
    function getBool(key) { const v = get(key); return v === "true" || v === "1" }
    function getNum(key) { const v = parseFloat(get(key)); return isNaN(v) ? 0 : v }
    function hasDefault(key) { return defaults[key] !== undefined }
    function isDefault(key) { return values[key] === undefined || values[key] === defaults[key] }

    function set(key, value) {
        const ls = lines.slice();
        let last = -1;
        for (let n = 0; n < ls.length; n++) {
            const kv = splitLine(ls[n]);
            if (kv && kv.key === key) last = n;
        }
        if (last >= 0) {
            const eq = ls[last].indexOf("=");
            ls[last] = ls[last].slice(0, eq + 1) + " " + value;
        } else {
            appendUnderHeader(ls, [key + " = " + value]);
        }
        commit(ls);
    }
    function reset(key) {
        if (defaults[key] === undefined) return;
        set(key, defaults[key]);
    }

    // ---- autostart ----
    function setAutostarts(cmds) {
        const ls = lines.slice();
        const at = autostarts.map(a => a.line);
        const fresh = cmds.map(c => "autostart = " + c);
        for (let i = 0; i < at.length && i < fresh.length; i++) ls[at[i]] = fresh[i];
        if (at.length > fresh.length) {
            for (let i = at.length - 1; i >= fresh.length; i--) ls.splice(at[i], 1);
        } else if (fresh.length > at.length) {
            const rest = fresh.slice(at.length);
            if (at.length > 0) ls.splice(at[at.length - 1] + 1, 0, ...rest);
            else appendUnderHeader(ls, rest);
        }
        commit(ls);
    }

    // ---- binds ----
    function bindLine(mode, combo, action) {
        return (mode === "normal" ? "bind_normal" : "bind_insert") + " = " + combo + " = " + action;
    }
    function setBind(mode, combo, action) {
        const ls = lines.slice();
        const b = binds.find(x => x.mode === mode && x.combo === combo);
        if (b) ls[b.line] = bindLine(mode, combo, action);
        else {
            const same = binds.filter(x => x.mode === mode);
            if (same.length > 0) ls.splice(same[same.length - 1].line + 1, 0, bindLine(mode, combo, action));
            else appendUnderHeader(ls, [bindLine(mode, combo, action)]);
        }
        commit(ls);
    }
    function removeBind(mode, combo) {
        const b = binds.find(x => x.mode === mode && x.combo === combo);
        if (!b) return;
        const ls = lines.slice();
        ls.splice(b.line, 1);
        commit(ls);
    }

    // ---- macros ----
    function safeMacroName(name) {
        let out = name.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, "_");
        out = out.replace(/^_+|_+$/g, "");
        return out === "" ? "macro" : out;
    }
    function macroLine(m) {
        let s = "macro = " + safeMacroName(m.name)
              + " trigger=" + m.trigger
              + " type=" + m.type
              + " mode=" + m.mode
              + " press=" + Math.max(1, Math.round(m.press));
        if (m.type === "click")
            s += " button=" + m.button + " cps=" + Math.max(1, Math.round(m.cps));
        else
            s += " interval=" + Math.max(0, Math.round(m.interval))
              + " sequence=" + String(m.sequence).replace(/\s+/g, "");
        return s;
    }
    function setMacro(originalName, macro) {
        const ls = lines.slice();
        const old = macros.find(m => m.name === originalName);
        const fresh = macroLine(macro);
        if (old) ls[old.line] = fresh;
        else {
            const same = macros;
            if (same.length > 0) ls.splice(same[same.length - 1].line + 1, 0, fresh);
            else appendUnderHeader(ls, [fresh]);
        }
        commit(ls);
    }
    function removeMacro(name) {
        const m = macros.find(x => x.name === name);
        if (!m) return;
        const ls = lines.slice();
        ls.splice(m.line, 1);
        commit(ls);
    }

    // ---- outputs (config side) ----
    readonly property var outputKeyOrder: ["mode", "pos", "scale", "transform", "enabled", "mirror", "adaptive_sync"]
    function outputLine(name, kv) {
        let s = "output = " + name;
        const keys = Object.keys(kv).sort((a, b) => {
            const ia = outputKeyOrder.indexOf(a), ib = outputKeyOrder.indexOf(b);
            return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib);
        });
        for (const k of keys) s += " " + k + "=" + kv[k];
        return s;
    }
    // patch values of null drop the key; the line is rewritten whole
    function setOutput(name, patch) {
        setOutputs([{ name: name, patch: patch }]);
    }
    function setOutputs(changes) {
        const ls = lines.slice();
        const oc = ({});
        for (const n in outputCfg) oc[n] = Object.assign({}, outputCfg[n]);
        for (const c of changes) {
            const kv = oc[c.name] ?? ({});
            for (const k in c.patch) {
                if (c.patch[k] === null || c.patch[k] === undefined) delete kv[k];
                else kv[k] = String(c.patch[k]);
            }
            oc[c.name] = kv;
        }
        for (const c of changes) {
            const fresh = outputLine(c.name, oc[c.name]);
            const at = [];
            for (let n = 0; n < ls.length; n++) {
                const kv = splitLine(ls[n]);
                if (kv && kv.key === "output" && parseOutputTokens(kv.value).name === c.name) at.push(n);
            }
            if (Object.keys(oc[c.name]).length === 0) {
                for (let i = at.length - 1; i >= 0; i--) ls.splice(at[i], 1);
            } else if (at.length === 0) {
                appendUnderHeader(ls, [fresh]);
            } else {
                ls[at[0]] = fresh;
                for (let i = at.length - 1; i > 0; i--) ls.splice(at[i], 1);
            }
        }
        commit(ls);
    }
    function outputLines() {
        return lines.filter(l => { const kv = splitLine(l); return kv && kv.key === "output" });
    }
    function restoreOutputLines(saved) {
        const ls = lines.filter(l => { const kv = splitLine(l); return !(kv && kv.key === "output") });
        if (saved.length > 0) appendUnderHeader(ls, saved);
        commit(ls);
    }

    // ---- 15 s trial for risky monitor changes ----
    property var trialSaved: null
    property int trialLeft: 0
    readonly property bool trialActive: trialSaved !== null
    function beginTrial() {
        if (trialSaved === null) trialSaved = outputLines();
        trialLeft = 15;
        trialTick.restart();
    }
    function keepTrial() { trialSaved = null; trialTick.stop(); }
    function revertTrial() {
        if (trialSaved === null) return;
        const saved = trialSaved;
        trialSaved = null;
        trialTick.stop();
        restoreOutputLines(saved);
    }
    Timer {
        id: trialTick
        interval: 1000; repeat: true
        onTriggered: {
            root.trialLeft -= 1;
            if (root.trialLeft <= 0) root.revertTrial();
        }
    }

    // ---- shipped defaults ----
    Process {
        id: defProc
        running: true
        command: ["sh", "-c",
            'for f in "${GLUEWC_DATADIR:-/nonexistent}/config.def.conf" /usr/local/share/gluewc/config.def.conf /usr/share/gluewc/config.def.conf; do [ -r "$f" ] && { cat "$f"; exit 0; }; done; exit 1']
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaults = root.parseScalars(text);
                root.defaultBinds = root.parseBinds(text);
            }
        }
    }

    // ---- outputs state file ----
    property var outputs: []
    property bool outputsLoaded: false

    function parseOutputs(text) {
        const out = [];
        for (const line of text.split("\n")) {
            if (line.trim() === "") continue;
            const o = ({ name: "", enabled: false, x: 0, y: 0, w: 0, h: 0, pw: 0, ph: 0, hz: 0,
                         scale: 1, transform: "normal", mirror: "none", focused: false,
                         make: "none", model: "none", serial: "none", preferred: "none", modes: [] });
            for (const f of line.split("\t")) {
                const i = f.indexOf("=");
                if (i < 0) continue;
                const k = f.slice(0, i), v = f.slice(i + 1);
                switch (k) {
                case "enabled": case "focused": o[k] = v === "1"; break;
                case "x": case "y": case "w": case "h": case "pw": case "ph": o[k] = parseInt(v) || 0; break;
                case "hz": case "scale": o[k] = parseFloat(v) || 0; break;
                case "modes": o.modes = v === "" ? [] : v.split(","); break;
                default: o[k] = v;
                }
            }
            if (o.name !== "") out.push(o);
        }
        outputs = out;
        outputsLoaded = out.length > 0;
    }
    function output(name) { return outputs.find(o => o.name === name) ?? null }
    function isMirror(name) { const o = output(name); return o !== null && o.mirror !== "none" }
    // mirrors and disabled outputs get no shell windows
    function isPassive(name) { const o = output(name); return o !== null && (o.mirror !== "none" || !o.enabled) }
    function focusedOutput() {
        return outputs.find(o => o.focused && o.enabled) ?? outputs.find(o => o.enabled) ?? null;
    }

    FileView {
        path: root.stateDir + "/outputs"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseOutputs(text())
        onLoadFailed: { root.outputs = []; root.outputsLoaded = false; }
    }

    // ---- identify: every screen shows its name for a moment ----
    property bool identifying: false
    function identify() { identifying = true; identifyTimer.restart(); }
    Timer { id: identifyTimer; interval: 2200; onTriggered: root.identifying = false }
}

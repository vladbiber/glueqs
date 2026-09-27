pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Backlight level from /sys/class/backlight. The kernel emits a udev change
// event on every write to the device, including the brightnessctl calls the
// compositor spawns on its brightness keys, so this stays in sync without
// polling.
Singleton {
    id: root

    // GLUEQS_BACKLIGHT_DIR points at a fake sysfs tree for tests
    readonly property string base: (Quickshell.env("GLUEQS_BACKLIGHT_DIR") ?? "") !== ""
                                   ? Quickshell.env("GLUEQS_BACKLIGHT_DIR") : "/sys/class/backlight"
    readonly property bool fake: base !== "/sys/class/backlight"
    property string device: ""
    // what set() writes through: brightnessctl, light, sysfs, or nothing
    property string writer: ""
    property int max: 0
    property int raw: 0
    // level and percent are assigned, not bound: the OSD reads them from the
    // osdTrigger handler, which runs before bindings on raw get to re-evaluate
    property real level: 0
    property int percent: 0
    readonly property bool available: device !== "" && max > 0

    signal osdTrigger()

    // suppress the OSD during startup while the initial level lands
    property bool ready: false
    Timer { running: true; interval: 2000; onTriggered: root.ready = true }

    // keyboard backlights live under /sys/class/leds, so whatever is here is
    // the panel; take the first one
    Process {
        running: true
        command: ["sh", "-c", 'ls -1 "$1" 2>/dev/null | head -1', "glueqs", root.base]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim();
                if (d !== "") root.device = d;
            }
        }
    }

    // pick the writer once the device is known; the fake tree is always sysfs
    Process {
        running: root.device !== ""
        command: ["sh", "-c",
            'if [ -n "$3" ]; then echo sysfs; elif command -v brightnessctl >/dev/null 2>&1; then echo brightnessctl; '
            + 'elif command -v light >/dev/null 2>&1; then echo light; elif [ -w "$1/$2/brightness" ]; then echo sysfs; fi',
            "glueqs", root.base, root.device, root.fake ? "1" : ""]
        stdout: StdioCollector { onStreamFinished: root.writer = text.trim() }
    }

    readonly property bool canSet: writer !== ""

    // percent 0..100; 0 switches the panel off, the brightness keys bring it back
    function set(percent) {
        if (!available || !canSet) return;
        const p = Math.max(0, Math.min(100, Math.round(percent)));
        const rawv = Math.round(p / 100 * root.max);
        setter.command = ["sh", "-c",
            'case "$1" in brightnessctl) brightnessctl -q -d "$3" set "$2%" ;; light) light -S "$2" ;; '
            + 'sysfs) printf %s "$4" > "$5/$3/brightness" && { [ -n "$6" ] && printf %s "$4" > "$5/$3/actual_brightness"; :; } ;; esac',
            "glueqs", writer, String(p), device, String(rawv), base, fake ? "1" : ""];
        setter.running = true;
    }
    Process {
        id: setter
        onExited: curFile.reload()
    }

    FileView {
        id: maxFile
        path: root.device === "" ? "" : root.base + "/" + root.device + "/max_brightness"
        preload: true
        printErrors: false
        onLoaded: {
            root.max = parseInt(text()) || 0;
            curFile.reload();
        }
    }

    // actual_brightness is what the panel settled on, which is what the OSD
    // should report. The value is taken in onLoaded because reload() is
    // asynchronous: reading text() straight after it hands back the previous
    // contents, which left the OSD a step behind every keypress.
    FileView {
        id: curFile
        path: root.device === "" ? "" : root.base + "/" + root.device + "/actual_brightness"
        preload: true
        watchChanges: root.fake
        onFileChanged: reload()
        printErrors: false
        onLoaded: root.apply(parseInt(text()) || 0)
    }

    function apply(v) {
        if (root.max <= 0)
            return;
        const changed = v !== root.raw;
        root.raw = v;
        root.level = v / root.max;
        root.percent = Math.round(root.level * 100);
        if (changed && root.ready && root.available)
            osdTrigger();
    }

    Process {
        running: !root.fake
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => { if (line.indexOf("change") >= 0) curFile.reload(); }
        }
    }
}

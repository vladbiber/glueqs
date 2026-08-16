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

    property string device: ""
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
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim();
                if (d !== "") root.device = d;
            }
        }
    }

    FileView {
        id: maxFile
        path: root.device === "" ? "" : "/sys/class/backlight/" + root.device + "/max_brightness"
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
        path: root.device === "" ? "" : "/sys/class/backlight/" + root.device + "/actual_brightness"
        preload: true
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
        running: true
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => { if (line.indexOf("change") >= 0) curFile.reload(); }
        }
    }
}

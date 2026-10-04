pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU, memory, temperature and disk use, sampled every 2 s while a bar tile
// shows one of them.
Singleton {
    id: root
    property int users: 0
    function acquire() { users++ }
    function release() { users = Math.max(0, users - 1) }

    property real cpu: 0      // 0..1
    property real ram: 0      // 0..1
    property real ramUsedGb: 0
    property int temp: -1     // °C, -1 unknown
    property real disk: 0     // 0..1 of /
    property real lastBusy: -1
    property real lastTotal: -1

    Process {
        id: rd
        // one shot for everything: stat line, meminfo, hottest cpu-ish zone, df
        command: ["sh", "-c",
            "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; "
            + "t=''; for z in /sys/class/thermal/thermal_zone*; do case $(cat $z/type 2>/dev/null) in x86_pkg_temp|cpu*|k10temp|coretemp|soc*) t=$(cat $z/temp); break;; esac; done; "
            + "[ -z \"$t\" ] && t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); echo \"temp $t\"; "
            + "df -P / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0, avail = 0;
                for (const line of text.split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f[0] === "cpu") {
                        const n = f.slice(1).map(x => parseInt(x) || 0);
                        const idle = n[3] + (n[4] ?? 0);
                        const all = n.reduce((a, b) => a + b, 0);
                        if (root.lastTotal >= 0 && all > root.lastTotal)
                            root.cpu = Math.max(0, Math.min(1, 1 - (idle - root.lastBusy) / (all - root.lastTotal)));
                        root.lastBusy = idle; root.lastTotal = all;
                    } else if (f[0] === "MemTotal:") total = parseInt(f[1]);
                    else if (f[0] === "MemAvailable:") avail = parseInt(f[1]);
                    else if (f[0] === "temp") root.temp = f[1] ? Math.round(parseInt(f[1]) / 1000) : -1;
                    else if (f.length >= 6 && f[4]?.endsWith("%")) root.disk = (parseInt(f[4]) || 0) / 100;
                }
                if (total > 0) { root.ram = 1 - avail / total; root.ramUsedGb = (total - avail) / 1048576; }
            }
        }
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.users > 0
        onTriggered: rd.running = true
    }
}

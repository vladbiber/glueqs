pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wifi and bluetooth through nmcli/bluetoothctl. The bar state is polled every
// 10s; the network list, connection details and the bluetooth devices are
// only scanned while a view is on screen (acquire/release), and are shared by
// the bar popup and the settings page.
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property int wifiSignal: 0
    property bool btPowered: false
    property int btConnected: 0
    readonly property bool airplane: !wifiEnabled && !btPowered

    // ---- detail, while watched ----
    property int users: 0
    readonly property bool watched: users > 0
    function acquire() { users++; if (users === 1) scanAll(); }
    function release() { users = Math.max(0, users - 1) }

    property var nets: []          // { ssid, signal, secured, security, inUse, saved, band, chan }
    property var saved: []
    property string iface: ""
    property string ssid: ""
    property string ip: ""
    property string gateway: ""
    property string band: ""
    property int chan: 0
    property bool wifiScanning: false

    property var btDevs: []        // { mac, name, icon, paired, connected, battery }
    property bool btScanning: false
    property string btBusy: ""

    property string busySsid: ""
    property string passSsid: ""   // the network asking for a password
    property string status: ""
    property string statusSsid: ""

    function scanAll() { poll.running = true; scan.running = true; info.running = true; bt.running = true; }

    Process {
        id: poll
        command: ["env", "LC_ALL=C", "sh", "-c",
            "echo \"WIFI:$(nmcli -t -f WIFI g 2>/dev/null)\";" +
            "echo \"SIG:$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\\\"yes\\\"{print $2; exit}')\";" +
            "echo \"BT:$(timeout 2 bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}')\";" +
            "echo \"BTN:$(timeout 2 bluetoothctl devices Connected 2>/dev/null | grep -c ^Device)\""]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("WIFI:")) root.wifiEnabled = line.slice(5) === "enabled";
                else if (line.startsWith("SIG:")) {
                    const s = line.slice(4);
                    root.wifiConnected = s !== "";
                    root.wifiSignal = parseInt(s) || 0;
                } else if (line.startsWith("BT:")) root.btPowered = line.slice(3) === "yes";
                else if (line.startsWith("BTN:")) root.btConnected = parseInt(line.slice(4)) || 0;
            }
        }
    }

    function refresh() { poll.running = true; if (watched) scanAll(); }

    Timer {
        running: true; repeat: true; interval: root.watched ? 5000 : 10000
        onTriggered: { poll.running = true; if (root.watched) { scan.running = true; info.running = true; bt.running = true; } }
    }

    // ---- wifi list ----
    Process {
        id: scan
        // SSID last: it is the only field that may hold (escaped) colons
        command: ["env", "LC_ALL=C", "sh", "-c",
            "nmcli -t -f NAME,TYPE con show 2>/dev/null | awk -F: '$2==\"802-11-wireless\"{print \"S:\" $1}';" +
            "nmcli -t -f IN-USE,SIGNAL,SECURITY,CHAN,FREQ,SSID dev wifi list 2>/dev/null | sed 's/^/N:/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = [];
                const seen = {};
                for (const raw of text.split("\n")) {
                    if (raw.startsWith("S:")) { saved.push(raw.slice(2).replace(/\\:/g, ":")); continue; }
                    if (!raw.startsWith("N:")) continue;
                    const line = raw.slice(2);
                    const f = [];
                    let at = 0;
                    for (let k = 0; k < 5; k++) {
                        const i = line.indexOf(":", at);
                        if (i < 0) break;
                        f.push(line.slice(at, i));
                        at = i + 1;
                    }
                    if (f.length < 5) continue;
                    const ssid = line.slice(at).replace(/\\:/g, ":").trim();
                    if (!ssid) continue;
                    const mhz = parseInt(f[4]) || 0;
                    const e = {
                        inUse: f[0] === "*",
                        signal: parseInt(f[1]) || 0,
                        security: f[2] === "--" ? "" : f[2],
                        secured: f[2] !== "" && f[2] !== "--",
                        chan: parseInt(f[3]) || 0,
                        band: mhz >= 5900 ? "6G" : mhz >= 4900 ? "5G" : "2.4G",
                        ssid: ssid
                    };
                    if (!(ssid in seen) || e.inUse || (!seen[ssid].inUse && e.signal > seen[ssid].signal))
                        seen[ssid] = e;
                }
                const list = Object.values(seen);
                for (const n of list) n.saved = saved.indexOf(n.ssid) >= 0;
                list.sort((a, b) => (b.inUse - a.inUse) || (b.saved - a.saved) || (b.signal - a.signal));
                root.saved = saved;
                root.nets = list;
                // the scan knows the network in use even when the poll lags
                const cur = list.find(n => n.inUse);
                if (cur) {
                    root.wifiEnabled = true; root.wifiConnected = true; root.wifiSignal = cur.signal;
                    root.ssid = cur.ssid; root.band = cur.band; root.chan = cur.chan;
                }
            }
        }
    }
    Process {
        id: info
        command: ["env", "LC_ALL=C", "sh", "-c",
            "d=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'); echo \"D:$d\";" +
            "[ -n \"$d\" ] || exit 0;" +
            "echo \"C:$(nmcli -t -g GENERAL.CONNECTION dev show \"$d\" 2>/dev/null)\";" +
            "echo \"I:$(nmcli -t -g IP4.ADDRESS dev show \"$d\" 2>/dev/null | head -1)\";" +
            "echo \"G:$(nmcli -t -g IP4.GATEWAY dev show \"$d\" 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = "", c = "", ip = "", gw = "";
                for (const l of text.split("\n")) {
                    if (l.startsWith("D:")) d = l.slice(2);
                    else if (l.startsWith("C:")) c = l.slice(2);
                    else if (l.startsWith("I:")) ip = l.slice(2).split("|")[0];
                    else if (l.startsWith("G:")) gw = l.slice(2);
                }
                root.iface = d; root.ip = ip.replace(/\/\d+$/, ""); root.gateway = gw;
                // the profile name is only a stand-in until a scan names the network
                if (c === "") { root.ssid = ""; root.band = ""; root.chan = 0; }
                else if (root.ssid === "") root.ssid = c;
            }
        }
    }

    function rescan() {
        wifiScanning = true;
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
        rescanDone.restart();
    }
    Timer { id: rescanDone; interval: 3500; onTriggered: { root.wifiScanning = false; scan.running = true; } }

    function setWifi(on) { Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]); soon.restart(); }
    function setBt(on) {
        Quickshell.execDetached(["sh", "-c", "timeout 5 bluetoothctl power " + (on ? "on" : "off")]);
        soon.restart();
    }
    function setAirplane(on) {
        Quickshell.execDetached(["sh", "-c", "nmcli radio all " + (on ? "off" : "on")
            + "; timeout 5 bluetoothctl power " + (on ? "off" : "on")]);
        soon.restart();
    }
    Timer { id: soon; interval: 1500; onTriggered: root.refresh() }

    // ---- connect ----
    Process {
        id: connectProc
        property string ssid: ""
        property bool hadPassword: false
        stderr: StdioCollector { id: connErr }
        onExited: (code, st) => {
            root.busySsid = "";
            root.statusSsid = ssid;
            if (code === 0) {
                root.status = "CONNECTED";
                root.passSsid = "";
            } else {
                const err = connErr.text.toLowerCase();
                if (!hadPassword && (err.includes("secrets") || err.includes("password")
                                     || err.includes("802.1x") || err.includes("no network"))) {
                    root.passSsid = ssid;
                    root.status = "PASSWORD";
                } else {
                    root.status = hadPassword ? "WRONG PASSWORD?" : "FAILED";
                    if (hadPassword) root.passSsid = ssid;
                }
            }
            root.refresh();
        }
    }
    function connect(ssid, password) {
        if (busySsid !== "") return;
        const n = nets.find(x => x.ssid === ssid);
        // an open or saved network goes straight; a new secured one asks first
        if (password === "" && n && n.secured && !n.saved) {
            passSsid = ssid; status = "PASSWORD"; statusSsid = ssid;
            return;
        }
        busySsid = ssid;
        status = "CONNECTING"; statusSsid = ssid;
        connectProc.ssid = ssid;
        connectProc.hadPassword = password !== "";
        connectProc.command = password === ""
            ? ["nmcli", "dev", "wifi", "connect", ssid]
            : ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        connectProc.running = true;
    }
    function cancelPassword() { passSsid = ""; if (status === "PASSWORD") status = ""; }
    function disconnect() {
        if (iface !== "") Quickshell.execDetached(["nmcli", "dev", "disconnect", iface]);
        status = ""; soon.restart();
    }
    function forget(ssid) {
        Quickshell.execDetached(["nmcli", "con", "delete", "id", ssid]);
        status = ""; soon.restart();
    }

    // ---- bluetooth ----
    Process {
        id: bt
        command: ["env", "LC_ALL=C", "sh", "-c",
            "timeout 2 bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
            "  timeout 2 bluetoothctl info \"$mac\" 2>/dev/null | awk -v m=\"$mac\" -v n=\"$name\" '" +
            "    /Icon:/{ic=$2} /Paired:/{p=$2} /Connected:/{c=$2}" +
            "    /Battery Percentage:/{gsub(/[()]/,\"\",$4); b=$4}" +
            "    END{printf \"%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n\", m, ic, p, c, b, n}';" +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of text.split("\n")) {
                    const f = l.split("\t");
                    if (f.length < 6 || !/^[0-9A-F:]{17}$/i.test(f[0])) continue;
                    out.push({ mac: f[0], icon: f[1], paired: f[2] === "yes", connected: f[3] === "yes",
                               battery: f[4] === "" ? -1 : parseInt(f[4]), name: f[5] || f[0] });
                }
                out.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
                root.btDevs = out;
            }
        }
    }
    Process {
        id: btDiscover
        command: ["sh", "-c", "timeout 14 bluetoothctl --timeout 12 scan on >/dev/null 2>&1"]
        onRunningChanged: root.btScanning = running
        onExited: bt.running = true
    }
    Timer { running: root.btScanning; repeat: true; interval: 2500; onTriggered: bt.running = true }
    function btScan() { if (btPowered && !btDiscover.running) btDiscover.running = true }

    Process {
        id: btAct
        onExited: { root.btBusy = ""; bt.running = true; poll.running = true; }
    }
    function btRun(mac, script) {
        if (btBusy !== "") return;
        btBusy = mac;
        btAct.command = ["sh", "-c", script, "glueqs", mac];
        btAct.running = true;
    }
    function btToggle(dev) {
        if (!dev.paired)
            btRun(dev.mac, 'timeout 20 bluetoothctl pair "$1"; timeout 5 bluetoothctl trust "$1"; timeout 12 bluetoothctl connect "$1"');
        else
            btRun(dev.mac, 'timeout 12 bluetoothctl ' + (dev.connected ? "disconnect" : "connect") + ' "$1"');
    }
    function btForget(dev) { btRun(dev.mac, 'timeout 8 bluetoothctl remove "$1"') }

    function btIcon(icon) {
        if (/audio|head/.test(icon)) return "headset";
        if (/phone/.test(icon)) return "phone";
        if (/keyboard/.test(icon)) return "keyboard";
        if (/mouse|tablet/.test(icon)) return "mouse";
        if (/computer/.test(icon)) return "laptop";
        if (/game|joy/.test(icon)) return "pad";
        return "bt";
    }
}

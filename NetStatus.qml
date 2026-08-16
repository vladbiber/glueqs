pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Polls nmcli/bluetoothctl every 10s for wifi + bluetooth state.
Singleton {
    id: root

    property bool wifiEnabled: false
    property bool wifiConnected: false
    property int wifiSignal: 0
    property bool btPowered: false
    property int btConnected: 0

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

    function refresh() { poll.running = true }

    Timer {
        running: true; repeat: true; interval: 10000
        onTriggered: poll.running = true
    }
}

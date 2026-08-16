import QtQuick
import Quickshell.Io

// Download/upload rate from /proc/net/dev, sampled every 2s.
Block {
    id: root

    property real lastRx: -1
    property real lastTx: -1
    property real lastTime: 0
    property real rxRate: 0
    property real txRate: 0

    function fmt(bps) {
        const k = bps / 1024;
        if (k < 1000) return Math.round(k) + "K";
        return (k / 1024).toFixed(1) + "M";
    }

    Process {
        id: rd
        command: ["cat", "/proc/net/dev"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0;
                for (const line of text.split("\n")) {
                    const m = line.trim().split(/[:\s]+/);
                    if (m.length < 10 || !line.includes(":") || m[0] === "lo") continue;
                    rx += parseInt(m[1]) || 0;
                    tx += parseInt(m[9]) || 0;
                }
                const now = Date.now();
                if (root.lastRx >= 0 && now > root.lastTime) {
                    const dt = (now - root.lastTime) / 1000;
                    root.rxRate = Math.max(0, (rx - root.lastRx) / dt);
                    root.txRate = Math.max(0, (tx - root.lastTx) / dt);
                }
                root.lastRx = rx; root.lastTx = tx; root.lastTime = now;
            }
        }
    }
    Timer {
        running: true; repeat: true; interval: 2000
        onTriggered: rd.running = true
    }

    Grid {
        columns: 1

    Column {
            visible: !Theme.vertical
            spacing: 3

            Row {
                spacing: 5
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "down"; px: 1; gap: 0.9
                    color: root.rxRate > 2048 ? Theme.fg : Theme.dim
                }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fmt(root.rxRate)
                    px: 1; gap: 0.9
                    color: root.rxRate > 2048 ? Theme.fg : Theme.dim
                }
            }
            Row {
                spacing: 5
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "up"; px: 1; gap: 0.9
                    color: root.txRate > 2048 ? Theme.fg : Theme.dim
                }
                DotText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fmt(root.txRate)
                    px: 1; gap: 0.9
                    color: root.txRate > 2048 ? Theme.fg : Theme.dim
                }
            }
        }

        Column {
            visible: Theme.vertical
            spacing: 2

            DotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "down"; px: 0.9; gap: 0.8
                color: root.rxRate > 2048 ? Theme.fg : Theme.dim
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.fmt(root.rxRate)
                px: 0.8; gap: 0.8
                color: root.rxRate > 2048 ? Theme.fg : Theme.dim
            }
            DotIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "up"; px: 0.9; gap: 0.8
                color: root.txRate > 2048 ? Theme.fg : Theme.dim
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.fmt(root.txRate)
                px: 0.8; gap: 0.8
                color: root.txRate > 2048 ? Theme.fg : Theme.dim
            }
        }
    }
}

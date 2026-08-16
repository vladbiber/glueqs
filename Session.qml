pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property bool panelOpen: false

    readonly property var actions: [
        { label: "LOGOUT",    cmd: ["pkill", "-x", "gluewc"],  danger: false },
        { label: "REBOOT",    cmd: ["loginctl", "reboot"],     danger: false },
        { label: "POWER OFF", cmd: ["loginctl", "poweroff"],   danger: true }
    ]

    function run(cmd) {
        Quickshell.execDetached(cmd);
    }
}

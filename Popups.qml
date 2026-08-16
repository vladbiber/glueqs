pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which bar popup is open: "", "calendar", "net", "launcher", "weather",
// "battery", "settings". The settings tab lives here too so it is shared
// between screens and can be aimed from outside over IPC.
Singleton {
    id: root
    property string open: ""
    property int settingsTab: 0

    function toggle(name) {
        open = (open === name) ? "" : name;
    }

    // qs -c glueqs ipc call glueqs wallpaper
    IpcHandler {
        target: "glueqs"

        function wallpaper(): void {
            root.settingsTab = 4;
            root.open = root.open === "settings" ? "" : "settings";
        }

        function settings(): void {
            root.toggle("settings");
        }

        function close(): void {
            root.open = "";
        }
    }
}

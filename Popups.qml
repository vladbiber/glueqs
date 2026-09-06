pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Which bar popup is open: "", "calendar", "net", "launcher", "weather",
// "battery", "settings", "wallpaper". The settings tab lives here too so it
// is shared between screens and can be aimed from outside over IPC.
Singleton {
    id: root
    property string open: ""
    property int settingsTab: 0

    function toggle(name) {
        open = (open === name) ? "" : name;
    }

    // qs -c glueqs ipc call glueqs wallpaper           toggle the picker
    // qs -c glueqs ipc call glueqs setwallpaper PATH   put PATH on every screen
    // qs -c glueqs ipc call glueqs nextwallpaper       next file in the folder
    // qs -c glueqs ipc call glueqs randomwallpaper     a random one
    IpcHandler {
        target: "glueqs"

        function wallpaper(): void {
            root.toggle("wallpaper");
        }

        function setwallpaper(path: string): void {
            Wallpapers.set(path, "");
        }

        function nextwallpaper(): void {
            Wallpapers.next("");
        }

        function randomwallpaper(): void {
            Wallpapers.random("");
        }

        function settings(): void {
            root.toggle("settings");
        }

        function close(): void {
            root.open = "";
        }
    }
}

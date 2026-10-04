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
    property int gluewcPage: 0
    signal settingsScroll(int y)

    function toggle(name) {
        open = (open === name) ? "" : name;
    }

    // qs -c glueqs ipc call glueqs wallpaper           toggle the picker
    // qs -c glueqs ipc call glueqs setwallpaper PATH   put PATH on every screen
    // qs -c glueqs ipc call glueqs nextwallpaper       next file in the folder
    // qs -c glueqs ipc call glueqs randomwallpaper     a random one
    IpcHandler {
        target: "glueqs"

        function themeinfo(): string {
            return JSON.stringify({ scheme: Settings.s.themeScheme, palette: Theme.p,
                wallpaper: Theme.wallPath, style: Settings.s.wallpaperSchemeType,
                ready: Theme.wallReady, error: Theme.wallError, seeds: Theme.wallSeeds,
                terminals: ThemeSync.terminals, terminalStatus: ThemeSync.status,
                syncText: Settings.s.themeTerminalText, syncBorders: Settings.s.themeWindowBorders,
                workspaces: WsState.outputs });
        }

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

        // qs -c glueqs ipc call glueqs settingspage 2      straight to a page
        function settingspage(page: int): void {
            root.settingsTab = page;
            root.open = "settings";
        }

        // qs -c glueqs ipc call glueqs gluewc          the compositor settings
        // qs -c glueqs ipc call glueqs gluewcpage 6    straight to a page
        // qs -c glueqs ipc call glueqs settingsscroll 600   scroll the open page
        function settingsscroll(y: int): void {
            root.settingsScroll(y);
        }

        function gluewc(): void {
            root.toggle("gluewc");
        }

        function gluewcpage(page: int): void {
            root.gluewcPage = page;
            root.open = "gluewc";
        }

        function close(): void {
            root.open = "";
        }
    }
}

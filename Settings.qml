pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Persistent shell settings, stored next to the config as settings.json.
Singleton {
    id: root
    readonly property var s: json

    FileView {
        path: Quickshell.shellPath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: json
            property bool showMedia: true
            property bool showNetSpeed: true
            property bool showNetwork: true
            property bool showVolume: true
            property bool showBattery: true
            property bool showWeather: true
            property bool showLauncher: true
            property bool showWorkspaces: true
            property bool showClock: true
            property bool showPower: true
            property bool osdEnabled: true
            property bool eqEnabled: true
            property bool clock12h: false
            property bool showDate: true
            property bool showTray: true
            property bool showNotifs: true
            property string barPosition: "top"   // top | bottom | left | right
            property bool barSolid: false
            property string barLeft: "settings,launcher,workspaces,tray,media"
            property string barCenter: "weather,clock,notifs"
            property string barRight: "netspeed,network,volume,battery,power"
            property int osdDuration: 1600
            property int volumeStep: 5
            property string weatherLocation: ""
            property int weatherInterval: 15
            property real scale: 1.0
            property bool dotFont: true          // off = plain text instead of dots
            property string wallpaperDir: ""     // empty = ~/Pictures/Wallpapers
            property string wallpaper: ""        // the picture on every screen
            property string wallpaperPerMonitor: "" // "name=path;name=path" overrides
            property string wallpaperFill: "crop"   // crop | fit | stretch | center | tile
            property string wallpaperTransition: "random" // fade | wipe | slide | zoom | random
            property int wallpaperTransitionMs: 900
            property int wallpaperRandomMin: 0   // minutes between random changes, 0 = off
            property string wallpaperSolid: "#000000" // behind the picture, or alone without one
            property string dockPinned: ""       // desktop entry ids pinned to the overview dash
            property string dockUsage: ""        // "id=count,id=count", most used first
            property string accent: "#d71921"
            property string eqPreset: ""
            property string eqGains: "0,0,0,0,0,0,0,0,0,0"
        }
    }

    // one-time migration: add widgets that predate this config, keeping user order
    Timer {
        interval: 1500; running: true
        onTriggered: {
            const all = (json.barLeft + "," + json.barCenter + "," + json.barRight)
                .split(",").filter(x => x !== "");
            if (!all.includes("tray")) {
                const l = json.barLeft.split(",").filter(x => x !== "");
                const i = l.indexOf("workspaces");
                l.splice(i >= 0 ? i + 1 : l.length, 0, "tray");
                json.barLeft = l.join(",");
            }
            if (!all.includes("notifs")) {
                const c = json.barCenter.split(",").filter(x => x !== "");
                c.push("notifs");
                json.barCenter = c.join(",");
            }
        }
    }
}

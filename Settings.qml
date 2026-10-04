pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Persistent shell settings in $XDG_CONFIG_HOME/glueqs/settings.json, so the
// shell itself can live somewhere read-only (a package, the Nix store). A
// settings.json still sitting next to the QML is copied over once.
Singleton {
    id: root
    readonly property var s: json
    readonly property string dir: {
        const x = Quickshell.env("XDG_CONFIG_HOME");
        return (x !== null && x !== undefined && x !== "" ? x : Quickshell.env("HOME") + "/.config") + "/glueqs";
    }
    property bool ready: false

    Process {
        running: true
        command: ["sh", "-c",
            'mkdir -p "$1" && if [ ! -e "$1/settings.json" ] && [ -e "$2" ]; then cp "$2" "$1/settings.json"; fi',
            "glueqs", root.dir, Quickshell.shellPath("settings.json")]
        onExited: { root.ready = true; store.reload(); }
    }

    FileView {
        id: store
        path: root.dir + "/settings.json"
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
            property bool showBrightness: true
            property bool showLevels: true
            property int idleOffMin: 10          // minutes idle before the backlight goes to 0, 0 = never
            property int idleSuspendMin: 0       // minutes idle before suspend, 0 = never
            property bool idleNotWhileMedia: true
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
            property string barRight: "netspeed,network,levels,battery,power"
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
            property string dockPinned: "org.glue.Welcome" // desktop entry ids pinned to the overview dash; ids without a .desktop file are skipped
            property string dockUsage: ""        // "id=count,id=count", most used first
            property string accent: ""          // empty = the scheme's own accent
            // ---- theme ----
            property string themeScheme: "nothing" // a Palettes.js id, "custom" or "wallpaper"
            property string themeCustom: ""      // JSON of the custom scheme's slots
            property string wallpaperSchemeMode: "dark"   // dark | light, for the wallpaper scheme
            property string wallpaperSchemeType: "scheme-tonal-spot"
            property string uiFont: ""           // empty = JetBrains Mono
            property int fontWeight: 500
            property string dotShape: "round"    // round | square | rounded | diamond | bar
            property real dotFill: 1.0           // dot size inside its cell, 0.6..1.2
            property real panelOpacity: 1.0
            property real tileOpacity: 1.0
            property bool borders: true
            property int radius: 10
            property int barSize: 48
            property int tileSpacing: 8
            property bool barFloating: false
            property real animSpeed: 1.0         // 0 = no animation
            // ---- sleep mode and keep awake ----
            property bool sleepEnabled: true
            property bool keepAwake: false
            // ---- visualisers in the bar ----
            property int vizBars: 16
            property int vizWidth: 96
            property string vizColor: "accent"   // accent | text | gradient
            property int vizFps: 30
            property bool vizHideIdle: false
            property string eqPreset: ""
            property string eqGains: "0,0,0,0,0,0,0,0,0,0"
        }
    }

    // one-time migration: add widgets that predate this config, keeping user order
    Timer {
        interval: 1500; running: root.ready
        onTriggered: {
            // a 0 timeout used to be how sleep mode was switched off
            if (json.idleOffMin <= 0) { json.sleepEnabled = false; json.idleOffMin = 10; }
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
            // the combined levels tile takes the volume tile's place unless
            // the separate tiles were chosen on purpose
            if (!all.includes("levels") && !all.includes("brightness")) {
                for (const z of ["barLeft", "barCenter", "barRight"]) {
                    const l = json[z].split(",").filter(x => x !== "");
                    const i = l.indexOf("volume");
                    if (i >= 0) { l[i] = "levels"; json[z] = l.join(","); return; }
                }
                const r = json.barRight.split(",").filter(x => x !== "");
                const i = r.indexOf("battery");
                r.splice(i >= 0 ? i : r.length, 0, "levels");
                json.barRight = r.join(",");
            }
        }
    }
}

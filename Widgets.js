.pragma library

// Every bar widget the settings can place. multi: may sit on the bar more
// than once. key: the old show/hide setting it still has, if any.
var LIST = [
    { id: "settings", name: "Settings", icon: "gear", desc: "Opens this panel", group: "shell" },
    { id: "launcher", name: "Launcher", icon: "grid", desc: "App search", key: "showLauncher", group: "shell" },
    { id: "workspaces", name: "Workspaces", icon: "window", desc: "gluewc tags of this screen", key: "showWorkspaces", group: "shell" },
    { id: "tray", name: "Tray", icon: "tray", desc: "Status icons of running apps", key: "showTray", group: "shell" },
    { id: "notifs", name: "Notifications", icon: "bell", desc: "History and unread count", key: "showNotifs", group: "shell" },
    { id: "power", name: "Power", icon: "power", desc: "Log out, reboot, power off", key: "showPower", group: "shell" },
    { id: "clock", name: "Clock", icon: "clock", desc: "Time and date, click for the calendar", key: "showClock", group: "info" },
    { id: "weather", name: "Weather", icon: "sun", desc: "wttr.in, click for the forecast", key: "showWeather", group: "info" },
    { id: "window", name: "Active window", icon: "window", desc: "Title of the focused window", group: "info", isNew: true },
    { id: "caps", name: "Caps lock", icon: "caps", desc: "Lights up while caps lock is on", group: "info", isNew: true },
    { id: "media", name: "Media", icon: "note", desc: "Now playing, click for the player", key: "showMedia", group: "audio" },
    { id: "levels", name: "Volume and brightness", icon: "speaker", desc: "One tile for both sliders", key: "showLevels", group: "audio" },
    { id: "volume", name: "Volume", icon: "speaker", desc: "Volume alone, scroll to change", key: "showVolume", group: "audio" },
    { id: "mic", name: "Microphone", icon: "mic", desc: "Click mutes, scroll sets the level", group: "audio", isNew: true },
    { id: "viz:dots", name: "Visualiser · dots", icon: "wave", desc: "Dot-matrix spectrum", group: "viz", multi: true, isNew: true },
    { id: "viz:bars", name: "Visualiser · bars", icon: "wave", desc: "Solid bars from the bottom", group: "viz", multi: true, isNew: true },
    { id: "viz:mirror", name: "Visualiser · mirror", icon: "wave", desc: "Bars from the middle line", group: "viz", multi: true, isNew: true },
    { id: "viz:wave", name: "Visualiser · wave", icon: "wave", desc: "A filled, mirrored curve", group: "viz", multi: true, isNew: true },
    { id: "viz:line", name: "Visualiser · line", icon: "wave", desc: "A single smooth line", group: "viz", multi: true, isNew: true },
    { id: "viz:peaks", name: "Visualiser · peaks", icon: "wave", desc: "Bars with falling peak marks", group: "viz", multi: true, isNew: true },
    { id: "network", name: "Wi-Fi and Bluetooth", icon: "wifi3", desc: "Click for the network panel", key: "showNetwork", group: "system" },
    { id: "netspeed", name: "Net speed", icon: "down", desc: "Download and upload rate", key: "showNetSpeed", group: "system" },
    { id: "battery", name: "Battery", icon: "power", desc: "Charge and time left", key: "showBattery", group: "system" },
    { id: "brightness", name: "Brightness", icon: "bright", desc: "Backlight alone", key: "showBrightness", group: "system" },
    { id: "cpu", name: "CPU", icon: "cpu", desc: "Processor load", group: "system", isNew: true },
    { id: "ram", name: "Memory", icon: "ram", desc: "RAM in use", group: "system", isNew: true },
    { id: "temp", name: "Temperature", icon: "temp", desc: "CPU temperature", group: "system", isNew: true },
    { id: "disk", name: "Disk", icon: "disk", desc: "Space used on /", group: "system", isNew: true },
    { id: "keepawake", name: "Keep awake", icon: "cup", desc: "Holds sleep mode and suspend", group: "system", isNew: true },
    { id: "wallpaper", name: "Wallpaper", icon: "image", desc: "Click for the picker, scroll for the next", group: "system", isNew: true },
    { id: "spacer", name: "Spacer", icon: "dot", desc: "An empty gap", group: "shell", multi: true, isNew: true }
];

var GROUPS = [
    { id: "all", name: "ALL" }, { id: "shell", name: "SHELL" }, { id: "info", name: "INFO" },
    { id: "audio", name: "AUDIO" }, { id: "viz", name: "VISUALISERS" }, { id: "system", name: "SYSTEM" }
];

function byId(id) {
    for (var i = 0; i < LIST.length; i++) if (LIST[i].id === id) return LIST[i];
    return { id: id, name: id, icon: "dot", desc: "" };
}

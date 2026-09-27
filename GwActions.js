// Plain-language names for gluewc actions and key combos, and the way back.
.pragma library

// [action, label, group]; N stands for a workspace number 1..9
var WM = [
    ["wm:kill", "Close window", "Windows"],
    ["wm:toggle_fullscreen", "Fullscreen, bar stays", "Windows"],
    ["wm:toggle_real_fullscreen", "Fullscreen, whole screen", "Windows"],
    ["wm:toggle_float", "Float or tile the window", "Windows"],
    ["wm:toggle_float_centered", "Float the window, centred", "Windows"],
    ["wm:toggle_decorations", "Hide or show borders", "Windows"],
    ["wm:toggle_opacity", "Toggle window transparency", "Windows"],
    ["wm:consume", "Pull the next window into this tile", "Windows"],
    ["wm:expel", "Push the window out of its tile", "Windows"],
    ["wm:focus_left", "Focus left", "Focus"],
    ["wm:focus_right", "Focus right", "Focus"],
    ["wm:focus_up", "Focus up", "Focus"],
    ["wm:focus_down", "Focus down", "Focus"],
    ["wm:focus_next", "Focus next window", "Focus"],
    ["wm:swap_left", "Swap with the window on the left", "Move"],
    ["wm:swap_right", "Swap with the window on the right", "Move"],
    ["wm:swap_up", "Swap with the window above", "Move"],
    ["wm:swap_down", "Swap with the window below", "Move"],
    ["wm:swap_prev", "Swap with the previous window", "Move"],
    ["wm:swap_next", "Swap with the next window", "Move"],
    ["wm:move_left", "Move window left, on to the next workspace at the edge", "Move"],
    ["wm:move_right", "Move window right, on to the next workspace at the edge", "Move"],
    ["wm:move_up", "Move window up, on to the next workspace at the edge", "Move"],
    ["wm:move_down", "Move window down, on to the next workspace at the edge", "Move"],
    ["wm:workspace:N", "Switch to workspace N", "Workspaces"],
    ["wm:workspace_prev", "Previous workspace", "Workspaces"],
    ["wm:workspace_next", "Next workspace", "Workspaces"],
    ["wm:move_to_workspace_follow:N", "Move window to workspace N and follow it", "Workspaces"],
    ["wm:move_to_workspace_prev", "Move window to the previous workspace", "Workspaces"],
    ["wm:move_to_workspace_next", "Move window to the next workspace", "Workspaces"],
    ["wm:move_to_workspace_left", "Move window to the workspace on the left", "Workspaces"],
    ["wm:move_to_workspace_right", "Move window to the workspace on the right", "Workspaces"],
    ["wm:move_to_workspace_up", "Move window to the workspace above", "Workspaces"],
    ["wm:move_to_workspace_down", "Move window to the workspace below", "Workspaces"],
    ["wm:toggle_layout", "Next layout (bsp, scroll, drift)", "Layout"],
    ["wm:layout:bsp", "Layout: BSP tiling", "Layout"],
    ["wm:layout:scroll", "Layout: scrolling strip", "Layout"],
    ["wm:layout:drift", "Layout: drift canvas", "Layout"],
    ["wm:toggle_split", "Flip the split direction", "Layout"],
    ["wm:ratio:-0.05", "Shrink the split", "Layout"],
    ["wm:ratio:+0.05", "Grow the split", "Layout"],
    ["wm:zoom_in", "Zoom in (drift)", "Layout"],
    ["wm:zoom_out", "Zoom out (drift)", "Layout"],
    ["wm:zoom_reset", "Zoom to 100% (drift)", "Layout"],
    ["wm:zoom_fit", "Zoom to fit everything (drift)", "Layout"],
    ["wm:pan_left", "Pan the canvas left", "Layout"],
    ["wm:pan_right", "Pan the canvas right", "Layout"],
    ["wm:pan_up", "Pan the canvas up", "Layout"],
    ["wm:pan_down", "Pan the canvas down", "Layout"],
    ["wm:overview", "Toggle the overview", "Session"],
    ["wm:mode:normal", "Normal mode: keys work without Super", "Session"],
    ["wm:mode:insert", "Insert mode: keys go to the window", "Session"],
    ["wm:reload", "Reload the config", "Session"],
    ["wm:restart", "Restart gluewc", "Session"],
    ["wm:quit", "Quit gluewc, end the session", "Session"]
];

// commands the default config spawns, matched by what they contain
var SPAWN = [
    [/wpctl set-volume.*%\+|pactl set-sink-volume.*\+|pamixer -i/, "Volume up"],
    [/wpctl set-volume.*%-|pactl set-sink-volume.*-[0-9]|pamixer -d/, "Volume down"],
    [/set-mute @DEFAULT_AUDIO_SOURCE@|set-source-mute|--default-source -t/, "Mute the microphone"],
    [/set-mute @DEFAULT_AUDIO_SINK@|set-sink-mute|pamixer -t/, "Mute"],
    [/playerctl play-pause/, "Play or pause"],
    [/playerctl next/, "Next track"],
    [/playerctl previous/, "Previous track"],
    [/playerctl stop/, "Stop playback"],
    [/playerctl position \d+-/, "Seek back"],
    [/playerctl position \d+\+/, "Seek forward"],
    [/gluewc-backlight up|brightnessctl set \+|light -A/, "Brightness up"],
    [/gluewc-backlight down|brightnessctl set .*-$|light -U/, "Brightness down"],
    [/slurp.*grim.*wl-copy|grim -g.*wl-copy/, "Screenshot an area to the clipboard"],
    [/slurp.*grim|grim -g/, "Screenshot an area to a file"],
    [/grim - \| wl-copy/, "Screenshot the screen to the clipboard"],
    [/grim /, "Screenshot the screen to a file"],
    [/^(qs|quickshell) .*glueqs/, "Start the glueqs bar"],
    [/rofi|fuzzel|wmenu|bemenu|wofi|tofi|anyrun/, "App launcher"],
    [/^(alacritty|foot|kitty|wezterm|ghostty|st|xterm|konsole|gnome-terminal)\b/, "Terminal"],
    [/swaylock|hyprlock|gtklock|waylock/, "Lock the screen"]
];

var KEYNAMES = {
    Return: "Enter", KP_Enter: "Enter", space: "Space", BackSpace: "Backspace",
    Page_Up: "PgUp", Page_Down: "PgDn", Left: "←", Right: "→", Up: "↑", Down: "↓",
    Print: "PrtSc", comma: ",", period: ".", minus: "-", equal: "=", plus: "+", slash: "/",
    backslash: "\\", semicolon: ";", apostrophe: "'", bracketleft: "[", bracketright: "]",
    grave: "`", less: "<", greater: ">", Escape: "Esc", Delete: "Del", Insert: "Ins",
    XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute",
    XF86AudioMicMute: "Mic mute", XF86AudioPlay: "Play", XF86AudioPause: "Pause",
    XF86AudioStop: "Stop", XF86AudioNext: "Next track", XF86AudioPrev: "Prev track",
    XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −",
    XF86PowerOff: "Power", XF86Sleep: "Sleep", XF86Search: "Search", XF86Calculator: "Calc"
};
var MODNAMES = { mod: "Super", super: "Super", logo: "Super", shift: "Shift", ctrl: "Ctrl", control: "Ctrl", alt: "Alt" };

function wmEntry(action) {
    var m = action.match(/^wm:(workspace|move_to_workspace_follow):(\d)$/);
    if (m) {
        var tmpl = m[1] === "workspace" ? "Switch to workspace N" : "Move window to workspace N and follow it";
        return { label: tmpl.replace("N", m[2]), group: "Workspaces" };
    }
    m = action.match(/^wm:ratio:([+-]?[0-9.]+)$/);
    if (m) return { label: (m[1][0] === "-" ? "Shrink the split by " : "Grow the split by ") + m[1].replace(/^[+-]/, ""), group: "Layout" };
    for (var i = 0; i < WM.length; i++)
        if (WM[i][0] === action) return { label: WM[i][1], group: WM[i][2] };
    return null;
}

// what a bind does, in words; detail is the raw action for the grey line
function describe(action) {
    var wm = wmEntry(action);
    if (wm) return { label: wm.label, group: wm.group, kind: "wm" };
    if (action.indexOf("spawn:") === 0) {
        var cmd = action.slice(6).trim();
        for (var i = 0; i < SPAWN.length; i++)
            if (SPAWN[i][0].test(cmd)) return { label: SPAWN[i][1], group: "Run", kind: "spawn" };
        var first = cmd.split(/\s+/)[0].replace(/^.*\//, "");
        return { label: "Run " + (first.length > 24 ? first.slice(0, 24) + "…" : first), group: "Run", kind: "spawn" };
    }
    return { label: action, group: "Other", kind: "raw" };
}

// "mod+shift+q" -> ["Super", "Shift", "Q"]
function chips(combo) {
    var parts = combo.split("+").filter(function (p) { return p !== ""; });
    // a literal "+" key comes through as an empty token at the end
    if (combo.slice(-1) === "+") parts.push("plus");
    return parts.map(function (p, i) {
        var lower = p.toLowerCase();
        if (i < parts.length - 1 && MODNAMES[lower]) return MODNAMES[lower];
        if (KEYNAMES[p]) return KEYNAMES[p];
        if (p.length === 1) return p.toUpperCase();
        return p;
    });
}

// every action a picker can offer, workspace numbers spelled out
function catalogue() {
    var out = [];
    for (var i = 0; i < WM.length; i++) {
        var a = WM[i][0];
        if (a.indexOf(":N") > 0) {
            for (var n = 1; n <= 9; n++)
                out.push({ action: a.replace(":N", ":" + n), label: WM[i][1].replace("N", n), group: WM[i][2] });
        } else {
            out.push({ action: a, label: WM[i][1], group: WM[i][2] });
        }
    }
    return out;
}

// the Exec of a .desktop entry without its field codes
function cleanExec(exec) {
    return exec.replace(/%[fFuUdDnNickvm]/g, "").replace(/\s+/g, " ").trim();
}

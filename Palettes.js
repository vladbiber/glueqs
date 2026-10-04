.pragma library

// Colour schemes. Every scheme fills the same slots:
//   bg      the bar when it is solid, the darkest layer
//   panel   popup and settings backgrounds
//   card    cards inside a panel
//   surface tiles, fields, chips
//   hover   anything under the pointer
//   line    hairlines between rows
//   border  tile and panel outlines
//   strong  outlines that have to stand out (hover, focus)
//   fg      text and lit dots
//   muted   secondary text
//   faint   unlit dots
//   accent  the one colour
var SCHEMES = [
    { id: "nothing", name: "Nothing", dark: true,
      bg: "#000000", panel: "#0d0d0d", card: "#111111", surface: "#161616", hover: "#1c1c1c",
      line: "#202020", border: "#262626", strong: "#4a4a4a",
      fg: "#f2f2f2", muted: "#9a9a9a", faint: "#2e2e2e", accent: "#d71921" },
    { id: "paper", name: "Paper", dark: false,
      bg: "#f4f2ee", panel: "#ecebe6", card: "#f7f6f2", surface: "#e2e0da", hover: "#d8d6cf",
      line: "#d2cfc7", border: "#c9c6bd", strong: "#8f8b80",
      fg: "#141414", muted: "#5c5a55", faint: "#cfccc4", accent: "#d71921" },
    { id: "amber", name: "Amber CRT", dark: true,
      bg: "#0a0600", panel: "#110b02", card: "#160f04", surface: "#1c1406", hover: "#261b08",
      line: "#2a1e0a", border: "#3a2a0e", strong: "#7a5a1c",
      fg: "#ffb000", muted: "#b37d14", faint: "#3a2a0e", accent: "#ff6a00" },
    { id: "phosphor", name: "Phosphor", dark: true,
      bg: "#020a04", panel: "#04100a", card: "#06140c", surface: "#0a1c10", hover: "#0e2616",
      line: "#103018", border: "#164020", strong: "#2e7a44",
      fg: "#4dff88", muted: "#2fae5c", faint: "#123a1e", accent: "#b6ff3c" },
    { id: "gruvbox", name: "Gruvbox", dark: true,
      bg: "#1d2021", panel: "#282828", card: "#2e2b2a", surface: "#32302f", hover: "#3c3836",
      line: "#3c3836", border: "#504945", strong: "#7c6f64",
      fg: "#ebdbb2", muted: "#a89984", faint: "#504945", accent: "#fe8019" },
    { id: "catppuccin", name: "Catppuccin", dark: true,
      bg: "#11111b", panel: "#181825", card: "#1e1e2e", surface: "#24243a", hover: "#313244",
      line: "#313244", border: "#45475a", strong: "#6c7086",
      fg: "#cdd6f4", muted: "#a6adc8", faint: "#45475a", accent: "#cba6f7" },
    { id: "latte", name: "Latte", dark: false,
      bg: "#eff1f5", panel: "#e6e9ef", card: "#eff1f5", surface: "#dce0e8", hover: "#ccd0da",
      line: "#ccd0da", border: "#bcc0cc", strong: "#8c8fa1",
      fg: "#4c4f69", muted: "#6c6f85", faint: "#bcc0cc", accent: "#8839ef" },
    { id: "tokyonight", name: "Tokyo Night", dark: true,
      bg: "#16161e", panel: "#1a1b26", card: "#1f2030", surface: "#24283b", hover: "#292e42",
      line: "#292e42", border: "#3b4261", strong: "#565f89",
      fg: "#c0caf5", muted: "#9aa5ce", faint: "#3b4261", accent: "#7aa2f7" },
    { id: "nord", name: "Nord", dark: true,
      bg: "#242933", panel: "#2e3440", card: "#323846", surface: "#3b4252", hover: "#434c5e",
      line: "#3b4252", border: "#4c566a", strong: "#6c7a96",
      fg: "#eceff4", muted: "#b5bdcb", faint: "#4c566a", accent: "#88c0d0" },
    { id: "rosepine", name: "Rosé Pine", dark: true,
      bg: "#13111e", panel: "#191724", card: "#1f1d2e", surface: "#26233a", hover: "#2a2740",
      line: "#26233a", border: "#403d52", strong: "#6e6a86",
      fg: "#e0def4", muted: "#908caa", faint: "#403d52", accent: "#eb6f92" },
    { id: "dracula", name: "Dracula", dark: true,
      bg: "#191a21", panel: "#21222c", card: "#282a36", surface: "#2c2e3b", hover: "#343746",
      line: "#343746", border: "#44475a", strong: "#6272a4",
      fg: "#f8f8f2", muted: "#bfbfd0", faint: "#44475a", accent: "#ff79c6" },
    { id: "everforest", name: "Everforest", dark: true,
      bg: "#1e2326", panel: "#232a2e", card: "#283035", surface: "#2d353b", hover: "#343f44",
      line: "#343f44", border: "#475258", strong: "#7a8478",
      fg: "#d3c6aa", muted: "#9da9a0", faint: "#475258", accent: "#a7c080" },
    { id: "kanagawa", name: "Kanagawa", dark: true,
      bg: "#16161d", panel: "#1f1f28", card: "#232330", surface: "#2a2a37", hover: "#363646",
      line: "#2a2a37", border: "#54546d", strong: "#727169",
      fg: "#dcd7ba", muted: "#a6a69c", faint: "#363646", accent: "#e46876" },
    { id: "solarized", name: "Solarized", dark: true,
      bg: "#00212b", panel: "#002b36", card: "#04313d", surface: "#073642", hover: "#0b4150",
      line: "#073642", border: "#28505c", strong: "#586e75",
      fg: "#eee8d5", muted: "#93a1a1", faint: "#28505c", accent: "#b58900" },
    { id: "ocean", name: "Deep Ocean", dark: true,
      bg: "#05080f", panel: "#0a0f1a", card: "#0e1422", surface: "#131b2c", hover: "#1a2438",
      line: "#18213a", border: "#22304c", strong: "#41587e",
      fg: "#e3ecff", muted: "#8ea3c8", faint: "#1d2a44", accent: "#3dd6ff" },
    { id: "sakura", name: "Sakura", dark: true,
      bg: "#120a0e", panel: "#1a0f15", card: "#20131a", surface: "#281820", hover: "#33202a",
      line: "#2e1c26", border: "#4a2c3a", strong: "#8a5a70",
      fg: "#ffe4ee", muted: "#c79aae", faint: "#3e2532", accent: "#ff8fb8" }
];

var KEYS = ["bg", "panel", "card", "surface", "hover", "line", "border", "strong", "fg", "muted", "faint", "accent"];

var KEY_NAMES = {
    bg: "Background", panel: "Panels", card: "Cards", surface: "Tiles and fields",
    hover: "Hover", line: "Hairlines", border: "Borders", strong: "Strong borders",
    fg: "Text", muted: "Secondary text", faint: "Unlit dots", accent: "Accent"
};

function byId(id) {
    for (var i = 0; i < SCHEMES.length; i++)
        if (SCHEMES[i].id === id) return SCHEMES[i];
    return SCHEMES[0];
}

// a custom scheme is stored as JSON; missing slots fall back to Nothing
function parse(json) {
    var base = SCHEMES[0];
    var out = {};
    var obj = {};
    try { obj = JSON.parse(json || "{}") || {}; } catch (e) { obj = {}; }
    for (var i = 0; i < KEYS.length; i++) {
        var k = KEYS[i];
        out[k] = /^#[0-9a-fA-F]{6}$/.test(obj[k] || "") ? obj[k] : base[k];
    }
    out.dark = luminance(out.bg) < 0.5;
    return out;
}

function luminance(hex) {
    var r = parseInt(hex.substr(1, 2), 16) / 255;
    var g = parseInt(hex.substr(3, 2), 16) / 255;
    var b = parseInt(hex.substr(5, 2), 16) / 255;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function mix(a, b, t) {
    function ch(h, i) { return parseInt(h.substr(i, 2), 16); }
    function hx(v) { var s = Math.round(v).toString(16); return s.length < 2 ? "0" + s : s; }
    return "#" + hx(ch(a, 1) + (ch(b, 1) - ch(a, 1)) * t)
               + hx(ch(a, 3) + (ch(b, 3) - ch(a, 3)) * t)
               + hx(ch(a, 5) + (ch(b, 5) - ch(a, 5)) * t);
}

// matugen's material colours mapped onto the slots
function fromMaterial(c, dark) {
    var get = function (k, d) { return /^#[0-9a-fA-F]{6}$/.test(c[k] || "") ? c[k] : d; };
    var bg = get("surface_container_lowest", get("background", "#000000"));
    var fg = get("on_surface", "#f2f2f2");
    return {
        dark: dark,
        bg: bg,
        panel: get("surface_container_low", mix(bg, fg, 0.04)),
        card: get("surface_container", mix(bg, fg, 0.07)),
        surface: get("surface_container_high", mix(bg, fg, 0.10)),
        hover: get("surface_container_highest", mix(bg, fg, 0.14)),
        line: get("surface_variant", mix(bg, fg, 0.12)),
        border: get("outline_variant", mix(bg, fg, 0.18)),
        strong: get("outline", mix(bg, fg, 0.35)),
        fg: fg,
        muted: get("on_surface_variant", mix(fg, bg, 0.35)),
        faint: mix(bg, fg, 0.16),
        accent: get("primary", "#d71921")
    };
}

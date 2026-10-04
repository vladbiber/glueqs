#!/usr/bin/env python3
"""Wallpaper palettes and colour-only terminal integration for GlueQS."""

import argparse
import copy
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import tempfile
import tomllib


SLOTS = "bg panel card surface hover line border strong fg muted faint accent".split()
STYLES = ("faithful", "soft", "vibrant", "muted", "monochrome")


def rgb(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))


def hex_rgb(values):
    return "#" + "".join(f"{round(max(0, min(1, v)) * 255):02x}" for v in values)


def linear(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def luminance(value):
    r, g, b = map(linear, rgb(value))
    return .2126 * r + .7152 * g + .0722 * b


def contrast(a, b):
    x, y = sorted((luminance(a), luminance(b)))
    return (y + .05) / (x + .05)


def oklch(value):
    r, g, b = map(linear, rgb(value))
    l = (.4122214708*r + .5363325363*g + .0514459929*b) ** (1/3)
    m = (.2119034982*r + .6806995451*g + .1073969566*b) ** (1/3)
    s = (.0883024619*r + .2817188376*g + .6299787005*b) ** (1/3)
    light = .2104542553*l + .793617785*m - .0040720468*s
    a = 1.9779984951*l - 2.428592205*m + .4505937099*s
    b = .0259040371*l + .7827717662*m - .808675766*s
    return light, math.hypot(a, b), math.atan2(b, a)


def tone(light, chroma, hue):
    # Reduce chroma into sRGB instead of clipping channels and shifting hue.
    def channels(c):
        a, b = c * math.cos(hue), c * math.sin(hue)
        l = (light + .3963377774*a + .2158037573*b) ** 3
        m = (light - .1055613458*a - .0638541728*b) ** 3
        s = (light - .0894841775*a - 1.291485548*b) ** 3
        return (4.0767416621*l - 3.3077115913*m + .2309699292*s,
                -1.2684380046*l + 2.6097574011*m - .3413193965*s,
                -.0041960863*l - .7034186147*m + 1.707614701*s)
    low, high = 0, chroma
    for _ in range(18):
        mid = (low + high) / 2
        if all(-1e-7 <= v <= 1.0000001 for v in channels(mid)):
            low = mid
        else:
            high = mid
    return hex_rgb(12.92*v if v <= .0031308 else 1.055*v**(1/2.4)-.055
                   for v in channels(low))


def image_seeds(path):
    from PIL import Image, ImageOps
    with Image.open(Path(path).expanduser()) as source:
        image = ImageOps.exif_transpose(source).convert("RGBA")
        image.thumbnail((192, 192))
        # Invisible pixels must not contribute their often arbitrary RGB.
        data = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
        pixels = [p[:3] for p in data if p[3] >= 128]
    if not pixels:
        raise ValueError("Wallpaper has no visible pixels")
    sample = Image.new("RGB", (len(pixels), 1))
    sample.putdata(pixels)
    quantized = sample.quantize(colors=64, method=Image.Quantize.MEDIANCUT)
    palette = quantized.getpalette()
    entries = []
    for count, index in quantized.getcolors():
        color = hex_rgb(v / 255 for v in palette[index*3:index*3+3])
        light, chroma, hue = oklch(color)
        entries.append((count, color, light, chroma, hue))
    entries.sort(reverse=True)
    colorful = [e for e in entries if e[3] >= .025 and .12 < e[2] < .94]
    # A tiny saturated detail is not the overall character of a grey image.
    if sum(e[0] for e in colorful) < len(pixels) * .10:
        dominant = entries[0]
        return [tone(max(.35, min(.75, dominant[2])), 0, 0)]
    # Sum population across neighbouring shades; saturation gets no bonus.
    bins = {}
    for entry in colorful:
        key = round(entry[4] / (2*math.pi) * 18) % 18
        bins.setdefault(key, []).append(entry)
    groups = sorted(bins.values(), key=lambda es: sum(e[0] for e in es), reverse=True)
    seeds = []
    for group in groups:
        entry = max(group, key=lambda e: e[0])
        if all(abs(math.atan2(math.sin(entry[4]-oklch(c)[2]),
                             math.cos(entry[4]-oklch(c)[2]))) > .38 for c in seeds):
            seeds.append(entry[1])
        if len(seeds) == 6:
            break
    return seeds


def palette_from_seed(seed, mode="dark", style="faithful"):
    _, chroma, hue = oklch(seed)
    dark = mode == "dark"
    chroma = 0 if chroma < .01 or style == "monochrome" else min(.24, chroma)
    chroma *= {"faithful": 1, "soft": .65, "vibrant": 1.4, "muted": .3,
               "monochrome": 0}[style]
    surface_chroma = min(chroma * .16, .025)
    levels = ([.13, .17, .20, .24, .28, .30, .37, .55, .94, .74, .32] if dark
              else [.98, .955, .935, .91, .87, .84, .76, .53, .20, .43, .82])
    result = {key: tone(level, surface_chroma, hue)
              for key, level in zip(SLOTS[:-1], levels)}
    result["accent"] = tone(.78 if dark else .46, chroma, hue)
    result["dark"] = dark
    return result


def material_palette(seed, mode, style):
    executable = shutil.which("matugen")
    local = Path.home() / ".local/bin/matugen"
    if not executable and local.is_file():
        executable = str(local)
    if not executable:
        raise ValueError("Material styles need matugen; choose Faithful or install matugen")
    proc = subprocess.run([executable, "color", "hex", seed, "--json", "hex", "--dry-run",
                           "-m", mode, "-t", style], capture_output=True, text=True, timeout=45)
    if proc.returncode:
        raise ValueError(proc.stderr.strip() or "matugen failed")
    data = json.loads(proc.stdout)["colors"]
    # Support both matugen JSON layouts, never silently substitute a red seed.
    if mode in data:
        data = data[mode]
    colors = {}
    for key, value in data.items():
        if isinstance(value, dict):
            value = value.get(mode, value.get("default", value))
            if isinstance(value, dict):
                value = value.get("color")
        if isinstance(value, str) and re.fullmatch(r"#[\da-fA-F]{6}", value):
            colors[key] = value
    if not all(key in colors for key in ("primary", "on_surface")):
        raise ValueError("matugen returned an incomplete palette")
    result = palette_from_seed(colors["primary"], mode)
    mapping = dict(zip(SLOTS, ("surface_container_lowest", "surface_container_low",
                   "surface_container", "surface_container_high", "surface_container_highest",
                   "surface_variant", "outline_variant", "outline", "on_surface",
                   "on_surface_variant", "outline_variant", "primary")))
    for key, material in mapping.items():
        result[key] = colors.get(material, result[key])
    return result


def extract(path, mode, style, index=0):
    seeds = image_seeds(path)
    if style in STYLES:
        palette = palette_from_seed(seeds[max(0, min(index, len(seeds)-1))], mode, style)
    elif style in ("scheme-tonal-spot", "scheme-content", "scheme-fidelity", "scheme-vibrant",
                   "scheme-expressive", "scheme-neutral", "scheme-monochrome", "scheme-rainbow",
                   "scheme-fruit-salad"):
        seed = seeds[max(0, min(index, len(seeds)-1))]
        palette = (palette_from_seed(seed, mode, "monochrome") if oklch(seed)[1] < .01
                   else material_palette(seed, mode, style))
    else:
        raise ValueError("Unknown wallpaper style")
    return {"palette": palette, "seeds": seeds}


def terminal_colors(p):
    for key in SLOTS:
        if not re.fullmatch(r"#[\da-fA-F]{6}", str(p.get(key, ""))):
            raise ValueError(f"Invalid palette colour: {key}")
    dark = luminance(p["bg"]) < .4
    _, chroma, _ = oklch(p["accent"])
    # Keep ANSI semantic hues identifiable, with the theme's saturation/tone.
    normal = {"black": p["surface"], "white": p["fg"]}
    bright = {"black": p["muted"], "white": p["fg"]}
    for name, hue in zip(("red", "green", "yellow", "blue", "magenta", "cyan"),
                         (25, 145, 90, 260, 325, 200)):
        normal[name] = tone(.73 if dark else .46, max(.09, min(.17, chroma)), math.radians(hue))
        bright[name] = tone(.83 if dark else .39, max(.10, min(.18, chroma)), math.radians(hue))
    selection_text = "#000000" if contrast("#000000", p["accent"]) > contrast("#ffffff", p["accent"]) else "#ffffff"
    return {"primary": {"background": p["bg"], "foreground": p["fg"]},
            "cursor": {"text": p["bg"], "cursor": p["accent"]},
            "selection": {"text": selection_text, "background": p["accent"]},
            "normal": normal, "bright": bright}


def atomic_write(path, text, backup=False):
    path = path.resolve()  # Preserve symlinks to dotfile repositories.
    old = path.read_text() if path.exists() else None
    if old == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    saved = path.with_name(path.name + ".pre-glueqs")
    if backup and old is not None and not saved.exists():
        shutil.copy2(path, saved)
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".glueqs-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.chmod(temp, path.stat().st_mode & 0o777 if path.exists() else 0o600)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    return True


def alacritty_text(text, colors):
    """Edit conventional colour tables, then prove all other TOML is intact.

    Unusual inline/dotted colour tables are rejected before any file is written.
    The semantic equality check also protects multiline strings containing what
    looks like a table header. Imports, opacity, fonts and bindings survive.
    """
    original = tomllib.loads(text)
    expected = copy.deepcopy(original)
    for name, values in colors.items():
        expected.setdefault("colors", {}).setdefault(name, {}).update(values)
    lines = text.splitlines(keepends=True)
    headers = []
    for i, line in enumerate(lines):
        if re.match(r"^\s*\[", line):
            headers.append(i)
    headers.append(len(lines))
    replacements = {}
    found = set()
    for start, end in zip(headers, headers[1:]):
        match = re.fullmatch(r'\s*\[\s*colors\s*\.\s*(\w+)\s*\]\s*(?:#[^\n]*)?\n?', lines[start])
        if not match or match[1] not in colors:
            continue
        name = match[1]
        values = expected["colors"][name]
        if not all(isinstance(value, str) for value in values.values()):
            raise ValueError(f"Unsupported Alacritty colors.{name} table")
        # Keep standalone comments (including comments before the next table).
        comments = [line for line in lines[start+1:end] if line.lstrip().startswith("#")]
        replacements[start] = (end, f"[colors.{name}]\n" + "".join(
            f"{json.dumps(key)} = {json.dumps(value)}\n" for key, value in values.items())
            + "\n" + "".join(comments))
        found.add(name)
    out, i = [], 0
    while i < len(lines):
        if i in replacements:
            i, chunk = replacements[i]
            out.append(chunk)
        else:
            out.append(lines[i])
            i += 1
    result = "".join(out).rstrip() + "\n"
    for name, values in colors.items():
        if name not in found:
            result += f"\n[colors.{name}]\n" + "".join(
                f"{json.dumps(key)} = {json.dumps(value)}\n" for key, value in values.items())
    try:
        valid = tomllib.loads(result) == expected
    except tomllib.TOMLDecodeError:
        valid = False
    if not valid:
        raise ValueError("Alacritty uses inline/dotted colour tables; convert them to [colors.*] tables first")
    return result


def config_home():
    return Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")


def terminal_paths():
    home = config_home()
    candidates = [home / "alacritty/alacritty.toml", home / "alacritty.toml",
                  Path.home() / ".alacritty.toml"]
    return {"alacritty": next((p for p in candidates if p.exists()), candidates[0]),
            "kitty": Path(os.environ.get("KITTY_CONFIG_DIRECTORY") or home / "kitty") / "kitty.conf"}


def detect():
    paths = terminal_paths()
    return {name: {"installed": bool(shutil.which(name)), "configured": path.exists(), "path": str(path)}
            for name, path in paths.items()}


def apply_terminal(name, palette, keep_text=False):
    path = terminal_paths()[name]
    colors = terminal_colors(palette)
    if name == "alacritty":
        text = path.read_text() if path.exists() else ""
        if not text:
            # Inherit the system configuration so Glue's 0.5 opacity remains.
            dirs = (os.environ.get("XDG_CONFIG_DIRS") or "/etc/xdg").split(":")
            for directory in dirs:
                system = Path(directory) / "alacritty/alacritty.toml"
                if system.is_file():
                    text = "[general]\nimport = [" + json.dumps(str(system)) + "]\n"
                    break
        if keep_text:
            colors = {"primary": {"background": palette["bg"]}}
        atomic_write(path, alacritty_text(text, colors), backup=True)
    else:
        generated = path.parent / "glueqs-colors.conf"
        ansi = "black red green yellow blue magenta cyan white".split()
        values = {"background": palette["bg"], "foreground": palette["fg"],
                  "cursor": palette["accent"], "cursor_text_color": palette["bg"],
                  "selection_background": palette["accent"], "selection_foreground": colors["selection"]["text"]}
        for i, key in enumerate(ansi):
            values[f"color{i}"] = colors["normal"][key]
            values[f"color{i+8}"] = colors["bright"][key]
        if keep_text:
            kept = {}
            if generated.exists():
                for line in generated.read_text().splitlines():
                    pair = line.split()
                    if len(pair) == 2 and pair[0] in values and re.fullmatch(r"#[\da-fA-F]{6}", pair[1]):
                        kept[pair[0]] = pair[1]
            values = dict(kept, background=palette["bg"])
        changed = atomic_write(generated, "# GlueQS colours; opacity is owned by kitty.conf.\n" +
                               "".join(f"{key} {value}\n" for key, value in values.items()))
        text = path.read_text() if path.exists() else ""
        include = "include glueqs-colors.conf"
        # Last include wins, even over a previously selected kitty theme.
        text = "\n".join(line for line in text.splitlines() if line.strip() != include).rstrip()
        changed = atomic_write(path, text + "\n" + include + "\n", backup=True) or changed
        if changed:
            for process in Path("/proc").iterdir():
                if not process.name.isdigit():
                    continue
                try:
                    if process.stat().st_uid == os.getuid() and (process / "comm").read_text().strip() == "kitty":
                        os.kill(int(process.name), signal.SIGUSR1)
                except (OSError, ValueError):
                    pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    image = sub.add_parser("extract")
    image.add_argument("path")
    image.add_argument("mode", choices=("dark", "light"))
    image.add_argument("style")
    image.add_argument("index", type=int, default=0, nargs="?")
    sub.add_parser("detect")
    apply = sub.add_parser("apply")
    apply.add_argument("--keep-text", action="store_true", help="Only sync the background, preserving text and ANSI colours")
    apply.add_argument("palette", help="JSON palette")
    apply.add_argument("terminals", nargs="+", choices=("alacritty", "kitty"))
    args = parser.parse_args()
    try:
        if args.command == "extract":
            result = extract(args.path, args.mode, args.style, args.index)
        elif args.command == "detect":
            result = detect()
        else:
            palette = json.loads(args.palette)
            done, errors = [], []
            for name in args.terminals:
                try:
                    apply_terminal(name, palette, args.keep_text)
                    done.append(name)
                except (OSError, ValueError) as error:
                    errors.append(f"{name}: {error}")
            result = {"applied": done, "errors": errors}
        print(json.dumps(result))
    except Exception as error:
        print(json.dumps({"error": str(error)}))
        raise SystemExit(1)


if __name__ == "__main__":
    main()

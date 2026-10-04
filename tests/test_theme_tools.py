import copy
import importlib.util
import json
import math
import os
from pathlib import Path
import tempfile
import tomllib
import unittest
from unittest.mock import patch

from PIL import Image

spec = importlib.util.spec_from_file_location("theme_tools", Path(__file__).parents[1] / "theme_tools.py")
theme = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme)


class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.image = Path(self.temp.name) / "wallpaper with spaces.png"

    def save(self, color, detail=None):
        image = Image.new("RGB", (100, 100), color)
        if detail:
            image.paste(detail, (0, 0, 5, 100))
        image.save(self.image)

    def test_greyscale_never_acquires_red(self):
        for grey in ("#000000", "#777777", "#ffffff"):
            self.save(grey)
            for mode in ("dark", "light"):
                for style in theme.STYLES:
                    p = theme.extract(str(self.image), mode, style)["palette"]
                    for key in theme.SLOTS:
                        self.assertLess(max(theme.rgb(p[key])) - min(theme.rgb(p[key])), .01)

    def test_tiny_red_detail_does_not_dominate_grey(self):
        self.save("#888888", "#ff0000")
        p = theme.extract(str(self.image), "dark", "faithful")["palette"]
        self.assertLess(theme.oklch(p["accent"])[1], .01)

    def test_population_wins_over_saturation(self):
        self.save("#568baf", "#ff0000")
        result = theme.extract(str(self.image), "dark", "faithful")
        a, b = theme.oklch(result["palette"]["accent"])[2], theme.oklch("#568baf")[2]
        self.assertLess(abs(math.atan2(math.sin(a-b), math.cos(a-b))), .05)
        self.assertGreaterEqual(len(result["seeds"]), 2)
        alternative = theme.extract(str(self.image), "dark", "faithful", 1)
        self.assertNotEqual(result["palette"]["accent"], alternative["palette"]["accent"])

    def test_transparent_pixels_do_not_supply_a_seed(self):
        image = Image.new("RGBA", (100, 100), (255, 0, 0, 0))
        image.paste((30, 130, 180, 255), (0, 0, 10, 100))
        image.save(self.image)
        self.assertEqual(theme.image_seeds(str(self.image)), ["#1e82b4"])

    def test_contrast_and_styles(self):
        for seed in ("#ff0000", "#0000ff", "#ffffff", "#00ff00", "#777777", "#fbbb22"):
            for mode in ("dark", "light"):
                for style in theme.STYLES:
                    p = theme.palette_from_seed(seed, mode, style)
                    self.assertGreaterEqual(theme.contrast(p["fg"], p["bg"]), 7)
                    self.assertGreaterEqual(theme.contrast(p["accent"], p["bg"]), 4.5)
                    self.assertGreaterEqual(theme.contrast(p["muted"], p["panel"]), 4.5)
        muted = theme.palette_from_seed("#568baf", style="muted")
        vivid = theme.palette_from_seed("#568baf", style="vibrant")
        self.assertGreater(theme.oklch(vivid["accent"])[1], theme.oklch(muted["accent"])[1])

    def test_bad_image_is_an_error(self):
        self.image.write_text("not an image")
        with self.assertRaises(OSError):
            theme.extract(str(self.image), "dark", "faithful")

    def test_material_accepts_both_json_layouts_and_rejects_incomplete(self):
        for data in ({"primary": {"dark": {"color": "#88aacc"}}, "on_surface": {"dark": {"color": "#eeeeee"}}},
                     {"dark": {"primary": "#88aacc", "on_surface": "#eeeeee"}}):
            with patch.object(theme.shutil, "which", return_value="matugen"), patch.object(theme.subprocess, "run") as run:
                run.return_value.returncode = 0
                run.return_value.stdout = json.dumps({"colors": data})
                self.assertEqual(theme.material_palette("image", "dark", "scheme-content")["accent"], "#88aacc")
                self.assertNotIn("--prefer", run.call_args.args[0])
        with patch.object(theme.shutil, "which", return_value="matugen"), patch.object(theme.subprocess, "run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = '{"colors": {}}'
            with self.assertRaises(ValueError):
                theme.material_palette("image", "dark", "scheme-content")


class TerminalTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = patch.dict(os.environ, {"HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / "config"),
            "XDG_CONFIG_DIRS": str(self.home / "system"), "KITTY_CONFIG_DIRECTORY": ""})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.palette = theme.palette_from_seed("#4080c0")

    def test_alacritty_preserves_all_noncolor_settings_and_is_idempotent(self):
        text = '''# my terminal
[general]
import = ["other.toml"]
live_config_reload = true
[window]
opacity = 0.37 # transparency
blur = true
[font]
size = 13.5
[colors]
transparent_background_colors = true
[colors.primary]
background = "#000000"
dim_foreground = "#888888"
[colors.normal]
red = "#ff0000"
[[keyboard.bindings]]
key = "K"
mods = "Control"
action = "ClearHistory"
'''
        colors = theme.terminal_colors(self.palette)
        output = theme.alacritty_text(text, colors)
        before, after = tomllib.loads(text), tomllib.loads(output)
        old_colors, new_colors = before.pop("colors"), after.pop("colors")
        self.assertEqual(before, after)
        self.assertEqual(new_colors["transparent_background_colors"], old_colors["transparent_background_colors"])
        self.assertEqual(new_colors["primary"]["dim_foreground"], "#888888")
        self.assertIn("opacity = 0.37 # transparency", output)
        self.assertEqual(theme.alacritty_text(output, colors), output)

    def test_inline_and_multiline_configs_are_not_damaged(self):
        for text in ('colors = {primary = {background = "#000000"}}\n',
                     '[env]\nVALUE = """\n[colors.primary]\nbackground = "#000000"\n"""\n'):
            with self.assertRaises(ValueError):
                theme.alacritty_text(text, theme.terminal_colors(self.palette))

    def test_backup_symlink_and_user_edits_survive(self):
        path = theme.terminal_paths()["alacritty"]
        path.parent.mkdir(parents=True)
        target = self.home / "dotfile.toml"
        target.write_text("[window]\nopacity = 0.42\n")
        path.symlink_to(target)
        theme.apply_terminal("alacritty", self.palette)
        self.assertTrue(path.is_symlink())
        self.assertEqual(target.with_name("dotfile.toml.pre-glueqs").read_text(), "[window]\nopacity = 0.42\n")
        target.write_text(target.read_text().replace("0.42", "0.27"))
        theme.apply_terminal("alacritty", theme.palette_from_seed("#b05070"))
        self.assertEqual(tomllib.loads(target.read_text())["window"]["opacity"], .27)

    def test_new_alacritty_inherits_system_transparency(self):
        system = self.home / "system/alacritty/alacritty.toml"
        system.parent.mkdir(parents=True)
        system.write_text("[window]\nopacity = 0.5\n")
        theme.apply_terminal("alacritty", self.palette)
        result = tomllib.loads(theme.terminal_paths()["alacritty"].read_text())
        self.assertEqual(result["general"]["import"], [str(system)])
        self.assertNotIn("window", result)

    def test_kitty_include_only_changes_colors(self):
        path = theme.terminal_paths()["kitty"]
        path.parent.mkdir(parents=True)
        text = "background_opacity 0.41\nfont_size 15\ninclude my-theme.conf\nmap ctrl+x quit\n"
        path.write_text(text)
        with patch.object(theme.os, "kill"):
            theme.apply_terminal("kitty", self.palette)
            theme.apply_terminal("kitty", self.palette)
        self.assertEqual(path.read_text(), text + "include glueqs-colors.conf\n")
        self.assertEqual(path.with_name("kitty.conf.pre-glueqs").read_text(), text)
        self.assertNotIn("background_opacity", (path.parent / "glueqs-colors.conf").read_text())

    def test_keep_text_only_changes_background(self):
        path = theme.terminal_paths()["alacritty"]
        path.parent.mkdir(parents=True)
        original = '[window]\nopacity = 0.5\n[colors.primary]\nforeground = "#aabbcc"\n[colors.normal]\nred = "#ee1111"\n'
        path.write_text(original)
        theme.apply_terminal("alacritty", self.palette, keep_text=True)
        expected = tomllib.loads(original)
        expected["colors"]["primary"]["background"] = self.palette["bg"]
        self.assertEqual(tomllib.loads(path.read_text()), expected)
        kitty = theme.terminal_paths()["kitty"]
        kitty.parent.mkdir(parents=True)
        kitty.write_text("background_opacity 0.5\nforeground #aabbcc\ncolor1 #ee1111\n")
        with patch.object(theme.os, "kill"):
            theme.apply_terminal("kitty", self.palette, keep_text=True)
            generated = (kitty.parent / "glueqs-colors.conf").read_text()
            self.assertNotIn("foreground", generated)
            self.assertNotIn("color1", generated)
            theme.apply_terminal("kitty", self.palette)
            previous = (kitty.parent / "glueqs-colors.conf").read_text()
            next_palette = theme.palette_from_seed("#ee3333")
            theme.apply_terminal("kitty", next_palette, keep_text=True)
            updated = (kitty.parent / "glueqs-colors.conf").read_text()
            self.assertEqual(updated, previous.replace("background " + self.palette["bg"], "background " + next_palette["bg"]))

    def test_invalid_palette_never_changes_terminal(self):
        path = theme.terminal_paths()["alacritty"]
        broken = copy.deepcopy(self.palette)
        broken["accent"] = "no colour"
        with self.assertRaises(ValueError):
            theme.apply_terminal("alacritty", broken)
        self.assertFalse(path.exists())


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Run the real QML services offscreen with isolated config, state and IPC."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib

from PIL import Image

source = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="glueqs-runtime-") as directory:
    root = Path(directory)
    config, state, runtime = (root / name for name in ("config", "state", "runtime"))
    for path in (config / "glueqs", config / "gluewc", config / "alacritty", state, runtime):
        path.mkdir(parents=True, exist_ok=True)
    runtime.chmod(0o700)
    shell = root / "shell"
    shell.mkdir()
    for pattern in ("*.qml", "*.js", "theme_tools.py"):
        for path in source.glob(pattern):
            shutil.copy2(path, shell / path.name)
    (shell / "shell.qml").write_text((source / "tests/runtime.qml").read_text().replace('import ".."', 'import "."'))
    (config / "glueqs/settings.json").write_text(json.dumps({
        "themeAlacritty": True, "themeKitty": False, "themeTerminalText": False,
        "themeWindowBorders": True, "themeScheme": "nothing"}))
    (config / "gluewc/config.conf").write_text("border_focus = 11223380\nborder_normal = 22334460\nnormal_mode_color = 445566aa\n")
    terminal = config / "alacritty/alacritty.toml"
    terminal.write_text('[window]\nopacity = 0.37\n[colors.primary]\nforeground = "#abcdef"\n[colors.normal]\nred = "#cf4444"\n')
    for name, color in (("red", "#e04242"), ("blue", "#4080b0"), ("green", "#40b080")):
        Image.new("RGB", (48, 48), color).save(root / (name + ".png"))
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_CONFIG_HOME=str(config),
        XDG_CONFIG_DIRS=str(root / "system"), XDG_STATE_HOME=str(state), XDG_RUNTIME_DIR=str(runtime),
        XDG_CURRENT_DESKTOP="", GLUE_TEST_IMAGES=str(root))
    env.pop("WAYLAND_DISPLAY", None)
    subprocess.run(["qs", "-p", str(shell), "--no-color"], env=env, check=True, timeout=20)
    result = tomllib.loads(terminal.read_text())
    assert result["window"]["opacity"] == .37
    assert result["colors"]["primary"]["foreground"] == "#abcdef"
    assert result["colors"]["normal"]["red"] == "#cf4444"
    assert result["colors"]["primary"]["background"] != "#000000"
    print("PASS: actual terminal output preserves text, ANSI colours and opacity")

# glueqs

[![license: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![quickshell](https://img.shields.io/badge/quickshell-required-7aa2f7.svg)](https://quickshell.org/)

glueqs is a desktop shell for [Quickshell](https://quickshell.org/), drawn in a
dot-matrix style: every label, number and icon is a grid of round dots rendered
on a canvas, on black with a single accent colour. It is the shell written
alongside [gluewc](https://github.com/vladbiber/gluewc) and the one that
compositor is developed against.

[![glueqs in use](https://raw.githubusercontent.com/vladbiber/gluewc/main/docs/media/glue-poster.jpg)](https://github.com/vladbiber/gluewc/blob/main/docs/media/glue-demo.mp4)

Click for a minute and a half of it in use — the bar, the panels and the dash
over the compositor's overview.

## What is in it

A bar on any screen edge, with widgets placed by three ordered zone lists, and
a panel behind most of them:

| Widget | Left click | Also |
| --- | --- | --- |
| `settings` | Settings panel: bar, clock, audio, weather, wallpaper, theme | |
| `launcher` | App launcher: type to filter, Enter or click to launch | |
| `workspaces` | Switch to that workspace | Occupied ones show, empty ones hide |
| `tray` | Activate the app | Middle click: secondary action. **Right click: the app's own menu, quit included** |
| `media` | Expanded player: spinning disc, dot equalizer, dotted timeline, 10-band EasyEffects EQ | Prev/play/next on the tile itself |
| `weather` | Forecast panel | Current conditions from wttr.in |
| `clock` | Month calendar, today boxed in the accent | 12h/24h, optional date |
| `notifs` | Notification history | Toasts appear on their own |
| `netspeed` | Live up/down rates | Read from `/proc/net/dev` |
| `network` | Wi-Fi list with connect and password entry, Bluetooth toggle and devices | |
| `volume` | Mixer: output devices, mic and per-app streams | Right click mutes, wheel changes volume |
| `battery` | Charge, health, power draw, time left and power profiles | Hidden when there is no battery |
| `power` | Session menu: logout, reboot, power off | Each entry arms first, then runs |

Plus the parts that appear on their own:

- Volume and brightness OSDs, with a configurable dwell time
- Notification toasts, with a full notification server behind them
- An overview dash — pinned apps, running apps, and an apps grid you can pin
  from — that appears while the compositor's overview is up
- A dot font that falls back to a plain Nerd Font label at the same cap height,
  so every widget keeps its layout with the dot rendering switched off

## Requirements

Quickshell is the only hard requirement; everything else is per feature and
degrades to a widget that simply does not appear.

| For | Needs |
| --- | --- |
| The shell itself | [Quickshell](https://quickshell.org/) with Qt 6 |
| Workspaces | The `Quickshell.DWL` module and a dwl-family compositor (gluewc, dwl) |
| Overview dash | gluewc, which publishes its overview state to `$XDG_STATE_HOME/gluewc/overview` |
| Volume, media, tray, notifications, Bluetooth | PipeWire, and the MPRIS, SNI and notification services Quickshell already speaks |
| Wi-Fi and Bluetooth panels | `nmcli`, `bluetoothctl` |
| Weather | `curl`, and a location set in the settings panel |
| Brightness | A backlight under `/sys/class/backlight`, plus `udevadm` to follow external changes |
| Equalizer presets | `easyeffects` |
| Wallpaper picker | `waypaper` (which drives swww and records the choice) |
| Session menu | `loginctl` |

## Install

The repository *is* the Quickshell config directory:

```sh
git clone https://github.com/vladbiber/glueqs.git ~/.config/quickshell/glueqs
qs -c glueqs
```

To start it with the session, under gluewc in `~/.config/gluewc/config.conf`:

```ini
autostart = qs -c glueqs
```

Any other compositor works the same way through its own autostart; the
workspace strip and the overview dash are the only parts that will stay away.

## Settings

The settings panel writes `settings.json` next to the config, and the file is
watched, so editing it by hand applies immediately as well.

| Key | Meaning |
| --- | --- |
| `barPosition` | `top`, `bottom`, `left`, `right` |
| `barLeft`, `barCenter`, `barRight` | Ordered widget names, comma separated |
| `barSolid` | Solid black bar instead of floating tiles |
| `accent` | Accent colour, `#rrggbb` |
| `scale` | UI scale, clamped to 0.8–1.4 |
| `dotFont` | Dot matrix text, or a plain font at the same size |
| `show*` | One switch per widget |
| `clock12h`, `showDate` | Clock format |
| `osdEnabled`, `osdDuration` | Volume and brightness OSDs |
| `volumeStep` | Wheel and key step, in percent |
| `weatherLocation`, `weatherInterval` | wttr.in query and refresh minutes |
| `eqEnabled`, `eqPreset`, `eqGains` | Media panel equalizer |
| `wallpaperDir` | Where the wallpaper picker starts, empty for `~/Pictures/Wallpapers` |
| `dockPinned`, `dockUsage` | Overview dash pins and launch counts |

If `clock` is in the centre zone it is pinned to the exact centre of the screen
and its centre-zone neighbours flank it, so the time stays put no matter what
else is on the bar.

## From outside

```sh
qs -c glueqs ipc call glueqs wallpaper   # open the settings panel on wallpapers
qs -c glueqs ipc call glueqs settings    # toggle the settings panel
qs -c glueqs ipc call glueqs close       # close whatever panel is open
```

Bound to a key, the first one gives the wallpaper picker a shortcut:

```ini
bind_insert = mod+w = spawn:qs -c glueqs ipc call glueqs wallpaper
```

## Layout of the source

Singletons hold the state (`Settings`, `Theme`, `Popups`, `Audio`, `Brightness`,
`Weather`, `Notifs`, `MediaService`, `Session`, `Overview`, `Tray`), `*Widget`
files are the bar tiles, `*Panel` and `*Popup` files are the windows behind
them, and `Dot*` plus `DotFont.js` are the drawing primitives everything else
is built from. `shell.qml` instantiates one of each per screen.

## gluewc

[gluewc](https://github.com/vladbiber/gluewc) is the compositor this was
written for: a dwl fork with BSP tiling, nine workspaces per monitor, scroll
and drift layouts, an animated overview and runtime configuration. glueqs runs
on other wlroots compositors, but only gluewc drives the workspace strip and
the overview dash. It is a recommendation, not a requirement — and the same
holds the other way round: gluewc is happy with waybar, another shell, or none.

## License

GPL-3.0-or-later, the same as gluewc. The look is inspired by Nothing OS; no
code or assets are taken from it — the dot font in `DotFont.js` is drawn glyph
by glyph in this repository.

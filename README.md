# glueqs

[![license: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![quickshell](https://img.shields.io/badge/quickshell-required-7aa2f7.svg)](https://quickshell.org/)

glueqs is a desktop shell for [Quickshell](https://quickshell.org/), drawn in a
dot-matrix style: every label, number and icon is a grid of round dots rendered
on a canvas, on black with a single accent colour. It is the shell written
alongside [gluewc](https://github.com/vladbiber/gluewc) and the one that
compositor is developed against.

![The media panel: album disc, dot equalizer, timeline and EQ presets](docs/media.png)

*The media panel: the reel disc carries the album art, the dots are the live
spectrum, and the right column is a 10-band EasyEffects equalizer.*

![The bar and the compositor overview with the dash](docs/glue-tour.webp)

*The bar stays put while the compositor's overview opens; the dash below it
only exists while the overview is up.*

## What is in it

A bar on any screen edge, with widgets placed by three ordered zone lists, and
a panel behind most of them:

| Widget | Left click | Also |
| --- | --- | --- |
| `settings` | Settings panel: bar, clock, audio, weather, wallpaper, theme | |
| `wallpaper` | (not a widget) The picker on `Super+W`; the shell paints the wallpaper itself | |
| `launcher` | App launcher: type to filter, Enter or click to launch | |
| `workspaces` | Switch to that workspace | Occupied ones show, empty ones hide; read from gluewc's state file, switched through `gluewc-msg`, so no extra Quickshell module is needed |
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

![The settings panel on its bar tab](docs/settings.png)

*Settings: every widget can be moved between the three zones, reordered or
switched off, and the whole thing is written back to `settings.json`.*

![The network panel with a Wi-Fi list](docs/network.png)

*Networks, with the connected one boxed in the accent; the lock marks the ones
that will ask for a password. Bluetooth sits underneath.*

![The tray menu open under a tray icon](docs/tray-menu.png)

*Right click on a tray icon opens the app's own menu — checkboxes, disabled
entries, submenus and quit — drawn in the shell's own style.*

![The app launcher](docs/launcher.png)

*The launcher: type to filter, most-launched first.*

Plus the parts that appear on their own:

- Volume and brightness OSDs, with a configurable dwell time
- Notification toasts, with a full notification server behind them
- An overview dash — pinned apps, running apps, and an apps grid you can pin
  from — that appears while the compositor's overview is up
- A dot font that falls back to a plain Nerd Font label at the same cap height,
  so every widget keeps its layout with the dot rendering switched off

The rest of the panels, in the same order as the bar:

| | |
| --- | --- |
| ![Calendar](docs/calendar.png) | ![Volume mixer](docs/volume.png) |
| Calendar, today boxed in the accent | Mixer: outputs, mic and per-app streams |
| ![Battery](docs/battery.png) | ![Session menu](docs/session.png) |
| Battery, health and power profiles | Session menu, each entry arms before it runs |

## Requirements

Quickshell is the only hard requirement; everything else is per feature and
degrades to a widget that simply does not appear.

| For | Needs |
| --- | --- |
| The shell itself | [Quickshell](https://quickshell.org/) 0.2 or newer with Qt 6 — the one your distribution packages is fine |
| Workspaces | gluewc, which writes `$XDG_STATE_HOME/gluewc/workspaces` and installs `gluewc-msg` |
| Overview dash | gluewc, which publishes its overview state to `$XDG_STATE_HOME/gluewc/overview` |
| Live spectrum in the media panel | The `PwAudioSpectrum` type, which only the noctalia-qs fork of Quickshell has; without it the panel animates a synthetic equalizer |
| Volume, media, tray, notifications, Bluetooth | PipeWire, and the MPRIS, SNI and notification services Quickshell already speaks |
| Wi-Fi and Bluetooth panels | `nmcli`, `bluetoothctl` |
| Weather | `curl`, and a location set in the settings panel |
| Brightness | A backlight under `/sys/class/backlight`, plus `udevadm` to follow external changes |
| Equalizer presets | `easyeffects` |
| Wallpaper | Nothing: the shell paints it itself, on a background layer per screen |
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
| `wallpaper`, `wallpaperPerMonitor` | The picture on every screen, and `name=path;name=path` overrides for single screens |
| `wallpaperDir` | Where the wallpaper picker starts, empty for `~/Pictures/Wallpapers` |
| `wallpaperFill` | `crop`, `fit`, `stretch`, `center` or `tile` |
| `wallpaperTransition`, `wallpaperTransitionMs` | `fade`, `wipe`, `slide`, `zoom` or `random`, and how long it takes |
| `wallpaperRandomMin` | Minutes between random picks from the folder, 0 for never |
| `wallpaperSolid` | The colour behind the picture, or alone when there is none |
| `dockPinned`, `dockUsage` | Overview dash pins and launch counts |

If `clock` is in the centre zone it is pinned to the exact centre of the screen
and its centre-zone neighbours flank it, so the time stays put no matter what
else is on the bar.

## From outside

```sh
qs -c glueqs ipc call glueqs wallpaper            # toggle the wallpaper picker
qs -c glueqs ipc call glueqs setwallpaper PATH    # put PATH on every screen
qs -c glueqs ipc call glueqs nextwallpaper        # the next picture in the folder
qs -c glueqs ipc call glueqs randomwallpaper      # a random one
qs -c glueqs ipc call glueqs settings             # toggle the settings panel
qs -c glueqs ipc call glueqs close                # close whatever panel is open
```

Bound to a key, the first one gives the wallpaper picker a shortcut:

```ini
bind_insert = mod+w = spawn:qs -c glueqs ipc call glueqs wallpaper
```

## Wallpaper

The shell draws the wallpaper itself, so there is no swww, waypaper or swaybg
to run and nothing to keep in step: pick a picture in the panel (`Super+W`
under gluewc, or the settings panel's WALLPAPER tab) and it goes into
`settings.json` like every other setting. The picker shows the folder as a
grid with the picture on screen marked in the accent, walks into subfolders,
applies to every screen or only the one it is on, and sets the fill mode, the
transition (fade, wipe, slide, zoom, or a random one each time) and an optional
shuffle timer. Arrows move, Enter applies, `R` shuffles, `N` is next,
Backspace goes up a folder, Escape closes. The picture is decoded off the main
thread and the transition only starts once it is there.

## Layout of the source

Singletons hold the state (`Settings`, `Theme`, `Popups`, `Audio`, `Brightness`,
`Weather`, `Notifs`, `MediaService`, `Session`, `Overview`, `Tray`, `WsState`,
`Wallpapers`), `Wallpaper` is the background window per screen, `*Widget`
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

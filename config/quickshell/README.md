# Hecate shell

The Quickshell half of Hecate: a bar, desktop widgets, and the panels behind them (app launcher, notifications, Wi-Fi and Bluetooth, power menu, clipboard history, wallpaper picker). Everything takes its colors from the wallpaper through matugen, and everything is set from one file, `~/.config/hecate/hecate.toml`.

- [Settings](#settings)
- [Bar](#bar)
- [Desktop widgets](#desktop-widgets)
- [Colors](#colors)
- [Wallpaper and theming](#wallpaper-and-theming)
- [Keys and IPC](#keys-and-ipc)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Layout of this folder](#layout-of-this-folder)

## Settings

All settings live in `~/.config/hecate/hecate.toml`. The shell rereads it when you save, so changes show up without a restart. Anything you leave out falls back to the default shown in this file. If the TOML has a syntax error, the shell keeps the last good settings and logs the error.

```toml
[theme]
mode = "dynamic"        # "dynamic": new wallpaper → new colors. "static": colors stay as they are
font = "Inter"          # text font; icons always use Symbols Nerd Font

[wallpaper]
dir = "~/Pictures/Wallpapers"   # images the picker shows (top level only, no subfolders)
```

## Bar

Pick widgets for each section of the bar by name. Each name loads `modules/bar/widgets/<Name>.qml`, so adding your own widget is a matter of dropping a file there and listing it.

```toml
[bar]
left   = ["launcher", "workspaces", "windows"]
center = ["clock"]
right  = ["media", "volume", "battery", "tray", "connectivity", "notifications", "clipboard", "wallpaper", "power"]
```

| name | shows | mouse |
|---|---|---|
| `launcher` | Arch logo | click: app launcher |
| `workspaces` | a dot per workspace on this monitor | click: switch workspace |
| `windows` | open apps; the focused one with its title | click: focus · middle: close · scroll: cycle |
| `title` | focused window's icon and title | — |
| `clock` | date and time | — |
| `media` | play state, track and artist; hidden with no player | click: play/pause · scroll: previous/next |
| `volume` | output volume | click: mute · scroll: volume |
| `stats` | CPU, memory, GPU, temperature | — |
| `battery` | charge; hidden without a laptop battery | — |
| `caffeine` | idle inhibitor | click: keep the screen awake |
| `tray` | system tray icons | click: activate · right: menu · middle: secondary |
| `connectivity` | Wi-Fi/Ethernet and Bluetooth state | click: Wi-Fi & Bluetooth panel |
| `notifications` | bell and unread count | click: notification history |
| `clipboard` | clipboard icon | click: clipboard history |
| `wallpaper` | wallpaper icon | click: wallpaper picker |
| `power` | power icon | click: power menu |

### Widget options

Each widget reads its own `[widgets.<name>]` table. Every widget accepts `color`, `background` (see [Colors](#colors)) and `right_click`, a shell command run on right-click:

```toml
[widgets.stats]
right_click = "kitty -e btop"
```

Options specific to one widget, with their defaults:

```toml
[widgets.clock]
format = "ddd d MMM  ·  hh:mm"   # Qt date format

[widgets.windows]
scope = "workspace"   # which windows: "workspace", "monitor" or "all"
titles = "active"     # whose title shows: "none", "active" or "all"; hovering always shows it
max_title = 24        # characters before the title is cut

[widgets.title]
max_title = 48

[widgets.media]
max_title = 32

[widgets.volume]
step = 5              # % per scroll notch
max = 100             # volume cap in %, can go above 100
percent = true        # show the number next to the icon

[widgets.stats]
show = ["cpu", "mem"] # any of "cpu", "mem", "gpu", "temp"
                      # each turns tertiary above 70% and error above 90%

[widgets.battery]
low = 15              # % at which it turns red
```

Panels are styled the same way: `[widgets.launcher]`, `[widgets.notifications]`, `[widgets.connectivity]`, `[widgets.power]`, `[widgets.clipboard]` and `[widgets.wallpaper]` take `color` and `background`.

## Desktop widgets

Cards that sit on the wallpaper, behind your windows. They're arranged in two columns, top to bottom, and each name loads `modules/desktop/widgets/<Name>.qml`.

```toml
[desktop]
monitor = ""                          # output name such as "HDMI-A-1"; empty = first monitor
left  = ["clock", "weather", "audio"]
right = ["system", "github", "apps"]
```

| name | shows | needs |
|---|---|---|
| `clock` | hour and minute rings, date, day and year progress | — |
| `weather` | current conditions, the next 12 hours, a 5-day forecast with each day's range | internet ([Open-Meteo](https://open-meteo.com), no API key) |
| `audio` | the active media player: cover art, seek bar, controls, and a visualizer while audio plays | an MPRIS player, `cava` |
| `system` | CPU, memory and GPU gauges, per-thread load, VRAM, disk, GPU power and fan | — (reads `/proc` and sysfs; GPU details are AMD only) |
| `github` | your contribution calendar, as many weeks as fit; hover a day for its count | a GitHub token |
| `apps` | launcher tiles | — |

Options go in `[desktop.<name>]`. Every card also accepts `color` and `background`.

```toml
[desktop.clock]
twelve_hour = true

[desktop.weather]
location = ""        # city name; empty = guess from your IP address
units = "metric"     # or "imperial"

[desktop.github]
user = "Nurysso"
token_file = "~/.config/tokens/gpat.txt"   # a token with the read:user scope, nothing else in the file

[desktop.apps]
apps = ["firefox", "kitty", "org.gnome.Nautilus"]   # desktop entry ids or shell commands
```

To find an app's desktop entry id, look in `/usr/share/applications`: the id is the file name without `.desktop`.

## Colors

`color` and `background` accept either:

- an M3 color name, which keeps following the wallpaper, or
- any fixed color, such as `"#ff8800"` or `"tomato"`.

Without an override, colors come from the theme.

```toml
[widgets.power]
color = "error"               # icon or accent color
background = "#2b1a1a"        # pill, panel or card background
```

M3 color names: `primary` `on_primary` `primary_container` `on_primary_container`, the same four for `secondary`, `tertiary` and `error`, plus `background` `on_background` `surface` `on_surface` `surface_variant` `on_surface_variant` `surface_container_lowest` `surface_container_low` `surface_container` `surface_container_high` `surface_container_highest` `outline` `outline_variant` `inverse_surface` `inverse_on_surface` `inverse_primary` `shadow` `scrim`.

## Wallpaper and theming

`~/.config/hecate/scripts/set-wallpaper.sh <image>` is the only thing that changes the wallpaper. The picker calls it, and you can run it yourself. It:

1. points `~/.cache/hecate/wallpaper` at the image and restarts hyprpaper, which reads that link through `hypr/hyprpaper.conf`. hyprpaper 0.8 ignores the old `hyprctl hyprpaper wallpaper` command, so a restart is how the new image gets loaded, and why the screen may flash once.
2. in `dynamic` mode, runs `matugen image` and writes the colors to `~/.cache/hecate/theme.json`.

The shell watches `theme.json` and fades to the new colors. Any templates in `~/.config/matugen/config.toml` are rendered on the same run.

## Keys and IPC

| keys | opens |
|---|---|
| `SUPER+D` | app launcher |
| `SUPER+V` | clipboard history |
| `SUPER+SHIFT+N` | notifications |
| `SUPER+N` | Wi-Fi & Bluetooth |
| `SUPER+SHIFT+Q` | power menu |
| `SUPER+CTRL+W` | wallpaper picker |

Inside a panel, the arrow keys move, Enter picks, and Esc or a click outside closes it. In the clipboard, Delete with the cursor at the end of the search text removes the selected entry. The wallpaper picker closes once the wallpaper is applied.

Any panel can be toggled from a script or your own keybind:

```
qs ipc call hecate toggle <launcher|notifications|connectivity|power|clipboard|wallpaper>
```

## Requirements

- `quickshell`, `hyprpaper`, `matugen`, `jq`
- `python` 3.11 or newer (reads the TOML)
- `cliphist` and `wl-clipboard`
- a Symbols Nerd Font
- optional: NetworkManager for the Wi-Fi panel and BlueZ for Bluetooth (without them the panel says so), PipeWire for `volume`, UPower for `battery`, `cava` for the audio visualizer

Don't run swaync or any other notification daemon: this shell is the notification server.

## Troubleshooting

**A change to a `.qml` file doesn't show up.** Quickshell reloads on save, but its file watcher can lose track after files are replaced in bulk (for example by `cp -r`). Restart it: `pkill -x quickshell; quickshell & disown`.

**The log.** `qs log` prints the running shell's log, including QML errors with file and line.

**The wallpaper picker is empty.** It only lists images directly inside `[wallpaper] dir`, not in subfolders.

**Clicking a workspace does nothing.** Hecate's Hyprland config is Lua, which only accepts Lua-style dispatches such as `hl.dsp.focus({ workspace = "2" })`. The `workspaces` widget sends that form; custom widgets should too.

## Layout of this folder

```
shell.qml        entry point and IPC
config/          Config (reads hecate.toml), Theme (M3 colors and icons), GlobalStates (open panel, caffeine)
components/      building blocks: Panel, Pill, Card, Ring, Meter, Tile, SearchField, Toggle, StateLayer, ...
services/        shared state: Notifs (notification server), Cliphist, Net, SysStats (CPU/memory/GPU/disk)
modules/
  bar/           the bar, and bar/widgets with one file per bar widget
  desktop/       the desktop layer, desktop/widgets with one file per card, and cava.conf
  launcher/ notifications/ connectivity/ power/ clipboard/ wallpaper/   the panels
```

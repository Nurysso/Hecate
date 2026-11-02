# Hecate shell

The Quickshell half of Hecate: a bar, desktop widgets, and the panels behind them (app launcher, control center, notifications, calendar, Wi-Fi and Bluetooth, power menu, clipboard history, emoji picker, wallpaper picker), plus notification popups and an on-screen display for volume. Everything sits on frosted glass that Hyprland blurs, takes its colors from the wallpaper through matugen, and is set from one file, `~/.config/hecate/hecate.toml`.

- [Settings](#settings)
- [Bar](#bar)
- [Panels](#panels)
- [Notifications and the OSD](#notifications-and-the-osd)
- [Desktop widgets](#desktop-widgets)
- [Colors](#colors)
- [Wallpaper and theming](#wallpaper-and-theming)
- [Keys, shortcuts and IPC](#keys-shortcuts-and-ipc)
- [How it works with Hyprland](#how-it-works-with-hyprland)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Layout of this folder](#layout-of-this-folder)

## Settings

All settings live in `~/.config/hecate/hecate.toml`. The shell rereads it when you save, so changes show up without a restart, and only the parts you changed are rebuilt. Anything you leave out falls back to the default shown here. A value the shell can't use (a word where a number goes, a style that doesn't exist) falls back to its default and says so in `qs log`; if the TOML itself has a syntax error, the shell keeps the last good settings.

```toml
[theme]
mode = "dynamic"        # "dynamic": new wallpaper → new colors. "static": colors stay as they are
font = "Inter"          # text font; icons always use Symbols Nerd Font
rounding = 16           # corner radius in px, 0 for square corners
opacity = 0.78          # how solid the bar, panels and cards are, 0 (clear) to 1 (opaque); 0.94 without blur
blur = true             # frosted glass: Hyprland blurs what's behind them
border = true           # a hairline edge around them
scale = 1.0             # size of everything (text, icons, spacing); try 1.15 on a high-resolution screen
animations = true
animation_speed = 1.0   # 2 is twice as fast

[wallpaper]
dir = "~/Pictures/Wallpapers"   # images the picker shows (top level only, no subfolders)
```

## Bar

```toml
[bar]
position = "top"        # "top" or "bottom"
style = "islands"       # see below
height = 40
# margin = 6            # space around the bar in px; leave out to match Hyprland's gaps_out
# monitors = ["DP-1"]   # outputs that get a bar; leave out for all of them
left   = ["launcher", "workspaces", "windows"]
center = ["clock"]
right  = ["media", "tray", "status", "notifications", "power"]
```

`style` picks the shape:

- `islands`: each section (left, center, right) floats on its own piece of glass, sized to what's in it. A section with nothing to show disappears.
- `floating`: one rounded bar, inset from the screen edges.
- `full`: one bar running edge to edge.

Without `margin`, the gap around the bar is Hyprland's `general:gaps_out`, so the bar lines up with your tiled windows, and it follows the setting when Hyprland reloads.

Pick widgets for each section by name. Each name loads `modules/bar/widgets/<Name>.qml`, so adding your own widget is a matter of dropping a file there and listing it. Buttons that open a panel stay lit while it's open, and the panel hangs right beneath them. Most widgets show a tooltip when you hover them.

| name | shows | mouse |
|---|---|---|
| `launcher` | Arch logo | click: app launcher |
| `workspaces` | this monitor's workspaces; see `style` below | click: switch · scroll: next/previous |
| `windows` | open apps; the focused one with its title | click: focus · middle: close · scroll: cycle |
| `title` | focused window's icon and title | — |
| `clock` | time and date | click: calendar |
| `media` | cover, track and artist; hidden with no player | click: play/pause · scroll: previous/next · middle: raise the player |
| `volume` | output volume | click: mute · scroll: volume · middle: control center |
| `stats` | CPU, memory, GPU, temperature | — |
| `battery` | charge; hidden without a laptop battery | hover: time left |
| `caffeine` | idle inhibitor | click: keep the screen awake |
| `tray` | system tray icons | click: activate · right: menu · middle: secondary |
| `status` | network, Bluetooth, volume and battery icons together | click: control center · scroll: volume |
| `connectivity` | Wi-Fi/Ethernet and Bluetooth state | click: Wi-Fi & Bluetooth panel |
| `keyboard` | keyboard layout; hidden with only one | click: next layout |
| `submap` | the active Hyprland submap; hidden otherwise | click: leave it |
| `notifications` | bell with a count | click: notification history |
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
[widgets.launcher]
icon = "arch"         # "arch", "owl", or any glyph (clipboard, wallpaper and power take icon too)

[widgets.workspaces]
style = "dots"        # "dots", "numbers", or "icons" (the apps on each workspace)
count = 0             # always show workspaces 1..count, even empty ones
special = true        # a star for an open special workspace (scratchpad); click it to tuck it away

[widgets.windows]
scope = "workspace"   # which windows: "workspace", "monitor" or "all"
titles = "active"     # whose title shows: "none", "active" or "all"; hovering always shows it
max_title = 24        # characters before the title is cut

[widgets.title]
max_title = 48

[widgets.clock]
time = "hh:mm"        # Qt date formats
date = "ddd d MMM"    # "" hides the date
# format = "ddd d MMM  ·  hh:mm"   # older single-label form, still works

[widgets.media]
max_title = 32

[widgets.volume]
step = 5              # % per scroll notch or volume key
max = 100             # volume cap in %, can go above 100
percent = true        # show the number next to the icon

[widgets.stats]
show = ["cpu", "mem"] # any of "cpu", "mem", "gpu", "temp"
                      # each turns tertiary above 70% and error above 90%

[widgets.battery]
low = 15              # % at which it turns red
```

## Panels

Panels that belong to a bar widget drop out of the bar beneath it; the rest open in the middle of the screen. A click outside or Esc closes any of them. While a panel hangs from the bar, clicking another bar widget switches straight to its panel.

| panel | what's in it | opened by |
|---|---|---|
| `control` | quick toggles (Wi-Fi, Bluetooth, do not disturb, keep awake, power mode, game mode), volume and microphone sliders with a device picker, what's playing, batteries of connected devices | `status` widget |
| `notifications` | notification history, do not disturb, clear all | `notifications` widget |
| `calendar` | the month, today marked; scroll or the arrows change month | `clock` widget |
| `connectivity` | Wi-Fi networks (click to join, with a password prompt) and Bluetooth devices | `connectivity` widget, or the arrows on the control center's tiles |
| `launcher` | apps, the ones you use most first; type a sum such as `12*4` and Enter copies the answer | `launcher` widget, `SUPER+D` |
| `clipboard` | clipboard history, with thumbnails for images | `clipboard` widget, `SUPER+V` |
| `emoji` | emoji search, recent picks first | `SUPER+ALT+E` |
| `wallpaper` | the images in `[wallpaper] dir` | `wallpaper` widget, control center, `SUPER+CTRL+W` |
| `power` | lock, suspend, log out, restart, shut down | `power` widget, `SUPER+SHIFT+Q` |

In the control center, click a slider's icon to mute, and the arrow beside it to switch the output or input device. Game mode turns off Hyprland's animations, blur, shadows, gaps and rounding; turning it off reloads your Hyprland config to bring them back. Power mode needs power-profiles-daemon.

Inside a panel, the arrow keys move, Enter picks, and Esc closes it. The emoji picker copies the emoji you pick with `wl-copy`; type words from its name (e.g. "fire", "heart eyes") to filter. In the clipboard, Delete with the cursor at the end of the search text removes the selected entry. The wallpaper picker closes once the wallpaper is applied.

Panels take `color` (their accent) and `background` too, in `[widgets.<panel>]`.

## Notifications and the OSD

This shell is the notification server. New notifications pop up below the bar and also go to the history. A popup counts down along its bottom edge (hovering pauses it), can be swiped sideways to put it away, and runs the app's default action when clicked. Critical ones stay until you dismiss them. Do not disturb (bell button in the history, or the control center) keeps popups back.

When the volume or microphone changes, whether from the keys, an app or the control center, a small pill shows the new level.

```toml
[widgets.notifications]
popup = "top-right"   # "top-right", "top", "top-left", "bottom-right", "bottom" or "bottom-left"
timeout = 5           # seconds a popup stays (an app can ask for longer)
max = 4               # popups shown at once

[widgets.osd]
position = "bottom"   # "bottom" or "top"
enabled = true
```

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

Without an override, colors come from the theme. Backgrounds keep the glass look: they're drawn at `[theme] opacity`.

```toml
[widgets.power]
color = "error"               # icon or accent color
background = "#2b1a1a"        # button, panel or card background
```

M3 color names: `primary` `on_primary` `primary_container` `on_primary_container`, the same four for `secondary`, `tertiary` and `error`, plus `background` `on_background` `surface` `on_surface` `surface_variant` `on_surface_variant` `surface_container_lowest` `surface_container_low` `surface_container` `surface_container_high` `surface_container_highest` `outline` `outline_variant` `inverse_surface` `inverse_on_surface` `inverse_primary` `shadow` `scrim`.

## Wallpaper and theming

`~/.config/hecate/scripts/set-wallpaper.sh <image>` is the only thing that changes the wallpaper. The picker calls it, and you can run it yourself. It:

1. points `~/.cache/hecate/wallpaper` at the image and fades to it with `awww img`. On login, Hyprland's autostart starts `awww-daemon` on black and fades that link back in, so the desktop rises out of hecate-sddm's fade.
2. in `dynamic` mode, runs `matugen image` and writes the colors to `~/.cache/hecate/theme.json`.

The shell watches `theme.json` and fades to the new colors. Any templates in `~/.config/matugen/config.toml` are rendered on the same run.

## Keys, shortcuts and IPC

| keys | opens |
|---|---|
| `SUPER+D` | app launcher |
| `SUPER+V` | clipboard history |
| `SUPER+ALT+E` | emoji picker |
| `SUPER+SHIFT+N` | notifications |
| `SUPER+N` | Wi-Fi & Bluetooth |
| `SUPER+SHIFT+Q` | power menu |
| `SUPER+CTRL+W` | wallpaper picker |

The volume, microphone and media keys are handled by the shell too.

Hecate's binds reach the shell through Hyprland's global shortcuts, so a key press costs no process at all. The shell registers these under the app id `hecate`:

- each panel by name: `launcher`, `control`, `notifications`, `calendar`, `connectivity`, `power`, `clipboard`, `emoji`, `wallpaper` (toggles it)
- `volume-up`, `volume-down`, `volume-mute`, `mic-mute`
- `media-play-pause`, `media-next`, `media-previous`, `media-stop`
- `dnd`, `caffeine`

Bind them in `configs/keybinds.lua`:

```lua
hl.bind("SUPER + A", hl.dsp.global("hecate:control"))
```

They're also there from scripts and the command line:

```
qs ipc call hecate toggle <panel>      # or: open <panel>, close
qs ipc call hecate volume +5           # -5, or mute
qs ipc call hecate mic                 # mute or unmute the microphone
qs ipc call hecate media play-pause    # next, previous, stop
qs ipc call hecate dnd                 # do not disturb on/off
qs ipc call hecate caffeine            # keep awake on/off
```

## How it works with Hyprland

The shell talks to Hyprland over its IPC socket (the one `hyprctl` uses) and listens to its events, rather than polling:

- **Dispatching.** Hecate's Hyprland config is Lua, which only accepts Lua-style dispatches such as `hl.dsp.focus({ workspace = "2" })`. `services/Hypr.qml` checks which language Hyprland is running and sends the right form, so workspace switching keeps working with a classic `hyprland.conf` too. Custom widgets should go through it (`Hypr.dispatch(lua, classic)`).
- **Layer rules.** The shell animates its own windows, so on start (and again whenever Hyprland reloads its config, which clears them) it runs `hyprctl eval` to turn off Hyprland's layer animations for the `hecate-*` namespaces. Nothing needs adding to your Hyprland config.
- **Blur.** Each surface tells Hyprland its exact shape through the `ext-background-effect` protocol, so the blur follows the rounded glass, even while a panel slides out. It uses Hyprland's `decoration:blur` settings.
- **Gaps.** The bar's margin follows `general:gaps_out` (unless `[bar] margin` is set) and updates when the config reloads or game mode changes it.
- **Keyboard layouts, submaps and special workspaces** come from Hyprland's `activelayout`, `submap` and `activespecial` events, after one `hyprctl` query at start.

## Requirements

- `quickshell` 0.3 or newer, Hyprland 0.55 or newer (Lua config), `awww`, `matugen`, `jq`
- `python` 3.11 or newer (reads the TOML)
- `cliphist` and `wl-clipboard` (the emoji picker also needs an emoji font such as `noto-fonts-emoji`)
- a Symbols Nerd Font, and Inter (`inter-font`) for text
- optional: NetworkManager for the Wi-Fi panel and BlueZ for Bluetooth (without them the panel says so), PipeWire for volume, UPower for `battery`, power-profiles-daemon for the power mode toggle, `cava` for the audio visualizer

Don't run swaync or any other notification daemon: this shell is the notification server.

## Troubleshooting

**A change to a `.qml` file doesn't show up.** Quickshell reloads on save, but its file watcher can lose track after files are replaced in bulk (for example by `cp -r`). Restart it: `pkill -x quickshell; quickshell & disown`.

**The log.** `qs log` prints the running shell's log, including QML errors with file and line, and any hecate.toml value that was ignored.

**No blur.** Check `decoration:blur:enabled` in Hyprland (game mode turns it off) and `[theme] blur`. Without blur, `[theme] opacity` defaults to a more solid 0.94.

**A bar widget is missing.** If its name has a typo, `qs log` says which one. Some widgets hide themselves when there's nothing to show: `media` without a player, `battery` on a desktop, `tray` when empty, `keyboard` with one layout, `submap` outside a submap.

**The wallpaper picker is empty.** It only lists images directly inside `[wallpaper] dir`, not in subfolders.

**Clicking a workspace does nothing.** Custom widgets that dispatch should go through `Hypr.dispatch`; a plain `workspace 2` dispatch is rejected by a Lua config.

**Trying settings without touching your own file.** `HECATE_CONFIG=/path/to/test.toml quickshell` runs the shell on another hecate.toml.

## Layout of this folder

```
shell.qml        entry point: windows, IPC and global shortcuts
config/          Config (reads hecate.toml), Theme (colors, sizes, glass, motion, icons), GlobalStates (open panel, toggles)
components/      building blocks: Panel, Glass, Pill, Card, Slider, QuickToggle, Tile, SearchField, Tooltip, ...
services/        shared state: Hypr (Hyprland), Audio, Players (media), Notifs (notification server), Net,
                 Cliphist, Emojis, Launches (launcher history), SysStats (CPU/memory/GPU/disk)
modules/
  bar/           the bar, and bar/widgets with one file per bar widget
  desktop/       the desktop layer, desktop/widgets with one file per card, and cava.conf
  notifications/ popups, history and the card both use
  osd/           the volume and microphone display
  control/ calendar/ launcher/ connectivity/ power/ clipboard/ emoji/ wallpaper/   the panels
```

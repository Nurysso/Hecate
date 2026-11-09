<div align="center">

# Hecate Quickshell

<a href="https://quickshell.org"><img src="../../.github/readme/chip-quickshell.svg" height="28" alt="Quickshell 0.3+"></a>
<a href="https://hyprland.org"><img src="../../.github/readme/chip-hyprland-lua.svg" height="28" alt="Hyprland 0.55+, Lua config"></a>
<a href="#-colors"><img src="../../.github/readme/chip-colors.svg" height="28" alt="Material You colors"></a>
<a href="#%EF%B8%8F-configure-everything"><img src="../../.github/readme/chip-config.svg" height="28" alt="Configured from hecate.toml"></a>

<img src="https://github.com/user-attachments/assets/c1ed0b82-c60b-46e8-89c5-869eab4e5fac" width="100%" alt="The Hecate shell: the bar and desktop cards on a pink wallpaper">

[Look](#-the-look) · [Bar](#-the-bar) · [Panels](#%EF%B8%8F-panels) · [Desktop](#%EF%B8%8F-desktop-widgets) · [Configure](#%EF%B8%8F-configure-everything) · [Hyprland](#-built-for-hyprland) · [Keys](#%EF%B8%8F-keys-shortcuts-and-ipc) · [Help](#-troubleshooting)

</div>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## ✨ What you get

<table>
<tr>
<td width="33%" valign="top">

### 🧊 Real glass

Every surface tells Hyprland its exact rounded shape, so the blur sits under the glass and nowhere else, even while a panel slides out of the bar.

</td>
<td width="33%" valign="top">

### 🎨 Wallpaper colors

Pick a wallpaper and matugen recolors the whole shell, GTK, Qt and your prompt. The shell fades to the new palette.

</td>
<td width="33%" valign="top">

### 📜 One file

Look, layout and behaviour all live in `hecate.toml`. Save it and the shell updates on the spot; a typo falls back to the default and tells you.

</td>
</tr>
<tr>
<td valign="top">

### ⚡ Wired into Hyprland

Keybinds arrive through Hyprland's global shortcuts, state comes from its event socket, and the bar lines up with your window gaps.

</td>
<td valign="top">

### 🎛️ A control center

Wi-Fi, Bluetooth, do not disturb, keep awake, power mode and game mode, plus volume and mic with device switching.

</td>
<td valign="top">

### 🔔 It's your notifier

Popups you can swipe away, a history with do not disturb, and an on-screen pill when the volume changes.

</td>
</tr>
</table>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🪟 The look

Three shapes for the bar, set with `[bar] style`. Each one can sit at the top or bottom of the screen.

<img src="https://github.com/user-attachments/assets/79045ae8-39cf-4352-a023-ecae1fc05230" width="100%" alt="The three bar styles: islands, floating and full">

| `islands` (default)                                                                      | `floating`                                   | `full`                    |
| :--------------------------------------------------------------------------------------- | :------------------------------------------- | :------------------------ |
| Each section floats on its own glass, sized to what's in it; an empty section disappears | One rounded bar, inset from the screen edges | One bar from edge to edge |

The glass itself is tuned in `[theme]`:

```toml
[theme]
mode = "dynamic"        # "static" keeps the colors when the wallpaper changes
font = "Inter"          # text font; icons use Symbols Nerd Font
rounding = 16           # corner radius in px, 0 for square corners
opacity = 0.78          # 0 (clear) to 1 (opaque); 0.94 without blur
blur = true             # Hyprland blurs what's behind the glass
border = true           # a hairline edge
scale = 1.0             # text, icons and spacing; try 1.15 on a high-resolution screen
animations = true
animation_speed = 1.0   # 2 is twice as fast
```

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🧭 The bar

```toml
[bar]
position = "top"        # "top" or "bottom"
style = "islands"       # "islands", "floating" or "full"
height = 40
# margin = 6            # leave out to match Hyprland's gaps_out
# monitors = ["DP-1"]   # leave out for every monitor
left   = ["launcher", "workspaces", "windows"]
center = ["clock"]
right  = ["media", "tray", "status", "notifications", "power"]
```

List widgets by name. Each name loads `modules/bar/widgets/<Name>.qml`, so your own widget is just a file dropped in there. Buttons that open a panel stay lit while it's open, the panel hangs right beneath them, and most widgets show a tooltip on hover.

| widget          | shows                                                | mouse                                                       |
| --------------- | ---------------------------------------------------- | ----------------------------------------------------------- |
| `launcher`      | Arch logo                                            | click: app launcher                                         |
| `workspaces`    | this monitor's workspaces                            | click: switch · scroll: next/previous                       |
| `windows`       | open apps; the focused one with its title            | click: focus · middle: close · scroll: cycle                |
| `title`         | focused window's icon and title                      | —                                                           |
| `clock`         | time and date                                        | click: calendar                                             |
| `media`         | cover, track and artist; hidden with no player       | click: play/pause · scroll: skip · middle: raise the player |
| `volume`        | output volume                                        | click: mute · scroll: volume · middle: control center       |
| `stats`         | CPU, memory, GPU, temperature                        | —                                                           |
| `battery`       | charge; hidden without a laptop battery              | hover: time left                                            |
| `caffeine`      | idle inhibitor                                       | click: keep the screen awake                                |
| `tray`          | system tray icons                                    | click: activate · right: menu · middle: secondary           |
| `status`        | network, Bluetooth, volume and battery in one button | click: control center · scroll: volume                      |
| `connectivity`  | Wi-Fi/Ethernet and Bluetooth state                   | click: Wi-Fi & Bluetooth panel                              |
| `keyboard`      | keyboard layout; hidden with only one                | click: next layout                                          |
| `submap`        | the active Hyprland submap; hidden otherwise         | click: leave it                                             |
| `notifications` | bell with a count                                    | click: notification history                                 |
| `clipboard`     | clipboard icon                                       | click: clipboard history                                    |
| `wallpaper`     | wallpaper icon                                       | click: wallpaper picker                                     |
| `power`         | power icon                                           | click: power menu                                           |

<details>
<summary><b>Widget options</b>, with their defaults</summary>

<br>

Every widget reads its own `[widgets.<name>]` table and accepts `color`, `background` (see [Colors](#-colors)) and `right_click`, a shell command run on right-click:

```toml
[widgets.stats]
right_click = "kitty -e btop"
```

```toml
[widgets.launcher]
icon = "arch"         # "arch", "owl", or any glyph (clipboard, wallpaper and power take icon too)

[widgets.workspaces]
style = "dots"        # "dots", "numbers", or "icons" (the apps on each workspace)
count = 0             # always show workspaces 1..count, even empty ones
special = true        # a star for an open special workspace; click it to tuck it away

[widgets.windows]
scope = "workspace"   # "workspace", "monitor" or "all"
titles = "active"     # "none", "active" or "all"; hovering always shows it
max_title = 24

[widgets.title]
max_title = 48

[widgets.clock]
time = "hh:mm"        # Qt date formats
date = "ddd d MMM"    # "" hides the date
# format = "ddd d MMM  ·  hh:mm"   # the older single-label form still works

[widgets.media]
max_title = 32

[widgets.volume]
step = 5              # % per scroll notch or volume key
max = 100             # cap in %, can go above 100
percent = true        # show the number next to the icon

[widgets.stats]
show = ["cpu", "mem"] # any of "cpu", "mem", "gpu", "temp"; tertiary above 70%, error above 90%

[widgets.battery]
low = 15              # % at which it turns red
```

</details>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🗂️ Panels

Panels that belong to a bar widget slide out of the bar beneath it; the rest open in the middle of the screen. A click outside or <kbd>Esc</kbd> closes any of them, and while a panel hangs from the bar, clicking another bar widget switches straight to its panel.

| panel              | what's in it                                                                                         | opened by                                                                         |
| ------------------ | ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 🎛️ `control`       | toggles, volume and mic sliders with a device picker, what's playing, batteries of connected devices | `status` widget                                                                   |
| 🔔 `notifications` | history, do not disturb, clear all                                                                   | `notifications` widget, <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd>            |
| 📅 `calendar`      | the month with today marked; scroll to change month                                                  | `clock` widget                                                                    |
| 📶 `connectivity`  | Wi-Fi networks (with a password prompt) and Bluetooth devices                                        | `connectivity` widget, the control center's arrows, <kbd>Super</kbd>+<kbd>N</kbd> |
| 🚀 `launcher`      | apps, the ones you use most first; type a sum like `12*4` and Enter copies the answer                | `launcher` widget, <kbd>Super</kbd>+<kbd>D</kbd>                                  |
| 📋 `clipboard`     | history, with thumbnails for images                                                                  | `clipboard` widget, <kbd>Super</kbd>+<kbd>V</kbd>                                 |
| 😀 `emoji`         | search by name or keyword, recent picks first                                                        | <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd>                                      |
| 🖼️ `wallpaper`     | the images in `[wallpaper] dir`                                                                      | `wallpaper` widget, control center, <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>W</kbd> |
| ⏻ `power`          | lock, suspend, log out, restart, shut down                                                           | `power` widget, <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd>                    |

<details>
<summary><b>Tips inside the panels</b></summary>

<br>

- **Control center:** click a slider's icon to mute, and the arrow beside it to switch the output or input device. Game mode turns off Hyprland's animations, blur, shadows, gaps and rounding; turning it off reloads your Hyprland config to bring them back. Power mode needs power-profiles-daemon.
- **Everywhere:** the arrow keys move, Enter picks, Esc closes.
- **Emoji:** type words from the name ("fire", "heart eyes"); the pick is copied with `wl-copy`.
- **Clipboard:** Delete removes the selected entry while the cursor is at the end of the search text.
- **Wallpaper:** a carousel; the one in the middle is the one you'll get, and the panel's highlights take its colour. Arrows, the wheel or a click move along it, Enter applies. Type to search by name; <kbd>Tab</kbd> or the chips filter by colour (an image shows under its main colour and its second one, except that black, white and grey only count as the main colour); <kbd>Ctrl</kbd>+<kbd>S</kbd> sorts by name or newest; <kbd>Ctrl</kbd>+<kbd>R</kbd> applies a random one from what's shown. The picker closes once the wallpaper is applied. `wallpaper-index.py` keeps thumbnails and colours in `~/.cache/hecate/wallpapers.db` and only processes images added or changed since the last time, so a big folder opens instantly after the first run. Colours need Pillow (`python-pillow`); without it the chips, the palette and the changing highlight are off, a one-time notification asks you to install it, and everything else works. Delete the database to rebuild it.
- Panels take `color` (their accent) and `background` in `[widgets.<panel>]`.

</details>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🔔 Notifications and the OSD

This shell is the notification server, so don't run swaync or dunst alongside it. New notifications pop up below the bar and land in the history. A popup counts down along its bottom edge (hover to pause), swipes away sideways, and runs the app's default action when clicked. Critical ones stay until dismissed, and do not disturb holds the rest back.

When the volume or microphone changes, from the keys, an app or the control center, a small glass pill shows the new level.

```toml
[widgets.notifications]
popup = "top-right"   # "top-right", "top", "top-left", "bottom-right", "bottom" or "bottom-left"
timeout = 5           # seconds; an app can ask for longer
max = 4               # popups shown at once

[widgets.osd]
position = "bottom"   # "bottom" or "top"
enabled = true
```

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🖥️ Desktop widgets

Glass cards on the wallpaper, behind your windows, in two columns. The default is the first six; `keybinds`, `todo`, `updates` and `network` are there to add to either column. Each name loads `modules/desktop/widgets/<Name>.qml`.

```toml
[desktop]
monitor = ""                          # e.g. "HDMI-A-1"; empty = the first monitor
left  = ["clock", "weather", "audio"]
right = ["system", "github", "apps"]
# also available: keybinds, todo, updates, network
```

| card       | shows                                                                 | needs                                                       |
| ---------- | --------------------------------------------------------------------- | ----------------------------------------------------------- |
| `clock`    | hour and minute rings, the date, day and year progress                | —                                                           |
| `weather`  | now, the next 12 hours, 5 days with each day's range                  | internet ([Open-Meteo](https://open-meteo.com), no API key) |
| `audio`    | the player: cover art, seek bar, controls, a visualizer while playing | an MPRIS player, `cava`                                     |
| `system`   | CPU, memory and GPU gauges, per-thread load, VRAM, disk, GPU power    | — (GPU details are AMD only)                                |
| `github`   | your contribution calendar; hover a day for its count                 | a GitHub token                                              |
| `apps`     | launcher tiles                                                        | —                                                           |
| `keybinds` | your Hyprland binds as key caps, a category per page                  | the `--/` and `-- description` markers in `keybinds.lua`    |
| `todo`     | a checklist: tick, add and remove tasks                               | — (a markdown file, `~/.local/share/hecate/todo.md`)        |
| `updates`  | pending updates with versions, and the latest Arch news               | `checkupdates` + `paru`/`yay` (Arch) or `dnf`               |
| `network`  | download and upload speed, a graph of the last minute                 | —                                                           |

<details>
<summary><b>Card options</b></summary>

<br>

Every card also accepts `color` and `background`.

```toml
[desktop.clock]
twelve_hour = true

[desktop.weather]
location = ""        # city name; empty = guess from your IP address
units = "metric"     # or "imperial"

[desktop.github]
user = "Nurysso"
token_file = "~/.config/tokens/gpat.txt"   # a token with only the read:user scope

[desktop.apps]
apps = ["firefox", "kitty", "dolphin"]   # desktop entry ids or shell commands

[desktop.keybinds]
file = "~/.config/hypr/configs/keybinds.lua"
rows = 8                      # binds per page; the header arrows flip pages
rotate = 0                    # seconds between pages, 0 = only when you click
categories = ["Applications"] # only these "--/" categories (default: all)

[desktop.todo]
file = "~/.local/share/hecate/todo.md"   # "- [ ] task" / "- [x] task" lines, editable by hand
max = 8                                  # tasks shown

[desktop.updates]
interval = 60                 # minutes between checks
packages = 5                  # packages listed
news = true                   # Arch news headlines, click one to open it
news_count = 3
command = "kitty -e ~/.config/hecate/scripts/install-updates.sh"   # what the Update button runs

[desktop.network]
seconds = 60                  # history shown, 10 to 300
```

A desktop entry id is the file name in `/usr/share/applications` without `.desktop`.

</details>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## ⚙️ Configure everything

Everything lives in `~/.config/hecate/hecate.toml`. The shell rereads it when you save and rebuilds only what changed. Anything you leave out uses the defaults shown in this README. A value it can't use falls back to its default and says so in `qs log`; a TOML syntax error keeps the last good settings.

> [!TIP]
> Try settings without touching your own file: `HECATE_CONFIG=/path/to/test.toml quickshell`

```toml
[wallpaper]
dir = "~/Pictures/Wallpapers"   # top level only, no subfolders
```

### 🎨 Colors

`color` and `background` take an M3 color name, which keeps following the wallpaper, or any fixed color such as `"#ff8800"` or `"tomato"`. Backgrounds stay glassy: they're drawn at `[theme] opacity`.

```toml
[widgets.power]
color = "error"
background = "#2b1a1a"
```

<details>
<summary><b>All M3 color names</b></summary>

<br>

`primary` `on_primary` `primary_container` `on_primary_container`, the same four for `secondary`, `tertiary` and `error`, plus `background` `on_background` `surface` `on_surface` `surface_variant` `on_surface_variant` `surface_container_lowest` `surface_container_low` `surface_container` `surface_container_high` `surface_container_highest` `outline` `outline_variant` `inverse_surface` `inverse_on_surface` `inverse_primary` `shadow` `scrim`

</details>

### 🌄 Wallpaper and theming

`~/.config/hecate/scripts/set-wallpaper.sh <image>` is the only thing that changes the wallpaper; the picker calls it and so can you. It points `~/.cache/hecate/wallpaper` at the image and moves to it with `awww`, in a circle growing from the middle of the screen. In `dynamic` mode it then runs matugen and writes `~/.cache/hecate/theme.json`, which the shell watches and fades to.

<img src="https://github.com/user-attachments/assets/1bf1b82e-16cd-4119-873c-097ee1d8df9f" width="100%" alt="The shell on three wallpapers: blue sky, pixel-art meadow and pink clouds, with the desktop cards recolored to match">

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## ⚡ Built for Hyprland

The shell speaks to Hyprland over the same socket `hyprctl` uses and listens to its events instead of polling.

|                            |                                                                                                                                                                                    |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Global shortcuts**       | Binds reach the shell through Hyprland's global-shortcuts protocol, so a key press doesn't start a process.                                                                        |
| **Either config language** | `services/Hypr.qml` checks whether Hyprland runs a Lua config and sends `hl.dsp.*` calls or classic dispatchers to match. Custom widgets should use `Hypr.dispatch(lua, classic)`. |
| **Its own layer rules**    | On start, and after every config reload, `hyprctl eval` turns off Hyprland's animations for the `hecate-*` windows, which animate themselves. Nothing to add to your config.       |
| **Shaped blur**            | The `ext-background-effect` protocol hands Hyprland each surface's exact shape. It uses your `decoration:blur` settings.                                                           |
| **Gaps**                   | The bar's margin follows `general:gaps_out` unless `[bar] margin` is set.                                                                                                          |
| **Events**                 | Keyboard layout, submap and special workspaces come from `activelayout`, `submap` and `activespecial`, after one query at start.                                                   |

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## ⌨️ Keys, shortcuts and IPC

| keys                                           | does                                          |
| ---------------------------------------------- | --------------------------------------------- |
| <kbd>Super</kbd>+<kbd>D</kbd>                  | app launcher                                  |
| <kbd>Super</kbd>+<kbd>V</kbd>                  | clipboard history                             |
| <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd>   | emoji picker                                  |
| <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | notifications                                 |
| <kbd>Super</kbd>+<kbd>N</kbd>                  | Wi-Fi & Bluetooth                             |
| <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd> | power menu                                    |
| <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>W</kbd>  | wallpaper picker                              |
| volume, mic and media keys                     | handled by the shell, with the on-screen pill |

The shell registers these global shortcuts under the app id `hecate`:

- each panel by name, toggling it: `launcher` `control` `notifications` `calendar` `connectivity` `power` `clipboard` `emoji` `wallpaper`
- `volume-up` `volume-down` `volume-mute` `mic-mute`
- `media-play-pause` `media-next` `media-previous` `media-stop`
- `dnd` `caffeine`

Bind one in `configs/keybinds.lua`:

```lua
hl.bind("SUPER + A", hl.dsp.global("hecate:control"))
```

Or drive the shell from scripts:

```sh
qs ipc call hecate toggle <panel>      # or: open <panel>, close
qs ipc call hecate volume +5           # -5, or mute
qs ipc call hecate mic                 # mute or unmute the microphone
qs ipc call hecate media play-pause    # next, previous, stop
qs ipc call hecate dnd                 # do not disturb on/off
qs ipc call hecate caffeine            # keep awake on/off
```

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 📦 Requirements

|              |                                                                                                                                                                               |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Needed**   | `quickshell` 0.3+, Hyprland 0.55+ (Lua config), `awww`, `matugen`, `jq`, `python` 3.11+, `cliphist`, `wl-clipboard`                                                           |
| **Fonts**    | Symbols Nerd Font for icons, Inter (`inter-font`) for text, an emoji font such as `noto-fonts-emoji`                                                                          |
| **Optional** | NetworkManager (Wi-Fi), BlueZ (Bluetooth), PipeWire (volume), UPower (batteries), power-profiles-daemon (power mode), `cava` (visualizer), `python-pillow` (wallpaper colors) |

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🩺 Troubleshooting

<details>
<summary><b>A change to a <code>.qml</code> file doesn't show up</b></summary>
<br>
Quickshell reloads on save, but its file watcher can lose track after files are replaced in bulk (for example by <code>cp -r</code>). Restart it: <code>pkill -x quickshell; quickshell & disown</code>.
</details>

<details>
<summary><b>Where's the log?</b></summary>
<br>
<code>qs log</code> prints the running shell's log: QML errors with file and line, and any hecate.toml value that was ignored.
</details>

<details>
<summary><b>No blur</b></summary>
<br>
Check <code>decoration:blur:enabled</code> in Hyprland (game mode turns it off) and <code>[theme] blur</code>. Without blur, <code>[theme] opacity</code> defaults to a more solid 0.94.
</details>

<details>
<summary><b>A bar widget is missing</b></summary>
<br>
A typo in its name is reported in <code>qs log</code>. Some widgets hide when there's nothing to show: <code>media</code> without a player, <code>battery</code> on a desktop, <code>tray</code> when empty, <code>keyboard</code> with one layout, <code>submap</code> outside a submap.
</details>

<details>
<summary><b>The wallpaper picker is empty</b></summary>
<br>
It only lists images directly inside <code>[wallpaper] dir</code>, not in subfolders.
</details>

<details>
<summary><b>Clicking a workspace in a custom widget does nothing</b></summary>
<br>
A Lua config rejects a plain <code>workspace 2</code> dispatch. Go through <code>Hypr.dispatch</code>, which sends the right form.
</details>

<img src="../../.github/readme/divider.svg" width="100%" alt="">

## 🗺️ Inside this folder

```
shell.qml        entry point: windows, IPC and global shortcuts
config/          Config (reads hecate.toml) · Theme (colors, sizes, glass, motion, icons) · GlobalStates
components/      Panel · Glass · Pill · Card · Slider · QuickToggle · Tile · SearchField · Tooltip · …
services/        Hypr (Hyprland) · Audio · Players · Notifs · Net · Cliphist · Emojis · Launches · SysStats
modules/
  bar/           the bar, and bar/widgets with one file per widget
  desktop/       the desktop layer, desktop/widgets with one file per card, and cava.conf
  notifications/ popups, history, and the card both use
  osd/           the volume and microphone pill
  control/ calendar/ launcher/ connectivity/ power/ clipboard/ emoji/ wallpaper/   the panels
reveal/          the login circle: its own short-lived instance, run by hecate/scripts/start-desktop.sh
```

<br>

<div align="center">

<sub>Part of <a href="../../README.md">Hecate</a> · made with Quickshell, Hyprland and matugen</sub>

</div>

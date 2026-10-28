# Hecate Settings

A settings app for the Hecate Hyprland dotfiles. It reads your Lua Hyprland config, previews changes live, and saves them to a separate overrides file, so your own config files are never rewritten.

Built with Rust and QML (Qt 6, through [CXX-Qt](https://github.com/KDAB/cxx-qt)). Colors follow your wallpaper, just like the rest of Hecate.

> **Status:** beta. It works on the author's machine (Hyprland 0.56, Arch Linux). Expect rough edges.

## Pages

| Page | What you can do |
|---|---|
| **Home** | See your wallpaper and open the wallpaper picker, read system info (OS, kernel, Hyprland and Hecate versions, memory, disk), and arrange the Quickshell bar and desktop widgets. |
| **Decoration** | Rounding, gaps, borders, opacity, blur and shadows. |
| **Animation** | Edit bezier curves by dragging their handles, with a live preview of the motion. |
| **Keybinds** | Add, edit and delete keybinds. Conflicts are flagged before you save. |
| **Monitors** | Drag monitors around to arrange them, or nudge them with the arrow keys. |
| **Connectivity** | Wi-Fi (NetworkManager), Bluetooth (BlueZ) and audio: volume, mute and output device. |

The search bar at the top searches every Hyprland setting, not just the ones on these pages.

## How saving works

Settings changes are previewed live. Nothing is written to disk until you choose to.

1. **Change a setting** and Hyprland updates straight away through `hyprctl eval`.
2. A bar appears at the bottom with **Apply** and **Revert**.
   - **Apply** writes your changes to `~/.config/hypr/hecate_overrides.lua`.
   - **Revert** sets Hyprland back to the saved values.
3. Closing the app with unsaved changes asks whether to discard them. Discarding also undoes them in Hyprland.

For your saved changes to survive a Hyprland reload, `hyprland.lua` has to load the overrides file. If it doesn't, the Home page shows **Overrides not loaded** with an **Add it** button. The button appends this line to the end of your config:

```lua
require("hecate_overrides")
```

It has to be the last line, so the overrides win over your earlier settings.

Some changes don't use the Apply/Revert bar:

| Change | When it's saved |
|---|---|
| Keybinds and animation curves | Right away, when you press their own Save button. |
| Bar and desktop widget layout | Right away, to `~/.config/hecate/hecate.toml`. Quickshell picks it up live, and your comments and other settings in that file are kept. |
| Monitor layout | Never. It applies live only, and resets when Hyprland reloads its config. |
| Wi-Fi, Bluetooth, audio | Handled by those services, as if you'd used their own tools. |

## Requirements

**To build:**

```bash
sudo pacman -S --needed rust qt6-base qt6-declarative
```

**To run:**

| Needed for | Package (Arch) |
|---|---|
| Everything | Hyprland with a Lua config (`hyprland.lua`) |
| Icons | `ttf-nerd-fonts-symbols` (Symbols Nerd Font) |
| Wallpaper picker, live bar and widget layout | Hecate's Quickshell setup (`qs`) |
| Wallpaper colors in the app | `matugen`, through Hecate's `set-wallpaper.sh` |
| Wi-Fi | `networkmanager`, with the service running |
| Bluetooth | `bluez` and `bluez-utils`, `bluetooth.service` running, and a Bluetooth adapter |
| Audio | `wireplumber` (`wpctl`). `pactl` from `pipewire-pulse` or PulseAudio adds output switching and works as a fallback. |

Anything missing only affects its own section. For example, without `bluez-utils` the Bluetooth card says so and the rest of the app works normally.

## Build and run

```bash
cd hecate-settings
cargo build --release
./target/release/hecate-settings
```

## Files it reads and writes

| File | Access | Why |
|---|---|---|
| `~/.config/hypr/hyprland.lua` | read, and one line appended by **Add it** | Your current settings, binds and curves |
| `~/.config/hypr/hecate_overrides.lua` | read and write | Where Apply, keybinds and curves are saved |
| `~/.config/hecate/hecate.toml` | read and write | Font, Hecate version, bar and desktop layout |
| `~/.cache/hecate/theme.json` | read, checked every second | App colors, so they follow wallpaper changes |
| `~/.cache/hecate/wallpaper` | read | The wallpaper shown on Home |
| `~/.config/quickshell/modules/{bar,desktop}/widgets/` | read | Which bar and desktop widgets exist |

Your config is loaded in a sandboxed Lua interpreter. It can `require` modules from your Hyprland config folder, but it can't open other files or run commands. It also can't run forever: it stops after a fixed instruction budget and 256 MB of memory.

## Project layout

```
hecate-settings/
├── engine/          # hecate-engine: loads hyprland.lua in a Lua sandbox, writes the overrides file
│   ├── src/lib.rs
│   └── tests/       # with fixture configs, including a hostile one and an infinite loop
└── app/             # hecate-settings: the Qt app
    ├── build.rs     # registers every QML file and Rust bridge with CXX-Qt
    ├── src/
    │   ├── main.rs
    │   ├── backend.rs       # settings, apply/revert, keybinds, curves, theme, Home, monitors
    │   └── connectivity.rs  # Wi-Fi, Bluetooth and audio, run on background threads
    └── qml/         # Main.qml plus one file per page and the shared controls
```

The list of Hyprland settings, with their types, ranges and descriptions, comes from `scripts/config_schema.json` at the root of the repo, which is compiled into the app. It's generated from the Hyprland wiki:

```bash
python3 scripts/gen_schema.py scripts/config_schema.json
```

## Development

```bash
cargo test                 # engine and app tests
cargo build && QT_FORCE_STDERR_LOGGING=1 ./target/debug/hecate-settings
```

Set `QT_FORCE_STDERR_LOGGING=1` when debugging QML. Otherwise Qt may send its warnings to the systemd journal instead of your terminal, and a broken QML file can fail silently.

When adding a page, register its QML file in `app/build.rs` and add its name to `tabs` in `Main.qml`. The page goes in `Main.qml`'s `StackLayout` in the same position as its name in `tabs`. Search results are always the last page.

Qt's JavaScript engine doesn't support every recent JavaScript feature. `Object.fromEntries` and `Array.prototype.flat` both failed here, so stick to plain loops and `concat`.

## Known limitations

- Monitor changes are not saved. They reset when Hyprland reloads its config.
- The Wi-Fi password is passed to `nmcli` as a command-line argument, so it is visible in the process list while connecting.
- Bluetooth can connect and disconnect devices you've already paired, but it can't pair new ones. Use `bluetoothctl` for that.
- Settings set by a script in your config, rather than a plain value, are shown as read-only.
- Spring animation curves are shown but can't be edited.

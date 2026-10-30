# ⚙️ Hecate Configuration Index

Welcome to the **Hecate Configurations** directory.
Each folder here represents a fully integrated component of the Hecate desktop — including terminals, shells, system daemons, theming tools, and visual enhancements.

You can explore the linked official documentation below to learn more about each tool and its configuration options.

---

## 🧩 Installation

| Platform | Support Status | Notes |
|-----------|----------------|-------|
| **Arch Linux** | ✅ Full Support | Recommended platform — all features and scripts are tested here. |
| **Fedora** | ⚠️ Manual only | Install script is outdated, follow the [manual guide](../Installation/manual-install.md) |
| **Ubuntu** | 🧪 Partial | Under development. Some shell integrations may require manual setup. |
| **NixOS** | 🚧 Planned | Not yet supported, will be added after Fedora and Ubuntu testing. |
| **Others (Debian, OpenSUSE, etc.)** | ❌ Not Supported | Might work with manual configuration but not officially maintained. |

---

### 💡 Notes
- **Arch Linux** is the *reference system* for Hecate — all scripts and integrations (like dynamic colors, Pulse, and other features) are verified here.
- Fedora install is manual only for now; Ubuntu support is under development.
- For installation instructions, check the respective guides in the [`Installation`](../Installation) folder:
  - [Arch](../Installation/arch.md)
  - [Fedora](../Installation/fedora.md)
  - [Ubuntu 25](../Installation/ubuntu-25.md)

## 🧩 Core Components

| Application | Description | Official Docs |
|--------------|-------------|----------------|
| **Hyprland** | Window manager — the heart of Hecate | [HyprWiki](https://wiki.hypr.land/) |
| **Eww** | Widget framework for panels and system monitors | [elkowar.github.io/eww](https://elkowar.github.io/eww/configuration.html) |
| **SwayNC** | Notification daemon with modern UI | GitHub: Ersatus/swaync run: `man 5 swaync` in terminal |
| **Waybar** | Customizable status bar | [github.com/Alexays/Waybar](https://github.com/Alexays/Waybar/wiki/Configuration) |
| **Wlogout** | Logout / power menu interface | [github.com/ArtsyMacaw/wlogout](https://github.com/ArtsyMacaw/wlogout) |
| **Rofi** | Application launcher & power menu | [davatorium.github.io/rofi](https://davatorium.github.io/rofi/) |

---

## 💻 Terminals

| Application | Description | Official Docs |
|--------------|-------------|----------------|
| **Alacritty** | GPU-accelerated terminal | [alacritty](https://github.com/alacritty/alacritty/blob/master/docs/features.md) |
| **Ghostty** | Modern, cross-platform GPU terminal | [ghostty](https://ghostty.org/docs/config) |
| **Foot** | Lightweight Wayland-native terminal | [foot](https://codeberg.org/dnkl/foot#configuration) |
| **Kitty** | Fast terminal with GPU rendering | [sw.kovidgoyal.net/kitty](https://sw.kovidgoyal.net/kitty/overview/) |

---

## 🐚 Shells & Prompts

| Application | Description | Official Docs |
|--------------|-------------|----------------|
| **Zsh** | Default shell with plugins and aliases | [zsh.sourceforge.io](https://zsh.sourceforge.io/) |
| **Fish** | User-friendly shell with autosuggestions | [fishshell.com](https://fishshell.com/docs/current/) |
| **Bash** | Traditional POSIX shell | [gnu.org/software/bash](https://www.gnu.org/software/bash/manual/) |
| **Starship** | Cross-shell prompt written in Rust | [starship.rs](https://starship.rs/config/) |

---

## 🎨 Theming & Aesthetics

| Application | Description | Official Docs |
|--------------|-------------|----------------|
| **Matugen** | Material You-style wallpaper-based color generation | [github.com/InioX/matugen](https://github.com/InioX/matugen) |
| **Wallust** | Universal color palette generator | [github.com/Explosions/wallust](https://explosion-mental.codeberg.page/wallust/) |
| **Waypaper** | Wallpaper manager with PyWall and Wallust support | [github.com/nwg-piotr/waypaper](https://github.com/nwg-piotr/waypaper) |
| **GTK-3.0** | GTK theme configuration for apps | [GNOME GTK 3 Reference](https://docs.gtk.org/gtk3/) |

---

## ⚡ Utilities & System Tools

| Application | Description | Official Docs |
|--------------|-------------|----------------|
| **Fastfetch** | Modern system fetch utility | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch/wiki) |
| **Hecate** | Core automation logic (internal tool) | *Internal script — see [`config/hecate.md`](../Hecate/hecate.md)* |
| **install-hyprland-plugins.sh** | Script to manage Hyprland plugin setup | **`Deprecated`** |
| **hecate.sh** | Main orchestrator for theme, startup, and system sync | *Internal script — see [`Hecate/hecate.md`](../script/hecate.md)* |

# Hecate Manual Installation Guide

> **Distro-agnostic guide.** This is the supported route for Fedora, Ubuntu and everything else. On Arch-based systems you can use the [installer](arch.md) instead.

Hecate is a Hyprland setup with a Quickshell bar and widgets, [`awww`](https://codeberg.org/LGFae/awww) for wallpapers, `matugen` for wallpaper colors, and the `hecate-settings` app. Package names below are the Arch ones; look up the equivalents in your distribution.

---

## Prerequisites

- Git
- A Hyprland version recent enough for the Lua config (`hyprland.lua`)
- `sudo` and your distribution's package manager

---

## Step 1: Clone the repository

```bash
git clone https://github.com/Nurysso/Hecate.git ~/Hecate
ls ~/Hecate/config
```

---

## Step 2: Back up your existing configs

```bash
BACKUP_DIR="$HOME/.cache/hecate-backup/hecate-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR/config"

for dir in $(ls ~/Hecate/config); do
  [ -d "$HOME/.config/$dir" ] && cp -r "$HOME/.config/$dir" "$BACKUP_DIR/config/"
done
[ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/"
[ -f ~/.bashrc ] && cp ~/.bashrc "$BACKUP_DIR/"
echo "Backup: $BACKUP_DIR"
```

To restore, copy the folders back into `~/.config`.

---

## Step 3: Install packages

### Required

| Purpose | Packages |
|---------|----------|
| Compositor | `hyprland`, `hyprlock`, `hypridle`, `xdg-desktop-portal-hyprland` |
| Bar, widgets, panels | `quickshell`, `qt6-base`, `qt6-declarative`, `qt6-wayland` |
| Wallpaper and colors | `awww`, `matugen`, `python` (3.11+, reads `hecate.toml`), `jq` |
| Clipboard | `wl-clipboard`, `cliphist` |
| Screenshots and OCR | `grim`, `slurp`, `tesseract`, `tesseract-data-eng` |
| Audio | `pipewire`, `pipewire-pulse`, `wireplumber`, `playerctl`, `pavucontrol` |
| Network and Bluetooth | `networkmanager`, `network-manager-applet`, `bluez`, `bluez-utils`, `blueman` |
| System | `polkit-kde-agent`, `brightnessctl`, `sysstat`, `lm_sensors`, `batsignal`, `xdg-user-dirs` |
| Notifications | `dunst` |
| Prompt and tools | `starship`, `fastfetch`, `btop`, `cava`, `thunar`, `yazi` |
| Fonts | `inter-font`, `ttf-jetbrains-mono-nerd`, `ttf-nerd-fonts-symbols`, `noto-fonts`, `noto-fonts-emoji` |
| Terminal (pick one) | `kitty`, `alacritty`, `foot`, `ghostty` |
| Shell (pick one) | `zsh`, `bash`, `fish`, plus `fzf`, `bat`, `eza`, `fd`, `thefuck` |

### To build hecate-settings

`rust` (or `rustup` with `rustup default stable`), a C++ compiler, and the Qt 6 packages above.

### Optional

`sddm` with `qt5-graphicaleffects`, `qt5-quickcontrols2` and `qt5-svg` for the login screen (theme in `~/Hecate/hecate-sddm`).

Enable the services:

```bash
sudo systemctl enable --now NetworkManager bluetooth
```

---

## Step 4: Copy the configs

Each folder in `~/Hecate/config` goes to `~/.config/<name>`. Terminals: copy only the one you use.

```bash
mkdir -p ~/.config ~/.local/bin
cd ~/Hecate/config

for d in cava fastfetch gtk-3.0 gtk-4.0 hecate hypr quickshell shell starship zsh bash fish; do
  rm -rf ~/.config/$d
  cp -r $d ~/.config/$d
done

TERM_APP=kitty   # alacritty, foot, ghostty or kitty
rm -rf ~/.config/$TERM_APP && cp -r $TERM_APP ~/.config/$TERM_APP

# Shell rc files (the shared aliases and env are in ~/.config/shell)
cp zsh/zshrc ~/.zshrc
cp bash/bashrc ~/.bashrc

# Helper commands
install -m755 local-bin/hecate.sh ~/.local/bin/hecate
install -m755 local-bin/termkeys.sh ~/.local/bin/termkeys
```

Make sure `~/.local/bin` is in your `PATH`.

Symlinks:

```bash
ln -sf ~/.config/starship/starship.toml ~/.config/starship.toml
ln -sf ~/.config/hypr/hyprlock/hecate-lock.conf ~/.config/hypr/hyprlock.conf
```

---

## Step 5: Configure Hecate

Edit `~/.config/hecate/hecate.toml`:

```toml
[theme]
mode = "dynamic"      # "dynamic" follows the wallpaper, "static" keeps the colors

[preferences]
term = "kitty"
browser = "firefox"   # the command that starts it
shell = "zsh"
profile = "minimal"
```

The bar, widgets and desktop sections are documented in the [Quickshell README](../../config/quickshell/README.md).

Quick Apps tiles live in `~/.config/hecate/quickapps.conf` (`Name=command`, name up to 12 characters):

```
Browser=firefox
Terminal=kitty
Files=thunar
```

Set your default shell if needed: `chsh -s "$(which zsh)"`.

Zsh installs its plugin manager (zinit) and plugins the first time you open a terminal. Fish and Bash need nothing extra.

---

## Step 6: Wallpapers

Put images in `~/Pictures/Wallpapers` (or point `[wallpaper] dir` in `hecate.toml` elsewhere). The full collection is in the repo's images folder.

Set one, which also regenerates the colors when the mode is dynamic:

```bash
~/.config/hecate/scripts/set-wallpaper.sh ~/Pictures/Wallpapers/<image>
```

You can also pick one from the wallpaper panel (`SUPER + CTRL + W`).

---

## Step 7: Build hecate-settings

```bash
~/Hecate/apps/hecate-settings/install.sh
```

This installs `~/.local/bin/hecate-settings` with its icon and desktop entry. Remove it with `--uninstall`.

---

## Step 8: Reboot and log in

Reboot, pick Hyprland (or start it with `Hyprland`). Autostart launches `awww`, Quickshell, the clipboard watchers, `hypridle` and the applets.

---

## Troubleshooting

```bash
pgrep -a quickshell
pgrep awww-daemon
~/Hecate/install.sh --check   # Arch only: lists missing tools and fonts
```

- **No bar:** run `quickshell` from a terminal and read the errors.
- **Colors never change:** check `mode = "dynamic"` in `hecate.toml`, and that `matugen` and `jq` are installed.
- **Icons are boxes:** install `ttf-nerd-fonts-symbols`.
- **Wi-Fi or Bluetooth lists are empty:** enable `NetworkManager` and `bluetooth`.
- **Reload Hyprland:** `SUPER + R`.

---

## File locations

| Location | Purpose |
|----------|---------|
| `~/Hecate/` | Cloned repository |
| `~/.config/hypr/` | Hyprland config |
| `~/.config/quickshell/` | Bar and widgets |
| `~/.config/hecate/hecate.toml` | Main Hecate config |
| `~/.config/shell/` | Aliases and env shared by bash, zsh and fish |
| `~/.cache/hecate/wallpaper` | Current wallpaper (symlink) |
| `~/.local/bin/hecate` | Update and config CLI |
| `~/.cache/hecate-backup/` | Your backups |

---

## Uninstall

Remove the folders listed in Step 4 from `~/.config`, restore your backup, and delete `~/.local/bin/{hecate,termkeys,hecate-settings}` and `~/Hecate`.

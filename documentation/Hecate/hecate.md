# Hecate CLI Tool Documentation

> **Command-line interface for Hecate dotfiles**

The `hecate` command provides a convenient interface for checking updates, managing themes, and monitoring your system.

---

## 📋 Installation

The CLI tool is installed automatically during setup to `~/.local/bin/hecate`.

**Verify installation:**
```bash
which hecate
hecate help
```

---

## 🎯 Commands

### `hecate startup`

Checks network connectivity and available updates.
Used in hyprl/configs/AutoStart.conf file for automatic checks at starup.

```bash
hecate startup
```

**Output:**
- Network status
- Current vs remote version
- Update notification if available

---

### `hecate network`
**Check internet connectivity**

Tests connection by pinging common DNS servers (8.8.8.8, 1.1.1.1) and Google.

```bash
hecate network
```

**Returns:**
- ✓ Network connected (exit 0)
- ✗ No network connection (exit 1)

---

### `hecate check`
**Check for updates**

Compares your local version against the latest GitHub release.

```bash
hecate check
```

**Output:**
- Current version: X.X.X
- Latest version: X.X.X
- Update notification if new version available

---

### `hecate update`
**Update Hecate dotfiles**

Downloads and runs the update script from GitHub. Updates configs and packages.

```bash
hecate update
```

**Process:**
1. Checks for updates
2. Asks for confirmation
3. Downloads update script
4. Runs update
5. Updates version in config

**Note:** Currently disabled in script (returns "it does nothing for now")

---

### `hecate theme`
**Toggle theme mode**

Switches between dynamic (wallpaper-based) and static (fixed) color modes.

```bash
hecate theme
```

**Modes:**
- **Dynamic**: Colors auto-update when wallpaper changes
- **Static**: Colors stay fixed regardless of wallpaper

**Current mode shown before toggle**

---

### `hecate info`
**Display system information**

Shows installation details and configuration.

```bash
hecate info
```

**Output includes:**
- Version and installation date
- Last update timestamp
- Theme mode (dynamic/static)
- Terminal, shell, browser choices
- Profile (minimal/developer/gamer/madlad)

---

### `hecate term`
**Get configured terminal**

Returns the terminal name from config. Used internally by scripts.

```bash
hecate term
```

---

### `hecate help`
**Show help message**

Displays all available commands with examples.

```bash
hecate help
```

---

## 📁 Configuration File

**Location:** `~/.config/hecate/hecate.toml`

```toml
# Hecate Dotfiles Configuration
# This file manages your Hecate installation settings

[metadata]
version = "0.3.9 blind owl"
install_date = "2025-10-15"
last_update = "2025-10-15"
repo_url = "https://github.com/nurysso/Hecate.git"

[theme]
# Theme mode: "dynamic" or "static"
# dynamic: Automatically updates system colors when wallpaper changes
# static: Keeps colors unchanged regardless of wallpaper
mode = "dynamic"

[preferences]
term = "kitty"
browser = "firefox"
shell = "fish"
profile = "minimal"
```

---

## 🔔 Notifications

All commands send desktop notifications via `notify-send`:

| Command | Notification |
|---------|-------------|
| `startup` | Network status + update alert |
| `network` | Connection status |
| `check` | Update available/up-to-date |
| `update` | Success/failure messages |
| `theme` | Mode changed confirmation |

---

## 🛠️ Requirements

- **gum** - Interactive CLI tool (required)
- **curl** - For checking updates
- **notify-send** - Desktop notifications (optional)
- Network access for update checks

---

## 🔧 Troubleshooting

### "gum is not installed"
```bash
sudo pacman -S gum  # or your distro's package manager
```

### "Hecate config not found"
```bash
# Recreate config
mkdir -p ~/.config/hecate
# Re-run installer or create manually
```

### Update check fails
```bash
# Check network first
hecate network

# Verify GitHub access
curl -I https://github.com
```

### Config values not updating
```bash
# Manually edit config
vim ~/.config/hecate/hecate.toml

# Or check file permissions
ls -la ~/.config/hecate/hecate.toml
```

---

## 🎨 Integration Examples

### Hyprland Startup
```conf
# ~/.config/hypr/configs/autoStart.conf
exec-once = bash -c "sleep 2 && $local/hecate startup 2>&1 | tee /tmp/hecate-startup.log"
```
### Shell Alias
```bash
# Quick commands
alias hupdate="hecate update"
alias htheme="hecate theme"
alias hinfo="hecate info"
```
---

## 🔐 Security Note

The update command downloads and executes a script from GitHub:
```bash
https://raw.githubusercontent.com/nurysso/Hecate/main/update.sh
```

**Always review update scripts before running in production environments.**

---

## 📝 Command Quick Reference

```bash
hecate startup    # Login check (network + updates)
hecate network    # Test internet connection
hecate check      # Check for updates
hecate update     # Update dotfiles
hecate theme      # Toggle dynamic/static
hecate info       # Show config info
hecate term       # Get terminal name
hecate help       # Show help
```

---

## 🐛 Known Issues

1. **Update command disabled** - Returns "it does nothing for now"
2. **Notifications require DISPLAY/WAYLAND_DISPLAY** - Won't work in pure TTY
3. **GitHub API rate limits** - May fail if checking too frequently
---

## Related Commands

```bash
# Update theme colors manually
~/.config/hecate/scripts/update_hecate_colors.sh

# Reload components
pkill -SIGUSR2 waybar
swaync-client -rs

# Check config file
cat ~/.config/hecate/hecate.toml
```

---

**Last Updated:** 2025-10-25
**Repository:** https://github.com/nurysso/Hecate

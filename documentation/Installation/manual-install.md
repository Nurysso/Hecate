# Hecate Manual Installation Guide

> **Universal installation guide for any Linux distribution**

This guide provides distro-agnostic instructions for manually installing Hecate dotfiles.

---

## 📋 Prerequisites

- Git
- Basic command line knowledge
- Your distribution's package manager

---

## 🚀 Installation Overview

1. Clone repository
2. Backup existing configs
3. Install required packages
4. Copy configuration files
5. Set up theme system
6. Configure applications

---

## Step 1: Clone the Repository

```bash
# Clone to home directory
git clone https://github.com/Aelune/Hecate.git ~/Hecate

# Verify
ls ~/Hecate/config
```

---

## Step 2: Backup Your Existing Configs
### You can do it either manually in your file manager or by following the commands

**Create timestamped backup:**
```bash
# Set backup location
BACKUP_DIR="$HOME/.config/Hecate-backup/config-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Save backup path for reference
echo "$BACKUP_DIR" > ~/.config/hecate_last_backup.txt
```

**Backup configs that Hecate will replace:**
```bash
# List of directories that will be replaced
CONFIGS_TO_BACKUP=(
  "hypr"
  "waybar"
  "swaync"
  "rofi"
  "wlogout"
  "quickshell"
  "eww"
  "kitty"
  "alacritty"
  "foot"
  "ghostty"
  "fish"
  "alacritty"
  "foot"
  "ghostty"
  "kitty"
  "wallust"
  "eww"
  "gtk-3.0"
  "gtk-4.0"
  "matugen"
  "fastfetch"
  "waypaper"
  "fish"
  "starship"
)

# Backup each if it exists
for config in "${CONFIGS_TO_BACKUP[@]}"; do
  if [ -d "$HOME/.config/$config" ]; then
    echo "Backing up: $config"
    cp -r "$HOME/.config/$config" "$BACKUP_DIR/"
  fi
done

# Backup shell rc files
[ -f ~/.zshrc ] && cp ~/.zshrc "$BACKUP_DIR/.zshrc"
[ -f ~/.bashrc ] && cp ~/.bashrc "$BACKUP_DIR/.bashrc"

echo "✓ Backup complete: $BACKUP_DIR"
```

**To restore later:**
```bash
# Restore a specific config
cp -r /path/to/backup/hypr ~/.config/
```

---

## Step 3: Install Required Packages

### Package List

Install these packages using your distribution's package manager. Package names may vary slightly between distributions.

#### Core Hyprland & Wayland

```
hyprland
hyprpaper
hyprlock
hypridle
xdg-desktop-portal-hyprland
qt5-wayland
qt6-wayland
```

#### Wayland Utilities

```
wl-clipboard
cliphist
grim
slurp
swappy
```

#### Status Bar & Notifications

```
waybar
swaync
dunst
```

#### Application Launcher & Menus

```
rofi-wayland (or rofi with wayland support)
rofi-emoji
wlogout
```

#### Wallpaper & Theming

```
waypaper
swww
python-pywal (or python3-pywal)
wallust
imagemagick
```

#### File Manager

```
of your choice
```

#### System Info & Monitoring

```
fastfetch
btop
htop
```

#### Shell & CLI Tools

```
starship
fzf
bat
exa (or eza)
fd (or fd-find)
ripgrep
```

#### Fonts

```
ttf-jetbrains-mono-nerd (or jetbrains-mono-nerd-fonts)
noto-fonts
noto-fonts-emoji
noto-fonts-cjk
inter-font (or fonts-inter)
```

#### Essential Tools

```
git
wget
curl
unzip
jq
bc
neovim (or vim)
nano
```

#### Terminal

```
kitty
alacritty
foot
ghostty
```

#### Shell

```
zsh
bash
fish
```

#### Browser

```
firefox
chromium
brave-browser
google-chrome
```

## Step 4: Copy Configuration Files

### Directory Structure

Hecate configs are organized in `~/Hecate/config/`:
```
~/Hecate/config/
├── hypr/              # Hyprland configuration
├── waybar/            # Status bar
├── swaync/            # Notification center
├── rofi/              # Application launcher
├── wlogout/           # Logout menu
├── hecate/            # Theme system
├── starship/          # Shell prompt
├── kitty/             # Kitty terminal
├── alacritty/         # Alacritty terminal
├── foot/              # Foot terminal
├── ghostty/           # Ghostty terminal
├── zsh/               # Zsh shell
├── bash/              # Bash shell
├── fish/              # Fish shell
└── hecate.sh          # CLI tool
```

### Copy Core Configs

```bash
# Ensure .config directory exists
mkdir -p ~/.config

# Copy core configurations
cp -r ~/Hecate/config/hypr ~/.config/
cp -r ~/Hecate/config/waybar ~/.config/
cp -r ~/Hecate/config/swaync ~/.config/
cp -r ~/Hecate/config/rofi ~/.config/
cp -r ~/Hecate/config/wlogout ~/.config/
cp -r ~/Hecate/config/hecate ~/.config/
```

### Copy Terminal Config

**Copy only YOUR chosen terminal:**
```bash
# Kitty
cp -r ~/Hecate/config/kitty ~/.config/

# OR Alacritty
cp -r ~/Hecate/config/alacritty ~/.config/

# OR Foot
cp -r ~/Hecate/config/foot ~/.config/

# OR Ghostty
cp -r ~/Hecate/config/ghostty ~/.config/
```

### Copy Shell Config

**Copy only YOUR chosen shell:**
```bash
# Zsh
cp ~/Hecate/config/zsh/.zshrc ~/.zshrc

# OR Bash
cp ~/Hecate/config/bash/.bashrc ~/.bashrc

# OR Fish
mkdir -p ~/.config/fish
cp -r ~/Hecate/config/fish/* ~/.config/fish/
```

### Copy Starship Config

```bash
cp ~/Hecate/config/starship/starship.toml ~/.config/starship.toml
```

### Install CLI Tools

```bash
# Create bin directory
mkdir -p ~/.local/bin

# Copy hecate CLI tool
cp ~/Hecate/config/hecate.sh ~/.local/bin/hecate
chmod +x ~/.local/bin/hecate
cp ~/Hecate/apps/Pulse/build/bin/Pulse ~/.local/bin/Pulse
cp ~/Hecate/apps/Hecate-Help/build/bin/Hecate-Help ~/.local/bin/Hecate-Help

# Add to PATH if not already there
# Add this line to your shell rc file (~/.bashrc, ~/.zshrc, etc.)
export PATH="$HOME/.local/bin:$PATH"
```

---

## Step 5: Set Up Theme System

### Create Hecate Configuration

```bash
mkdir -p ~/.config/hecate

cat > ~/.config/hecate/hecate.toml <<'EOF'
# Hecate Dotfiles Configuration
[metadata]
version = "0.3.9 blind owl"
install_date = "$(date +%Y-%m-%d)
last_update = "$(date +%Y-%m-%d)"
repo_url = "https://github.com/Aelune/Hecate.git"

[theme]
# Mode: "dynamic" = auto-update colors from wallpaper
#       "static" = keep colors unchanged
mode = "dynamic"

[preferences]
term = "kitty"      # Change to: kitty, alacritty, foot, ghostty
browser = "firefox" # Change to: firefox, chromium, brave, etc.
shell = "zsh"       # Change to: zsh, bash, fish
profile = "minimal"
EOF
```

### Create Color Symlinks

```bash
# Link Waybar and SwayNC to master color file
ln -sf ~/.config/hecate/hecate.css ~/.config/waybar/color.css
ln -sf ~/.config/hecate/hecate.css ~/.config/swaync/color.css

# Link Waybar style and config to defaults
ln -sf ~/.config/waybar/style/default.css ~/.config/waybar/style.css
ln -sf ~/.config/waybar/configs/top ~/.config/waybar/config
```

---

## Step 6: Configure Applications

### Set Default Applications

```bash
mkdir -p ~/.config/Hecate/quickApps.conf

# Edit with your preferences
cat > ~/.config/hecate/quickapps.conf <<'EOF'
# Quick Apps Configuration
# Syntax name=command
# Max 12 characters in name
Firefox=firefox
Terminal=kitty
Files=dolphin
Editor=code
Music=spotify
EOF
```

### Configure Waypaper Post-Command

This makes colors update automatically when you change wallpaper:
For more info, check [dynamic-colors.md](../Hecate/dynamic-colors.md)

```bash
 ~/.config/hecate/scripts/hecate-system-colors.sh
```

### Set Default Shell (Optional)

```bash
# Change to your chosen shell
chsh -s $(which zsh)    # For Zsh
chsh -s $(which bash)   # For Bash
chsh -s $(which fish)   # For Fish

# Log out and back in for changes to take effect
```

---

## Step 7: Initialize Theme System

### Generate Initial Colors

```bash
# Set an initial wallpaper
# (Place a wallpaper in ~/Pictures/ or use any image)
wal -i ~/Pictures/your-wallpaper.jpg

# Generate Hecate colors
~/.config/hecate/scripts/update_hecate_colors.sh
```

### or change wallpaer by waypaper
---

## 🎯 Optional: Install Shell Plugins

### Zsh Plugins

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Fish Plugins

```bash
# Install Fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
  | source && fisher install jorgebucaran/fisher

# Install plugins
fisher install jethrokuan/z
fisher install PatrickF1/fzf.fish
fisher install jorgebucaran/nvm.fish
```

### Bash Plugins

```bash
# FZF integration (if available on your system)
# Usually in: /usr/share/fzf/

# Add to ~/.bashrc:
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
```

---

## 🎯 Optional: SDDM Login Manager

### Enable SDDM

```bash
# Enable SDDM service (command varies by distro)

# Systemd-based systems:
sudo systemctl enable sddm
sudo systemctl set-default graphical.target

# Reboot to use SDDM
sudo reboot
```

### Install Astronaut Theme (Optional)

```bash
curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh | bash
```

---

## ✅ Post-Installation

### 1. Reboot or Re-login

```bash
# Reboot
sudo reboot

# Or just log out and back in
```

### 2. Start Hyprland

- **From display manager:** Select "Hyprland"
- **From TTY:** Type `Hyprland`

### 3. Test Key Bindings

```
Super + Return         Terminal
Super + D              App launcher (Rofi)
Super + E              File manager
Super + B              Browser
Super + Q              Close window
```

### 4. Set Wallpaper

```bash
# Open waypaper
waypaper

# Select wallpaper
# Colors auto-update if theme mode is "dynamic"
```

---

## 🔧 Troubleshooting

### Verify Components Running

```bash
# Check if Waybar is running
pgrep waybar

# Check if SwayNC is running
pgrep swaync

# Check wallpaper daemon
pgrep hyprpaper  # or pgrep swww
```

### Restart Components

```bash
# Restart Waybar
pkill waybar && waybar &

# Restart SwayNC
pkill swaync && swaync &

# Reload Hyprland config
hyprctl reload
```

### Colors Not Updating

```bash
# Check theme mode
cat ~/.config/hecate/hecate.toml | grep mode

# Manually update colors
~/.config/hecate/scripts/update_hecate_colors.sh

# Check pywal colors exist
ls ~/.cache/wal/colors.json
```

### Terminal/App Not Opening

```bash
# Check your app-names.conf
cat ~/.config/hypr/configs/UserConfigs/app-names.conf

# Verify the app is installed
which kitty  # or your terminal
which firefox  # or your browser

# Test manually
kitty  # Should open terminal
firefox  # Should open browser
```

---

## 📁 File Locations Reference

| Location | Purpose |
|----------|---------|
| `~/Hecate/` | Cloned repository |
| `~/.config/hypr/` | Hyprland config |
| `~/.config/waybar/` | Waybar config |
| `~/.config/swaync/` | Notification center |
| `~/.config/rofi/` | App launcher |
| `~/.config/hecate/` | Theme system |
| `~/.config/hecate/hecate.toml` | Main config |
| `~/.config/hecate/hecate.css` | Master colors |
| `~/.config/starship.toml` | Shell prompt |
| `~/.zshrc` / `~/.bashrc` | Shell config |
| `~/.cache/wal/colors.json` | Pywal colors |
| `~/.local/bin/hecate` | CLI tool |
| `~/.config/Hecate-backup/` | Your backups |

---

## 💡 Customization Quick Tips

### Switch Theme Mode

```bash
# Edit config
vim ~/.config/hecate/hecate.toml

# Change mode:
mode = "dynamic"  # Auto-update from wallpaper
mode = "static"   # Keep colors fixed
```

### Change Terminal/Browser

```bash
# Edit app names
vim ~/.config/hecate/hecate.toml

# Update:
[preferences]
term = "kitty"
browser = "firefox"
```

### Add Custom Keybinds

```bash
# Edit user keybinds
vim ~/.config/hypr/configs/UserKeybinds.conf
```

### Modify Waybar Layout

```bash
# Edit Waybar config
vim ~/.config/waybar/configs/top
```

---
## Resources

- **Issues:** Report on GitHub
- **Automated Installer:** Use `./install.sh` for Arch-based systems (other distro are going to be added soon..)
- **Theme Documentation:** See [dynamic-colors.md](../Hecate/dynamic-colors.md)

---

- **Installation Time:** 15-30 minutes
- **Difficulty:** Intermediate
- **Distro Support:** Universal (package names may vary)
- **Last Updated:** 2025-10-25

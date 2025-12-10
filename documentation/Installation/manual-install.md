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
git clone https://github.com/nurysso/Hecate.git ~/Hecate

# Verify
ls ~/Hecate/config
```

---

## Step 2: Backup Your Existing Configs
### You can do it either manually in your file manager or by following the commands

**Create timestamped backup in cache:**
```bash
# Set backup location in cache directory
BACKUP_DIR="$HOME/.cache/hecate-backup/hecate-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR/config"

# Save backup path for reference
echo "$BACKUP_DIR" > ~/.cache/hecate_last_backup.txt
```

**Backup configs that Hecate will replace:**
```bash
# List of directories that will be replaced
CONFIGS_TO_BACKUP=(
  "alacritty"
  "bash"
  "cava"
  "eww"
  "fastfetch"
  "fish"
  "foot"
  "ghostty"
  "gtk-3.0"
  "gtk-4.0"
  "hecate"
  "hypr"
  "kitty"
  "matugen"
  "quickshell"
  "rofi"
  "starship"
  "swaync"
  "wallust"
  "waybar"
  "waypaper"
  "wlogout"
)

# Backup each config directory if it exists
for config in "${CONFIGS_TO_BACKUP[@]}"; do
  if [ -d "$HOME/.config/$config" ]; then
    echo "Backing up: $config"
    cp -r "$HOME/.config/$config" "$BACKUP_DIR/config/"
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
cp -r /path/to/backup/config/hypr ~/.config/

# Restore shell rc files
cp /path/to/backup/.zshrc ~/
cp /path/to/backup/.bashrc ~/
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
tesseract
webkit2gtk
```

#### Terminal

```
kitty
alacritty
foot
ghostty
```

#### Shell (of your choice)

```
zsh
bash
fish
```

#### Browser (of your choice)

```
firefox
chromium
brave-browser
google-chrome
```

---

## Step 4: Copy Configuration Files

### Directory Structure

Hecate configs are organized in `~/Hecate/config/`:
```
~/Hecate/config/
├── alacritty/         # Alacritty terminal
├── bash/              # Bash shell
├── bashrc             # Bash rc file
├── cava/              # Audio visualizer
├── eww/               # Elkowar's Wacky Widgets
├── fastfetch/         # System info
├── fish/              # Fish shell
├── foot/              # Foot terminal
├── ghostty/           # Ghostty terminal
├── gtk-3.0/           # GTK3 theme
├── gtk-4.0/           # GTK4 theme
├── hecate/            # Theme system
├── hecate.sh          # CLI tool
├── hypr/              # Hyprland configuration
├── kitty/             # Kitty terminal
├── matugen/           # Material theme generator
├── quickshell/        # Quick shell
├── rofi/              # Application launcher
├── starship/          # Shell prompt
├── swaync/            # Notification center
├── wallust/           # Wallpaper color generator
├── waybar/            # Status bar
├── waypaper/          # Wallpaper selector
├── wlogout/           # Logout menu
└── zshrc              # Zsh rc file
```

### Install CLI Tools

```bash
# Create bin directory
mkdir -p ~/.local/bin

# Copy hecate CLI tool
mv ~/Hecate/config/hecate.sh ~/.local/bin/hecate
chmod +x ~/.local/bin/hecate
echo "✓ Hecate CLI tool installed"

# Copy Pulse (if built)
if [ -f ~/Hecate/apps/Pulse/build/bin/Pulse ]; then
  mv ~/Hecate/apps/Pulse/build/bin/Pulse ~/.local/bin/Pulse
  chmod +x ~/.local/bin/Pulse
  echo "✓ Pulse installed"
fi

# Copy Hecate-Settings (if built)
if [ -f ~/Hecate/apps/Hecate-Help/build/bin/Hecate-Settings ]; then
  mv ~/Hecate/apps/Hecate-Help/build/bin/Hecate-Settings ~/.local/bin/Hecate-Settings
  chmod +x ~/.local/bin/Hecate-Settings
  echo "✓ Hecate-Settings installed"
fi

# Copy Aoiler (if built)
# Aoiler needs a little more setup and is in alpha stage may not work out of the box right now
if [ -f ~/Hecate/apps/Aoiler/build/bin/Aoiler ]; then
  mv ~/Hecate/apps/Aoiler/build/bin/Aoiler ~/.local/bin/Aoiler
  chmod +x ~/.local/bin/Aoiler
  echo "✓ Aoiler (Assistant) installed"
fi

# Add to local/bin to PATH if not already there
# Add this line to your shell rc file (~/.bashrc, ~/.zshrc, etc.)
export PATH="$HOME/.local/bin:$PATH"

# for fish use this
set -gx PATH $HOME/.local/bin $PATH
```

### Copy Shell RC Files

```bash
# Copy shell rc files to home directory
cp ~/Hecate/config/zshrc ~/.zshrc
echo "✓ Zsh config copied to ~/.zshrc"

cp ~/Hecate/config/bashrc ~/.bashrc
echo "✓ Bash config copied to ~/.bashrc"
```


### Move Configs

either move manually or copy paste the commands

```bash
# Copy all config directories to ~/.config
for dir in ~/Hecate/config/*/; do
  dir_name=$(basename "$dir")
  echo "Copying $dir_name..."
  cp -r "$dir" ~/.config/
done

echo "✓ All config directories copied"
```





---

## Step 5: Set Up Theme System

### Create Hecate Configuration
<p> change your app prefrences term,browser,shell, profile(profile currenlt does nothing other than install additional packages at install which isnt really necessary at manual setup and maybe in future will add specific themes or something) </p>

```bash
mkdir -p ~/.config/hecate
remote_version=$(curl -s "https://raw.githubusercontent.com/nurysso/Hecate/main/version.txt" )
cat > ~/.config/hecate/hecate.toml <<EOF
# Hecate Dotfiles Configuration
[metadata]
version = "$remote_version"
install_date = "$(date +%Y-%m-%d)"
last_update = "$(date +%Y-%m-%d)"
repo_url = "https://github.com/nurysso/Hecate.git"

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

echo "✓ Hecate config created"
```

### Create Color Symlinks

```bash
# Remove any existing symlinks or files
[ -e ~/.config/waybar/style.css ] && rm -f ~/.config/waybar/style.css
[ -e ~/.config/waybar/config ] && rm -f ~/.config/waybar/config
[ -e ~/.config/waybar/color.css ] && rm -f ~/.config/waybar/color.css
[ -e ~/.config/swaync/color.css ] && rm -f ~/.config/swaync/color.css
[ -e ~/.config/starship.toml ] && rm -f ~/.config/starship.toml

# Create symlinks
ln -s ~/.config/waybar/style/default.css ~/.config/waybar/style.css
ln -s ~/.config/waybar/configs/top ~/.config/waybar/config
ln -s ~/.config/hecate/hecate.css ~/.config/waybar/color.css
ln -s ~/.config/hecate/hecate.css ~/.config/swaync/color.css
ln -s ~/.config/starship/starship.toml ~/.config/starship.toml

echo "✓ Symlinks created"
```

---

## Step 6: Configure Quick Applications
### Set Default Applications

```bash
mkdir -p ~/.config/hecate

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

echo "✓ Quick apps configured"
```

### Configure Waypaper Post-Command

This script makes colors update automatically when you change wallpaper:
For more info, check [dynamic-colors.md](../Hecate/dynamic-colors.md). Check if the script exists and is there any error

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

### Or change wallpaper by waypaper
```bash
waypaper
```

---

## Install Shell Plugins

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

## Optional: SDDM Login Manager

### Enable SDDM

```bash
# Enable SDDM service (command varies by distro choose your distro command)
sudo pacman -S sddm
sudo dnf install sddm
sudo apt install sddm

# enable sddm:
sudo systemctl enable sddm
sudo systemctl set-default graphical.target
```

### Install Astronaut Theme (Optional)(Its a different project not owned by me I just contributed in install script)

```bash
curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh | bash
```

---

## ✅ Post-Installation

### 1. Reboot

```bash
# Reboot
sudo reboot
```

### 2. Start Hyprland

- **From display manager:** Select "Hyprland"
- **From TTY:** Type `Hyprland`

### 3. Test Key Bindings

```
SUPER + Return         Terminal
SUPER + D              App launcher (Rofi)
SUPER + E              File manager
SUPER + B              Browser
SUPER + Q              Close window
SUPER + H              Hecate settings app (keybinds)
SUPER + Space          Aoiler ai assistant(in alpha stage may not work smoothly)
```

### 4. Set Wallpaper

```bash
# Open waypaper by command or keybind
waypaper

# Keybind
SUPER + CTRL + W
# Select wallpaper
# Colors auto-update if theme mode is "dynamic"
# Change theme from static to dynamic or vis versa just type hecate theme or change in hecate settings app under home page
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
pgrep swww  # or pgrep hyprpaper
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
| `~/.config/starship.toml` | Shell prompt (symlink) |
| `~/.zshrc` | Zsh config |
| `~/.bashrc` | Bash config |
| `~/.cache/wal/colors.json` | Pywal colors |
| `~/.local/bin/hecate` | CLI tool |
| `~/.cache/hecate-backup/` | Your backups |
| `~/.cache/hecate_last_backup.txt` | Last backup path |

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

## 🗑️ Uninstallation

### Restore Previous Configs

```bash
# Find your backup
BACKUP_PATH=$(cat ~/.cache/hecate_last_backup.txt)
echo "Restoring from: $BACKUP_PATH"

# Restore all configs
cp -r "$BACKUP_PATH/config/"* ~/.config/

# Restore shell rc files
[ -f "$BACKUP_PATH/.zshrc" ] && cp "$BACKUP_PATH/.zshrc" ~/
[ -f "$BACKUP_PATH/.bashrc" ] && cp "$BACKUP_PATH/.bashrc" ~/

echo "✓ Configs restored"
```

### Remove Hecate

```bash
# Remove Hecate configs
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/swaync
rm -rf ~/.config/rofi
rm -rf ~/.config/hecate

# Remove CLI tools
rm -f ~/.local/bin/hecate
rm -f ~/.local/bin/Pulse
rm -f ~/.local/bin/Hecate-Settings
rm -f ~/.local/bin/Aoiler

# Remove repository
rm -rf ~/Hecate

echo "✓ Hecate removed"
```

---

## 📚 Resources

- **Issues:** Report on GitHub
- **Automated Installer:** Use `./install.sh` for Arch-based systems (other distros are going to be added soon..)
- **Theme Documentation:** See [dynamic-colors.md](../Hecate/dynamic-colors.md)

---

**Installation Stats:**
- **Installation Time:** 15-30 minutes
- **Difficulty:** Intermediate
- **Distro Support:** Universal (package names may vary)
- **Backup Location:** `~/.cache/hecate-backup/`
- **Last Updated:** 2025-11-12

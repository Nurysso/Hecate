#!/bin/bash

# Hecate installer for Arch-based systems
# Usage: ./arch.sh [--check | --no-deps | --dry-run | --help]

set -e

# Output is plain printf so it never waits on gum or a text effect; gum is only used for prompts.
good() { printf '\033[32m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
bad() { printf '\033[31m%s\033[0m\n' "$*" >&2; }
header() { printf '\n\033[1;35m== %s ==\033[0m\n' "$*"; }
have() { command -v "$1" &>/dev/null; }

# Colors for the --help and --dry-run text
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Global Variables
# HECATE_LOCAL=true (set by install.sh when run from a checkout) installs from that checkout instead of cloning
HECATE_LOCAL="${HECATE_LOCAL:-false}"
HECATEDIR="${HECATEDIR:-$HOME/Hecate}"
HECATEAPPSDIR="$HECATEDIR/apps"
CONFIGDIR="$HOME/.config"
REPO_URL="https://github.com/Nurysso/Hecate.git"
OS="arch"
PACKAGE_MANAGER=""
HYPRLAND_NEWLY_INSTALLED=false
CHECK_ONLY=false
SKIP_PACKAGES=false
BUILD_PID=""
SETTINGS_LOG="/tmp/hecate-settings-build.log"

# User preferences
USER_TERMINAL=""
USER_SHELL=""
USER_BROWSER_PKG=""
USER_BROWSER_EXEC=""
USER_BROWSER_DISPLAY=""
USER_PROFILE=""
INSTALL_SDDM=false
INSTALL_PACKAGES=()
FAILED_PACKAGES=()
MISSING_PKGS=()


# Get package manager
get_packageManager() {
    if command -v paru &>/dev/null; then
      PACKAGE_MANAGER="paru"
    elif command -v yay &>/dev/null; then
      PACKAGE_MANAGER="yay"
    elif command -v pacman &>/dev/null; then
      PACKAGE_MANAGER="pacman"
    fi

  if [ -z "$PACKAGE_MANAGER" ]; then
    bad "Error: No supported package manager found!"
    exit 1
  fi

  good "✓ Package Manager: $PACKAGE_MANAGER"
}



safe_remove() {
  local path="$1"

  # 1. Input Validation & Strict Guardrails
  if [[ -z "$path" ]]; then
    bad "Error: safe_remove requires a target path."
    return 1
  fi

  if [[ "$path" == "/" || "$path" == "." || "$path" == ".." ]]; then
    bad "Error: Refusing to delete critical directory path: $path"
    return 1
  fi

  # 2. Check existence
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return 0
  fi

  # 3. Remove cleanly and catch errors
  # --preserve-root protects against accidental system wipeouts
  # -- stops flags from being read if a file starts with a dash (-)
  rm -rf --preserve-root -- "$path" || {
    bad "Error: Failed to force remove $path"
    return 1
  }
}

# Defensive helper function to safely copy a directory
safe_copy_dir() {
  local src="$1"
  local dest="$2"

  # 1. Input Validation
  if [[ -z "$src" || -z "$dest" ]]; then
    bad "Error: Source and destination paths are required."
    return 1
  fi

  if [[ ! -d "$src" ]]; then
    bad "Error: Source directory does not exist: $src"
    return 1
  fi

  # Prevent destructive operations on root or matching paths
  if [[ "$dest" == "/" || "$src" == "$dest" ]]; then
    bad "Error: Invalid or identical source/destination paths."
    return 1
  fi

  # 2. Stage the copy in a temporary directory
  local dest_parent
  dest_parent=$(dirname -- "$dest")

  local tmp_dest
  tmp_dest=$(mktemp -d "${dest_parent}/.copy_tmp_XXXXXX") || {
    bad "Error: Could not create temporary directory."
    return 1
  }

  # Ensure cleanup of temp dir if script aborts mid-copy
  trap 'rm -rf "$tmp_dest"' RETURN

  # Copy contents *into* the temp directory instead of replacing it
  cp -a "$src/." "$tmp_dest/" || {
    bad "Error: Copy failed from $src to $tmp_dest"
    return 1
  }

  # 3. Swap destination atomically
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf --preserve-root "$dest" || {
      bad "Error: Could not remove old $dest"
      return 1
    }
  fi

  mv "$tmp_dest" "$dest" || {
    bad "Error: Could not move temporary directory to final destination."
    return 1
  }

  # Clear the trap explicitly on success
  trap - RETURN
}


# Defensive helper function to safely copy a file
safe_copy_file() {
  local src="$1"
  local dest="$2"

  if [ ! -f "$src" ]; then
    bad "Error: Source file does not exist: $src"
    return 1
  fi

  # Remove destination if it exists (could be file, dir, or symlink)
  safe_remove "$dest"

  # Now safely copy
  cp "$src" "$dest"
}

# Clone dotfiles
clone_dotfiles() {
  header "Cloning Hecate Dotfiles"

  if [ "$HECATE_LOCAL" = true ]; then
    good "✓ Using the local checkout at $HECATEDIR"
    return
  fi

  if [ -d "$HECATEDIR" ]; then
    if gum confirm "Hecate directory already exists. Remove and re-clone?"; then
      rm -rf "$HECATEDIR"
    else
      warn "Using existing directory..."
      return
    fi
  fi

  warn "Cloning repository..."
  if ! git clone --depth 1 "$REPO_URL" "$HECATEDIR"; then
    bad "✗ Error cloning repository!"
    exit 1
  fi

  # Verify critical directories exist
  if [ ! -d "$HECATEDIR/config" ]; then
    bad "✗ Error: Config directory not found in cloned repo!"
    exit 1
  fi

  good "✓ Dotfiles cloned successfully!"
}

# Backup existing configs to cache instead of .config
backup_config() {
  header "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.cache/hecate-backup/hecate-$timestamp"

  # List of config directories to check (excluding shell rc files)
   local config_dirs=(
 "alacritty"  "cava" "fastfetch"  "foot"     "gtk-3.0"  "hecate"  "kitty"    "quickshell"  "starship" "zsh" "bash"  "fish" "shell" "ghostty" "gtk-4.0" "hypr" "matugen" "qt6ct" "Kvantum"
  )

  # Check for shell rc files separately
  local shell_files=()
  [ -f "$HOME/.zshrc" ] && shell_files+=(".zshrc")
  [ -f "$HOME/.bashrc" ] && shell_files+=(".bashrc")

  local backed_up=false

  # Backup config directories
  for dir in "${config_dirs[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
      if [ "$backed_up" = false ]; then
        mkdir -p "$backup_dir/config"
        backed_up=true
      fi
      warn "Backing up: $dir"
      cp -r "$HOME/.config/$dir" "$backup_dir/config/"
    fi
  done

  # Backup shell rc files
  for file in "${shell_files[@]}"; do
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    warn "Backing up: $file"
    cp "$HOME/$file" "$backup_dir/"
  done

  if [ "$backed_up" = true ]; then
    good "✓ Backup created at: $backup_dir"
    echo "$backup_dir" > "$HOME/.cache/hecate_last_backup.txt"
  else
    warn "No existing configs found to backup"
  fi
}

# Ask user preferences to customize installation
ask_preferences() {
  header "User Preferences"

  # Terminal preference
  USER_TERMINAL=$(gum choose --header "Select your preferred terminal:" \
    "kitty" \
    "alacritty" \
    "foot" \
    "ghostty")
  good "✓ Terminal: $USER_TERMINAL"
  echo ""

  # Shell preference
  USER_SHELL=$(gum choose --header "Select your preferred shell:" \
    "zsh" \
    "bash" \
    "fish")
  good "✓ Shell: $USER_SHELL"
  echo ""

  # Browser preference with display names
  local browser_choice=$(
    gum choose --header "Select your preferred browser:" \
      "Firefox" \
      "Brave" \
      "Chromium" \
      "Google Chrome"
  )

  case "$browser_choice" in
  "Firefox")
    USER_BROWSER_PKG="firefox"
    USER_BROWSER_EXEC="firefox"
    USER_BROWSER_DISPLAY="Firefox"
    ;;
  "Brave")
    USER_BROWSER_PKG="brave-bin"
    USER_BROWSER_EXEC="brave"
    USER_BROWSER_DISPLAY="Brave"
    ;;
  "Chromium")
    USER_BROWSER_PKG="chromium"
    USER_BROWSER_EXEC="chromium"
    USER_BROWSER_DISPLAY="Chromium"
    ;;
  "Google Chrome")
    USER_BROWSER_PKG="google-chrome"
    USER_BROWSER_EXEC="google-chrome-stable"
    USER_BROWSER_DISPLAY="Google Chrome"
    ;;
  esac

  if [ -n "$USER_BROWSER_DISPLAY" ]; then
    good "✓ Browser: $USER_BROWSER_DISPLAY"
  fi
  echo ""

  # SDDM preference
  if gum confirm "Install SDDM login manager?"; then
    INSTALL_SDDM=true
    good "✓ SDDM will be installed"
  else
    INSTALL_SDDM=false
    warn "Skipping SDDM installation"
  fi
  echo ""

  good "This will download additional packages to your system"
  warn "Choose profile based on your needs"

  while true; do
    USER_PROFILE=$(gum choose --header "Select your profile:" \
      "minimal" \
      "developer" \
      "gamer" \
      "madlad")
    good "✓ Profile: $USER_PROFILE"
    echo ""

    if [ "$USER_PROFILE" = "madlad" ]; then
      warn "⚠️ This could take easily more than an hour or 2 to install"
      if gum confirm "Do you want to continue?"; then
        break
      else
        continue
      fi
    else
      break
    fi
  done

  # Summary
  header "Installation Summary"
  warn "Terminal: $USER_TERMINAL"
  warn "Shell: $USER_SHELL"
  [ -n "$USER_BROWSER_DISPLAY" ] && warn "Browser: $USER_BROWSER_DISPLAY"
  warn "SDDM: $([ "$INSTALL_SDDM" = true ] && echo "Yes" || echo "No")"
  warn "Profile: $USER_PROFILE"
  echo ""

  if ! gum confirm "Proceed with these settings?"; then
    bad "Installation cancelled"
    exit 0
  fi
}

# Build package list based on preferences
build_package_list() {
  header "Building Package List"

  # Official repo packages install in one fast pacman transaction; anything else comes from the AUR
  INSTALL_PACKAGES+=(
    git wget curl unzip jq python python-pillow base-devel pacman-contrib
    awww hyprlock hypridle hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    cliphist wl-clipboard xdg-user-dirs grim slurp tesseract tesseract-data-eng libnotify
    pipewire pipewire-pulse wireplumber pavucontrol playerctl cava brightnessctl
    networkmanager network-manager-applet bluez bluez-utils blueman polkit-kde-agent
    sysstat lm_sensors batsignal
    qt6-base qt6-declarative qt6-wayland
    # app-theme.py recolors Materia-dark (GTK) and MateriaDark (Kvantum); kde-gtk-config ships the colorreload GTK module
    materia-gtk-theme kvantum kvantum-theme-materia qt6ct-kde kde-gtk-config breeze-icons vimix-cursors
    # no dunst/mako/swaync: quickshell is the notification server
    fastfetch dolphin btop yazi tyr-bin starship neovim nano
    inter-font ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji
    # the default lock screen (hecate-lock.conf)
    ttf-fira-sans ttf-victor-mono
  )

  # quickshell and matugen are in the official repos; skip them when another build already provides the command
  have qs || INSTALL_PACKAGES+=(quickshell)
  have matugen || INSTALL_PACKAGES+=(matugen)
  # rustup counts as cargo, and the rust package conflicts with rustup
  have cargo || INSTALL_PACKAGES+=(rust)

  # Check if Hyprland is already installed
  if have Hyprland; then
    good "✓ Hyprland is already installed"
  else
    warn "Hyprland not found - will be installed"
    INSTALL_PACKAGES+=(cmake meson cpio pkg-config hyprland)
    HYPRLAND_NEWLY_INSTALLED=true
  fi

  # Terminal
  INSTALL_PACKAGES+=("$USER_TERMINAL")

  # Shell packages
  case "$USER_SHELL" in
  zsh)
    INSTALL_PACKAGES+=(zsh fzf bat eza fd thefuck)
    ;;
  bash)
    INSTALL_PACKAGES+=(bash fzf bat eza fd thefuck bash-completion)
    ;;
  fish)
    INSTALL_PACKAGES+=(fish fzf bat eza thefuck)
    ;;
  esac

  # Browser - add to package list
  if [ -n "$USER_BROWSER_PKG" ]; then
    INSTALL_PACKAGES+=("$USER_BROWSER_PKG")
  fi

  # SDDM
  if [ "$INSTALL_SDDM" = true ]; then
    # hecate-sddm is a Qt6 theme (Qt5Compat.GraphicalEffects)
    INSTALL_PACKAGES+=(sddm qt6-5compat qt6-svg)
  fi

  # Profile-based packages
  case "$USER_PROFILE" in
  developer)
    add_developer_packages
    ;;
  gamer)
    add_gamer_packages
    ;;
  madlad)
    warn "Adding all packages..."
    add_developer_packages
    add_gamer_packages
    ;;
  esac

  mapfile -t INSTALL_PACKAGES < <(printf '%s\n' "${INSTALL_PACKAGES[@]}" | awk '!seen[$0]++')
  warn "Total packages to install: ${#INSTALL_PACKAGES[@]}"
}

# Add developer packages
add_developer_packages() {
  local dev_types=$(gum choose --no-limit --header "Select development areas (Space to select, Enter to confirm):" \
    "AI/ML" \
    "Web Development" \
    "Server/Backend" \
    "Database" \
    "Mobile Development" \
    "DevOps" \
    "Game Development" \
    "Skip")

  if echo "$dev_types" | grep -q "Skip"; then
    warn "Skipping developer packages"
    return
  fi

  if echo "$dev_types" | grep -q "AI/ML"; then
    warn "Adding AI/ML packages..."
    INSTALL_PACKAGES+=(python python-pip python-numpy python-pandas python-matplotlib python-scikit-learn)
  fi

  if echo "$dev_types" | grep -q "Web Development"; then
    warn "Adding Web Development packages..."
    INSTALL_PACKAGES+=(nodejs npm yarn)
  fi

  if echo "$dev_types" | grep -q "Server/Backend"; then
    warn "Adding Server/Backend packages..."
    INSTALL_PACKAGES+=(docker docker-compose)
  fi

  if echo "$dev_types" | grep -q "Database"; then
    warn "Adding Database packages..."
    INSTALL_PACKAGES+=(postgresql sqlite)

    if gum confirm "Install MySQL/MariaDB?"; then
      INSTALL_PACKAGES+=(mariadb)
    fi

    if gum confirm "Install Redis?"; then
      INSTALL_PACKAGES+=(redis)
    fi
  fi

  if echo "$dev_types" | grep -q "Mobile Development"; then
    warn "Adding Mobile Development packages..."
    INSTALL_PACKAGES+=(android-tools)
  fi

  if echo "$dev_types" | grep -q "DevOps"; then
    warn "Adding DevOps packages..."
    INSTALL_PACKAGES+=(docker kubectl terraform ansible)
  fi

  if echo "$dev_types" | grep -q "Game Development"; then
    warn "Adding Game Development packages..."
    INSTALL_PACKAGES+=(godot blender)
  fi
}

# Add gamer packages
add_gamer_packages() {
  warn "Adding gaming packages..."

  INSTALL_PACKAGES+=(steam lutris wine-staging winetricks gamemode lib32-gamemode mangohud lib32-mangohud)

  if gum confirm "Install Discord?"; then
    INSTALL_PACKAGES+=(discord)
  fi

  if gum confirm "Install emulators?"; then
    local emulators=$(gum choose --no-limit --header "Select emulators (Space to select, Enter to confirm):" \
      "RetroArch" \
      "PCSX2" \
      "Dolphin" \
      "RPCS3" \
      "Skip")

    if ! echo "$emulators" | grep -q "Skip"; then
      echo "$emulators" | grep -q "RetroArch" && INSTALL_PACKAGES+=(retroarch retroarch-assets-xmb retroarch-assets-ozone)
      echo "$emulators" | grep -q "PCSX2" && INSTALL_PACKAGES+=(pcsx2)
      echo "$emulators" | grep -q "Dolphin" && INSTALL_PACKAGES+=(dolphin-emu)
      echo "$emulators" | grep -q "RPCS3" && INSTALL_PACKAGES+=(rpcs3-bin)
    fi
  fi

  if gum confirm "Install ProtonUp-Qt (for managing Proton-GE)?"; then
    INSTALL_PACKAGES+=(protonup-qt)
  fi
}

install_packages() {
  header "Installing Packages"

  # One unknown name aborts a whole pacman or AUR transaction, so sort the list first:
  # official repo packages go through pacman, everything else through the AUR helper
  local repo=() aur=() p
  declare -A in_repo=()
  while read -r p; do in_repo[$p]=1; done < <(pacman -Slq)
  for p in "${INSTALL_PACKAGES[@]}"; do
    pacman -Qq "$p" &>/dev/null && continue
    if [ -n "${in_repo[$p]:-}" ]; then repo+=("$p"); else aur+=("$p"); fi
  done
  FAILED_PACKAGES=()

  if [ ${#repo[@]} -eq 0 ] && [ ${#aur[@]} -eq 0 ]; then
    good "✓ All packages are already installed"
    return 0
  fi

  if [ ${#repo[@]} -gt 0 ]; then
    warn "Installing ${#repo[@]} packages from the official repos..."
    sudo pacman -S --needed --noconfirm "${repo[@]}" || bad "✗ pacman could not install everything (a stale database can cause this, try: sudo pacman -Syu)"
  fi

  if [ ${#aur[@]} -gt 0 ]; then
    if [ "$PACKAGE_MANAGER" = "pacman" ]; then
      install_aur_helper || warn "No AUR helper, skipping: ${aur[*]}"
    fi
    if [ "$PACKAGE_MANAGER" != "pacman" ]; then
      warn "Installing ${#aur[@]} AUR packages with $PACKAGE_MANAGER: ${aur[*]}"
      if ! $PACKAGE_MANAGER -S --needed --noconfirm "${aur[@]}"; then
        warn "Retrying one at a time so a single failure doesn't block the rest..."
        for p in "${aur[@]}"; do
          pacman -Qq "$p" &>/dev/null || $PACKAGE_MANAGER -S --needed --noconfirm "$p" || true
        done
      fi
    fi
  fi

  for p in "${repo[@]}" "${aur[@]}"; do
    pacman -Qq "$p" &>/dev/null || FAILED_PACKAGES+=("$p")
  done

  if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    bad "✗ Not installed: ${FAILED_PACKAGES[*]}"
    printf '%s\n' "${FAILED_PACKAGES[@]}" >"$HOME/hecate_failed_packages.txt"
    warn "Saved to ~/hecate_failed_packages.txt, install them later with: $PACKAGE_MANAGER -S \$(cat ~/hecate_failed_packages.txt)"
  else
    good "✓ All packages installed"
  fi
  return 0
}

# Install AUR helper (paru or yay)
install_aur_helper() {
  header "Installing AUR Helper"
  warn "An AUR helper is required for some packages"
  echo ""

  if ! gum confirm "Install paru AUR helper now?"; then
    return 1
  fi

  warn "Installing build dependencies..."
  if ! sudo pacman -S --needed --noconfirm base-devel git; then
    bad "Failed to install build dependencies"
    return 1
  fi

  warn "Building paru from AUR..."
  local temp_dir="/tmp/paru-install-$$"
  mkdir -p "$temp_dir"

  if ! git clone --depth 1 https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
    bad "Failed to clone paru repository"
    rm -rf "$temp_dir"
    return 1
  fi

  cd "$temp_dir/paru"

  if makepkg -si --noconfirm; then
    cd "$HOME"
    rm -rf "$temp_dir"
    PACKAGE_MANAGER="paru"
    good "✓ Paru installed successfully!"
    return 0
  else
    cd "$HOME"
    rm -rf "$temp_dir"
    bad "✗ Failed to build paru"

    if gum confirm "Try installing yay instead?"; then
      if sudo pacman -S --needed --noconfirm yay; then
        PACKAGE_MANAGER="yay"
        good "✓ Yay installed successfully!"
        return 0
      fi
    fi
    return 1
  fi
}

# level|command|package|what needs it ("req" breaks the shell, "opt" only costs a feature)
TOOLS=(
  "req|Hyprland|hyprland|the compositor"
  "req|hyprctl|hyprland|live settings and monitors"
  "req|qs|quickshell|the bar, widgets and panels"
  "req|matugen|matugen|wallpaper colors"
  "req|awww|awww|the wallpaper"
  "req|hypridle|hypridle|idle and screen lock"
  "req|hyprlock|hyprlock|the lock screen"
  "req|jq|jq|set-wallpaper.sh and the bar"
  "req|python3|python|reading hecate.toml"
  "req|wpctl|wireplumber|volume control"
  "req|cliphist|cliphist|clipboard history"
  "req|wl-copy|wl-clipboard|the clipboard"
  "req|grim|grim|screenshots"
  "req|slurp|slurp|screenshots"
  "req|starship|starship|the prompt"
  "opt|cava|cava|the desktop audio visualizer"
  "opt|playerctl|playerctl|media controls"
  "opt|brightnessctl|brightnessctl|brightness keys"
  "opt|nmcli|networkmanager|Wi-Fi in hecate-settings"
  "opt|nm-applet|network-manager-applet|the network tray icon"
  "opt|nm-connection-editor|network-manager-applet|the connectivity right-click"
  "opt|bluetoothctl|bluez-utils|Bluetooth in hecate-settings"
  "opt|blueman-manager|blueman|the Bluetooth right-click"
  "opt|pactl|pipewire-pulse|switching audio outputs"
  "opt|pavucontrol|pavucontrol|the volume right-click"
  "opt|mpstat|sysstat|per-core CPU stats"
  "opt|sensors|lm_sensors|temperature readings"
  "opt|batsignal|batsignal|low battery warnings"
  "opt|tesseract|tesseract|OCR screenshots"
  "opt|notify-send|libnotify|notifications from the scripts"
  "opt|hyprpicker|hyprpicker|the color picker keybind"
  "opt|dolphin|dolphin|the file manager keybind"
  "opt|qt6ct|qt6ct-kde|Qt theming (QT_QPA_PLATFORMTHEME=qt6ct)"
  "opt|cargo|rust|building hecate-settings"
  "opt|qmake6|qt6-base|building hecate-settings"
)

# font family|package|what needs it
FONTS=(
  "Symbols Nerd Font|ttf-nerd-fonts-symbols|every icon in the bar and hecate-settings"
  "Inter|inter-font|the shell font"
  "JetBrainsMono Nerd Font|ttf-jetbrains-mono-nerd|the terminal"
  "Noto Color Emoji|noto-fonts-emoji|emoji"
  "Fira Sans|ttf-fira-sans|the lock screen clock"
  "Victor Mono|ttf-victor-mono|the lock screen date and uptime"
)

# path (absolute, or relative to /usr/share, ~/.local/share and ~/.)|package|what needs it
THEMES=(
  "/usr/share/themes/Materia-dark|materia-gtk-theme|the Hecate GTK theme (app-theme.py recolors it)"
  "/usr/share/Kvantum/MateriaDark|kvantum-theme-materia|the Hecate Qt theme (app-theme.py recolors it)"
  "/usr/lib/gtk-3.0/modules/libcolorreload-gtk-module.so|kde-gtk-config|live GTK recoloring (gtk-modules in gtk-3.0/settings.ini)"
  "icons/breeze-dark|breeze-icons|GTK and Qt icons"
  "icons/Vimix-cursors|vimix-cursors|the cursor"
)

have_theme() {
  case "$1" in /*) [ -e "$1" ]; return ;; esac
  [ -e "/usr/share/$1" ] || [ -e "$HOME/.local/share/$1" ] || [ -e "$HOME/.$1" ]
}

# toml_get <section> <key>: reads ~/.config/hecate/hecate.toml, prints nothing when unavailable
toml_get() {
  python3 -c "import sys, tomllib; print(tomllib.load(open(sys.argv[1], 'rb')).get(sys.argv[2], {}).get(sys.argv[3], ''))" \
    "$HOME/.config/hecate/hecate.toml" "$1" "$2" 2>/dev/null || true
}

have_font() { fc-list : family 2>/dev/null | tr ',' '\n' | grep -qixF -- "$1"; }

# Prints what is missing and fills MISSING_PKGS; returns 1 only when something required is missing
check_system() {
  header "Checking Dependencies and Fonts"
  MISSING_PKGS=()
  local tools=("${TOOLS[@]}") entry level cmd pkg why font found=0 required_missing=0
  [ -n "$USER_TERMINAL" ] && tools+=("req|$USER_TERMINAL|$USER_TERMINAL|your terminal")

  for entry in "${tools[@]}"; do
    IFS='|' read -r level cmd pkg why <<<"$entry"
    if have "$cmd"; then
      found=$((found + 1))
      continue
    fi
    if [ "$level" = req ]; then
      bad "✗ $cmd is missing, needed for $why (package: $pkg)"
      required_missing=$((required_missing + 1))
    else
      warn "! $cmd is missing, needed for $why (package: $pkg)"
    fi
    MISSING_PKGS+=("$pkg")
  done

  if have python3 && ! python3 -c 'import tomllib' 2>/dev/null; then
    bad "✗ python3 is older than 3.11 and has no tomllib, so the shell can't read hecate.toml"
    required_missing=$((required_missing + 1))
  fi

  if have fc-list; then
    for entry in "${FONTS[@]}"; do
      IFS='|' read -r font pkg why <<<"$entry"
      have_font "$font" && continue
      warn "! font '$font' is missing, used for $why (package: $pkg)"
      MISSING_PKGS+=("$pkg")
    done
    font=$(toml_get theme font)
    if [ -n "$font" ] && [ "$font" != "Inter" ] && ! have_font "$font"; then
      warn "! the font '$font' chosen in hecate.toml is not installed"
    fi
  else
    warn "! fc-list is missing, so fonts can't be checked (package: fontconfig)"
    MISSING_PKGS+=(fontconfig)
  fi

  local path
  for entry in "${THEMES[@]}"; do
    IFS='|' read -r path pkg why <<<"$entry"
    have_theme "$path" && continue
    warn "! ${path##*/} is missing, used for $why (package: $pkg)"
    MISSING_PKGS+=("$pkg")
  done

  # A second daemon gets D-Bus activated by the first notification sent before quickshell is up and keeps the name
  for cmd in dunst mako swaync; do
    have "$cmd" && warn "! $cmd is installed and can take notifications from quickshell (remove it: sudo pacman -Rns $cmd)"
  done

  if have nmcli && ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
    warn "! NetworkManager isn't running, so Wi-Fi in hecate-settings stays empty (sudo systemctl enable --now NetworkManager)"
  fi
  if have bluetoothctl && ! systemctl is-active --quiet bluetooth 2>/dev/null; then
    warn "! bluetooth.service isn't running (sudo systemctl enable --now bluetooth)"
  fi
  if [ ! -x "$HOME/.local/bin/hecate-settings" ] || [ ! -f "$HOME/.local/share/applications/hecate-settings.desktop" ]; then
    warn "! hecate-settings is not installed (run $HECATEAPPSDIR/hecate-settings/install.sh)"
  fi

  mapfile -t MISSING_PKGS < <(printf '%s\n' "${MISSING_PKGS[@]}" | awk 'NF && !seen[$0]++')
  if [ ${#MISSING_PKGS[@]} -eq 0 ] && [ "$required_missing" -eq 0 ]; then
    good "✓ Everything checks out ($found tools found, fonts installed)"
  fi
  [ "$required_missing" -eq 0 ]
}

# Checks after installing: offers to install whatever is missing, then re-checks
verify_system() {
  local ok=true
  check_system || ok=false
  if [ ${#MISSING_PKGS[@]} -gt 0 ] && gum confirm "Install the missing packages now? (${MISSING_PKGS[*]})"; then
    INSTALL_PACKAGES=("${MISSING_PKGS[@]}")
    install_packages
    ok=true
    check_system || ok=false
  fi
  if [ "$ok" = false ] && ! gum confirm "Required tools are still missing. Continue anyway?"; then
    bad "Installation aborted"
    exit 1
  fi
  return 0
}

# hecate-settings builds in the background (it is CPU-bound) while configs, plugins and wallpapers
# (disk and network) are set up, then finish_settings_build reports the result
start_settings_build() {
  local dir="$HECATEAPPSDIR/hecate-settings"
  if [ ! -f "$dir/install.sh" ]; then
    warn "hecate-settings not found in $HECATEAPPSDIR, skipping"
    return 0
  fi
  if have rustup && ! cargo --version &>/dev/null; then
    warn "Setting up the Rust toolchain first..."
    rustup default stable || true
  fi
  good "Building hecate-settings in the background (log: $SETTINGS_LOG)"
  setsid -w bash "$dir/install.sh" >"$SETTINGS_LOG" 2>&1 &
  BUILD_PID=$!
}

finish_settings_build() {
  [ -n "$BUILD_PID" ] || return 0
  kill -0 "$BUILD_PID" 2>/dev/null && warn "Waiting for the hecate-settings build to finish..."
  if wait "$BUILD_PID"; then
    good "✓ hecate-settings installed to ~/.local/bin (with its icon and desktop entry)"
  else
    bad "✗ hecate-settings failed to build, the end of $SETTINGS_LOG:"
    tail -n 15 "$SETTINGS_LOG" >&2
    warn "Retry later with: $HECATEAPPSDIR/hecate-settings/install.sh"
  fi
  BUILD_PID=""
  return 0
}

stop_settings_build() {
  if [ -n "$BUILD_PID" ]; then
    kill -- "-$BUILD_PID" 2>/dev/null || kill "$BUILD_PID" 2>/dev/null || true
  fi
}

# Enable SDDM after installation
enable_sddm() {
  if [ "$INSTALL_SDDM" != true ]; then
    return
  fi

  # Verify SDDM actually installed
  if ! pacman -Q sddm &>/dev/null; then
    bad "✗ SDDM was not installed successfully"
    warn "Skipping SDDM configuration"
    return
  fi

  header "Enabling SDDM"

  local current_dm=$(systemctl is-enabled display-manager.service 2>/dev/null || echo "none")

  if [ "$current_dm" != "none" ] && [ "$current_dm" != "sddm.service" ]; then
    warn "Detected existing display manager: $current_dm"

    if gum confirm "Disable $current_dm and enable SDDM instead?"; then
      warn "Disabling $current_dm..."
      sudo systemctl disable display-manager.service 2>/dev/null || true
      sudo systemctl disable "$current_dm" 2>/dev/null || true

      warn "Enabling SDDM..."
      if sudo systemctl enable sddm && sudo systemctl set-default graphical.target; then
        good "✓ SDDM enabled successfully!"
      else
        bad "✗ Failed to enable SDDM"
        warn "You may need to enable it manually"
      fi
    else
      warn "Keeping existing display manager"
    fi
  else
    if sudo systemctl enable sddm && sudo systemctl set-default graphical.target; then
      good "✓ SDDM enabled successfully!"
    else
      bad "✗ Failed to enable SDDM"
    fi
  fi
}

# Install shell scripts to ~/.local/bin
install_shell_scripts() {
  header "Installing Shell Scripts"

  mkdir -p "$HOME/.local/bin"

  local scripts_dir="$HECATEDIR/config/local-bin"

  if [ ! -d "$scripts_dir" ]; then
    warn "⚠ Scripts directory not found at $scripts_dir"
    return
  fi

  # Install hecate.sh
  if [ -f "$scripts_dir/hecate.sh" ]; then
    echo "Installing hecate script..."
    cp "$scripts_dir/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    echo "✓ hecate installed to ~/.local/bin/hecate"
  else
    warn "⚠ hecate.sh not found at $scripts_dir/hecate.sh"
  fi

  if [ -f "$scripts_dir/termkeys.sh" ]; then
    cp "$scripts_dir/termkeys.sh" "$HOME/.local/bin/termkeys"
    chmod +x "$HOME/.local/bin/termkeys"
    echo "✓ termkeys installed to ~/.local/bin/termkeys"
  fi
  echo ""
  good "✓ Shell scripts installed successfully!"
}

# Move configs from cloned repo to ~/.config
move_config() {
  header "Installing Configuration Files"

  if [ ! -d "$HECATEDIR/config" ]; then
    bad "Error: Config directory not found at $HECATEDIR/config"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  for item in "$HECATEDIR/config"/*; do
    if [ -d "$item" ]; then
      local item_name
      item_name=$(basename "$item")

      [ "$item_name" = "local-bin" ] && continue

      case "$item_name" in
        alacritty|foot|ghostty|kitty)
          if [ "$item_name" = "$USER_TERMINAL" ]; then
            warn "Installing $item_name config..."
            safe_copy_dir "$item" "$CONFIGDIR/$item_name"
          fi
          ;;
        hypr)
          # Explicit loud handling — this one must succeed
          warn "Installing hypr config..."
          if ! safe_copy_dir "$item" "$CONFIGDIR/hypr"; then
            bad "✗ CRITICAL: Failed to install hypr config!"
            exit 1
          fi
          good "✓ hypr config installed ($(ls "$CONFIGDIR/hypr" | wc -l) items)"
          ;;
        *)
          warn "Installing $item_name..."
          safe_copy_dir "$item" "$CONFIGDIR/$item_name"
          ;;
      esac
    fi
  done

  # Shell rc files
  if [ -f "$HECATEDIR/config/zsh/zshrc" ]; then
    safe_copy_file "$HECATEDIR/config/zsh/zshrc" "$HOME/.zshrc"
    good "✓ .zshrc installed"
  fi

  if [ -f "$HECATEDIR/config/bash/bashrc" ]; then
    safe_copy_file "$HECATEDIR/config/bash/bashrc" "$HOME/.bashrc"
    good "✓ .bashrc installed"
  fi

  install_shell_scripts

  good "✓ Configuration files installed successfully!"
}

# Helper function to install apps
# install_app() {
#   local app_name="$1"
#   local app_path="$2"
#   local app_display="${3:-$app_name}"

#   if [ -f "$app_path" ]; then
#     echo "Installing $app_display..."
#     cp "$app_path" "$HOME/.local/bin/$app_name"
#     chmod +x "$HOME/.local/bin/$app_name"
#     echo "✓ $app_display installed to ~/.local/bin/$app_name"
#   else
#     warn "⚠ $app_display binary not found at $app_path"
#   fi
# }

# Build preferred app keybind
build_preferd_app_keybind() {
  header "Configuring App Keybinds"

  mkdir -p ~/.config/hypr/configs/UserConfigs

  cat >~/.config/hypr/configs/UserConfigs/app-names.conf <<EOF
# Set your default applications here
\$term = $USER_TERMINAL
\$browser = $USER_BROWSER_EXEC
EOF

  good "✓ App keybinds configured!"
  warn "Terminal: $USER_TERMINAL"
  [ -n "$USER_BROWSER_DISPLAY" ] && warn "Browser: $USER_BROWSER_DISPLAY"
}

build_quickApps(){
      header "Configuring Widgets"

  cat >~/.config/hecate/quickapps.conf <<EOF
# Quick Apps Configuration
# Syntax name=command
# Max 12 characters in name
Browser=$USER_BROWSER_EXEC
Terminal=$USER_TERMINAL
Files=dolphin
EOF
    good "✓ widget configured!"
}
# Update ~/.config/hecate/hecate.toml in place so the shipped [bar], [widgets] and [desktop] settings survive
create_hecate_config() {
  header "Updating Hecate Configuration"

  local config_file="$HOME/.config/hecate/hecate.toml"
  local version="1.0.0"
  local install_date
  install_date=$(date +%Y-%m-%d)

  # Try to get version from remote
  if have curl; then
    local remote_version
    remote_version=$(curl -fsS --max-time 5 "https://raw.githubusercontent.com/Nurysso/Hecate/main/version.txt" 2>/dev/null || echo "")
    [ -n "$remote_version" ] && version="$remote_version"
  fi

  mkdir -p "$(dirname "$config_file")"

  # Ask about theme mode
  local theme_mode
  theme_mode=$(gum choose --header "Select theme mode:" \
    "dynamic - Auto-update colors from wallpaper" \
    "static - Keep colors unchanged")

  if echo "$theme_mode" | grep -q "dynamic"; then
    theme_mode="dynamic"
  else
    theme_mode="static"
  fi

  if [ ! -f "$config_file" ]; then
    cat >"$config_file" <<TOML
[metadata]
version = ""
install_date = ""
last_update = ""
repo_url = "$REPO_URL"

[theme]
mode = ""
font = "Inter"

[preferences]
term = ""
browser = ""
shell = ""
profile = ""
TOML
  fi

  set_toml() { sed -i "s|^$1 = .*|$1 = \"$2\"|" "$config_file"; }
  set_toml version "$version"
  set_toml install_date "$install_date"
  set_toml last_update "$install_date"
  set_toml mode "$theme_mode"
  set_toml term "$USER_TERMINAL"
  set_toml browser "$USER_BROWSER_EXEC"
  set_toml shell "$USER_SHELL"
  set_toml profile "$USER_PROFILE"

  good "✓ Hecate config updated at: $config_file"
  warn "Theme mode: $theme_mode"
}

# Build the Hecate GTK/Kvantum themes (Materia recolored from the wallpaper) and apply them with the icon/cursor/font settings
apply_gtk_theme() {
  local theme="Hecate"
  if [ ! -d /usr/share/themes/Materia-dark ]; then
    warn "Materia-dark not installed, falling back to Adwaita for GTK"
    theme="Adwaita-dark"
  fi
  python3 "$HOME/.config/hecate/scripts/app-theme.py" || warn "Could not generate the Hecate GTK/Qt themes"
  if have gsettings; then
    gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "breeze-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Vimix-cursors" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font Mono 12" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
  fi
}

# Setup link system colors
setup_Symlinks() {
  warn "Adding symlinks..."

  local STARSHIP_SYMLINK="$HOME/.config/starship.toml"
  local HYPRLOCK_SYMLINK="$HOME/.config/hypr/hyprlock.conf"

  safe_remove "$STARSHIP_SYMLINK"
  safe_remove "$HYPRLOCK_SYMLINK"

  ln -s "$HOME/.config/starship/starship.toml" "$STARSHIP_SYMLINK"
  ln -s "$HOME/.config/hypr/hyprlock/hecate-lock.conf" "$HYPRLOCK_SYMLINK"

  good "✓ Symlinks configured!"
}

# Set default shell
set_default_shell() {
  local current_shell=$(basename "$SHELL")

  if [ "$current_shell" = "$USER_SHELL" ]; then
    good "✓ $USER_SHELL is already your default shell"
    return
  fi

  # Verify the shell is actually installed
  if ! command -v "$USER_SHELL" &>/dev/null; then
    bad "✗ $USER_SHELL is not installed!"
    warn "Cannot set as default shell"
    return 1
  fi

  if gum confirm "Set $USER_SHELL as default shell?"; then
    local shell_path=$(which "$USER_SHELL")

    if [ -z "$shell_path" ]; then
      bad "Error: $USER_SHELL not found in PATH"
      return 1
    fi

    # Check if shell is in /etc/shells
    if ! grep -q "^${shell_path}$" /etc/shells; then
      warn "Adding $shell_path to /etc/shells..."
      echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
    fi

    warn "Changing default shell to $USER_SHELL..."

    if sudo chsh -s "$shell_path" "$USER"; then
      good "✓ $USER_SHELL set as default shell!"
      warn "Note: Log out and log back in for this to take effect"
    else
      bad "✗ Failed to change shell"
      warn "Try manually: chsh -s $shell_path"
      return 1
    fi
  fi
}

# install_extra_tools(){
#   gum style \
#     --foreground 212 --border-foreground 212 \
#     --align center \
#     'Installing Aoiler helper tyr' 'used to organize dirs'
#   gum style \
#     --foreground 212 --border-foreground 212 \
#     --align center \
#     'Installing Yazi plugins...'
#     # ya pkg install
# }


# Configure SDDM theme at the end
configure_sddm_theme() {
  if [ "$INSTALL_SDDM" != true ]; then
    return
  fi

  header "SDDM Theme Configuration"

  local choice
  choice=$(gum choose --header "Select an SDDM theme:" \
    "Hecate - matches the startup fade" \
    "Astronaut" \
    "Skip")

  if [[ "$choice" == Hecate* ]]; then
    local dest="/usr/share/sddm/themes/hecate-sddm"
    if sudo rm -rf --preserve-root -- "$dest" && sudo cp -r "$HECATEDIR/hecate-sddm" "$dest" &&
      sudo mkdir -p /etc/sddm.conf.d &&
      printf '[Theme]\nCurrent=hecate-sddm\n' | sudo tee /etc/sddm.conf.d/hecate.conf >/dev/null; then
      good "✓ hecate-sddm installed and set as the SDDM theme"
    else
      bad "✗ hecate-sddm installation failed"
    fi
  elif [ "$choice" = "Astronaut" ]; then
    warn "Installing SDDM theme..."

    local theme_script="/tmp/sddm-astronaut-setup.sh"
    if curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh -o "$theme_script"; then
      chmod +x "$theme_script"
      if bash "$theme_script"; then
        good "✓ SDDM theme installed!"
      else
        bad "✗ SDDM theme installation failed"
      fi
      rm -f "$theme_script"
    else
      bad "✗ Failed to download SDDM theme installer"
    fi
  else
    warn "Skipping SDDM theme installation"
  fi
}

# Setup wallpapers
setup_wallpapers() {
  header "Wallpaper Setup"

  local wallpaper_dir="$HOME/Pictures/Wallpapers"

  echo ""
  warn "Would you like to download the full wallpaper collection?"
  echo ""

  if gum confirm "Download full wallpaper repository?"; then
    # User wants full collection
    good "Downloading wallpaper collection (sparse checkout of images folder)..."

    # Backup existing wallpapers if path exists (could be file, dir, or symlink)
    if [ -e "$wallpaper_dir" ] || [ -L "$wallpaper_dir" ]; then
      local backup_dir="$HOME/Pictures/wallpapers-backup-$(date +%Y%m%d_%H%M%S)"
      warn "Backing up existing wallpapers to: $backup_dir"

      if [ -L "$wallpaper_dir" ]; then
        # It's a symlink, just remove it
        rm -f "$wallpaper_dir"
      elif [ -d "$wallpaper_dir" ]; then
        # It's a directory, move it
        mv "$wallpaper_dir" "$backup_dir"
      elif [ -f "$wallpaper_dir" ]; then
        # It's a file, move it
        mv "$wallpaper_dir" "$backup_dir"
      fi
    fi

    # Create temporary directory for sparse checkout
    local temp_dir="$HOME/Pictures/aesthetic-wallpapers-temp"
    mkdir -p "$temp_dir"

    # Perform sparse checkout
    (
      cd "$temp_dir" || exit 1
      git init
      git remote add origin "https://github.com/D3Ext/aesthetic-wallpapers.git"
      git sparse-checkout init --cone
      git sparse-checkout set --no-cone images
      git pull origin main
    )

    if [ -d "$temp_dir/images" ]; then
      # Move the images folder to wallpaper_dir
      mv "$temp_dir/images" "$wallpaper_dir"
      rm -rf "$temp_dir"
      echo "✓ Full wallpaper collection downloaded!"
    else
      bad "✗ Images folder not found in repository"
      rm -rf "$temp_dir"
      return 1
    fi
  else
    # User wants only default wallpapers
    good "Downloading default wallpapers..."
    local default_dir="$wallpaper_dir"
    mkdir -p "$default_dir"

    local lock_screen_url="https://raw.githubusercontent.com/D3Ext/aesthetic-wallpapers/refs/heads/main/images/3squares.png"
    local wallpaper_url="https://raw.githubusercontent.com/D3Ext/aesthetic-wallpapers/refs/heads/main/images/falltree.jpg"

    curl -fsSL "$lock_screen_url" -o "$default_dir/lock-screen.png" &
    curl -fsSL "$wallpaper_url" -o "$default_dir/wallpaper.png" &
    wait
    for f in lock-screen.png wallpaper.png; do
      [ -s "$default_dir/$f" ] && good "✓ $f downloaded" || bad "✗ $f failed to download"
    done

    echo ""
    echo "✓ Default wallpapers downloaded!"
  fi

  echo ""
  good "Wallpapers saved to: $wallpaper_dir"
}

# Main function
main() {
  # Parse arguments
  case "${1:-}" in
  --help | -h)
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./install.sh              Run the installer"
    echo "  ./install.sh --check      Only check dependencies and fonts, change nothing"
    echo "  ./install.sh --no-deps    Skip package installation (configs, hecate-settings and wallpapers only)"
    echo "  ./install.sh --help       Show this message"
    echo "  ./install.sh --dry-run    ...why though?"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  • gum - Interactive CLI tool (sudo pacman -S gum)"
    echo "  • paru or yay (recommended) - needed for the few AUR packages"
    echo ""
    echo -e "${YELLOW}Environment:${NC}"
    echo "  HECATEDIR=<dir>   Where the repo is cloned (default: ~/Hecate)"
    exit 0
    ;;
  --dry-run)
    echo -e "${BLUE}The \"I want to feel productive without doing anything mode\"${NC}"
    echo -e "${YELLOW}Simulating installation...${NC}"
    echo ""
    echo -e "${GREEN}✓ System check: Passed (probably)${NC}"
    echo -e "${GREEN}✓ Packages: Would install ~47 packages${NC}"
    echo -e "${GREEN}✓ Configs: Would copy lots of dotfiles${NC}"
    echo ""
    echo -e "${YELLOW}Congratulations! You've successfully done... nothing.${NC}"
    echo -e "${ORANGE}Run without --dry-run when you're ready to actually install.${NC}"
    echo ""
    echo -e "${RED}Pro tip: Dry runs don't make your setup any cooler.${NC}"
    echo -e "${BLUE}Want a real one? Try: ./install.sh --check${NC}"
    exit 0
    ;;
  --check)
    CHECK_ONLY=true
    ;;
  --no-deps)
    SKIP_PACKAGES=true
    ;;
  -*)
    echo -e "${RED}Unknown option: $1${NC}"
    echo -e "${BLUE}Try: ./install.sh --help${NC}"
    exit 1
    ;;
  esac

  if [ "$CHECK_ONLY" = true ]; then
    PACKAGE_MANAGER=$(basename "$(command -v paru || command -v yay || command -v pacman)")
    USER_TERMINAL=$(toml_get preferences term)
    local result=0
    check_system || result=1
    [ ${#MISSING_PKGS[@]} -gt 0 ] && warn "Install them with: $PACKAGE_MANAGER -S --needed ${MISSING_PKGS[*]}"
    exit $result
  fi

  trap stop_settings_build EXIT
  clear

  # Confirm installation
  if ! gum confirm "Do you want to proceed with Hecate installation?"; then
    clear
    warn "Installation cancelled by user"
    # Force exit with explicit return code
    exec false
  fi

  get_packageManager

  # Ask everything up front so the rest runs without waiting on you
  ask_preferences

  if [ "$SKIP_PACKAGES" = false ]; then
    build_package_list
    install_packages
    enable_sddm
  fi

  clone_dotfiles

  # Needs the repo and the Qt/Rust packages, runs alongside everything below
  start_settings_build

  backup_config
  move_config
  setup_Symlinks
  apply_gtk_theme
  build_preferd_app_keybind
  build_quickApps
  create_hecate_config

  set_default_shell
  setup_wallpapers
  configure_sddm_theme

  finish_settings_build

  if [ "$SKIP_PACKAGES" = false ]; then
    verify_system
  fi

  # Completion message
  header "Installation Complete"

  if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    warn "Note: Some packages failed to install"
    warn "Check ~/hecate_failed_packages.txt for details"
  else
    good "(surprisingly, nothing exploded)"
  fi

  echo ""
  good "Post-Install TODO:"
  good "1. Reboot (or live dangerously and just re-login)"
  good "2. Log into Hyprland"
  good "3. Take screenshot"
  good "4. Post to r/unixporn"
  echo ""
  good "May your wallpapers be dynamic and your RAM usage low."
  echo ""
  if gum confirm "Reboot now?"; then
    good "Rebooting..."
    sudo reboot
  else
    warn "Remember to reboot to apply all changes!"
  fi

}

# Run main function with arguments
main "$@"

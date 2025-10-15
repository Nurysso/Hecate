#!/bin/bash

# Hyprland Dotfiles Installer with Gum
# Description: Interactive installer for Hyprland configuration

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Global Variables
HECATEDIR="$HOME/Hecate"
HECATEAPPSDIR="$HOME/Hecate/apps"
CONFIGDIR="$HOME/.config"
REPO_URL="https://github.com/Aelune/Hecate.git"
OS=""
PACKAGE_MANAGER=""
HYPRLAND_NEWLY_INSTALLED=false

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

# Check if gum is installed
check_gum() {
  if ! command -v gum &>/dev/null; then
    echo -e "${RED}Gum is not installed!${NC}"
    echo -e "${YELLOW}Gum is required for this installer to work.${NC}"
    echo ""
    echo "Please install Gum using one of the following methods:"
    echo ""
    echo "Arch Linux:"
    echo "  sudo pacman -S gum"
    echo ""
    echo "Fedora:"
    echo "  sudo dnf install gum"
    echo ""
    echo "Or visit: https://github.com/charmbracelet/gum"
    exit 1
  fi
}

# Checks user OS runs only in arch shows warning in fedora and quits in ubuntu or other any other OS
check_OS() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    arch | manjaro | endeavouros)
      OS="arch"
      gum style --foreground 82 "✓ Detected OS: $OS"
      ;;
    fedora)
      gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
      gum style --foreground 220 "Proceed at your own risk or follow the Fedora guide if available at https://github.com/Aelune/Hecate/tree/main/documentation/install-fedora.md"
      OS="fedora"
      ;;
    ubuntu | debian | pop | linuxmint)
      gum style --foreground 196 --bold "❌ Error: Ubuntu/Debian-based OS detected!"
      gum style --foreground 220 "Hecate installer does not support Ubuntu automatically."
      gum style --foreground 220 "Please follow manual installation instructions:"
      gum style --foreground 220 "https://github.com/Aelune/Hecate/tree/main/documentation/install-ubuntu.md"
      exit 1
      ;;
    *)
      gum style --foreground 196 --bold "Error: OS '$ID' is not supported!"
      exit 1
      ;;
    esac
  else
    gum style --foreground 196 --bold "Error: Cannot detect OS!"
    exit 1
  fi
}

# Get package manager
get_packageManager() {
  case "$OS" in
  arch)
    if command -v paru &>/dev/null; then
      PACKAGE_MANAGER="paru"
    elif command -v yay &>/dev/null; then
      PACKAGE_MANAGER="yay"
    elif command -v pacman &>/dev/null; then
      PACKAGE_MANAGER="pacman"
    fi
    ;;
  fedora)
    if ! gum confirm "Do you want to continue on Fedora? Its not tested"; then
      gum style --foreground 196 "Aborting installation on Fedora."
      exit 1
    fi
    PACKAGE_MANAGER="dnf"
    ;;
  *)
    gum style --foreground 196 --bold "Error: No supported OS detected for package management!"
    exit 1
    ;;
  esac

  if [ -z "$PACKAGE_MANAGER" ]; then
    gum style --foreground 196 "Error: No supported package manager found!"
    exit 1
  fi

  gum style --foreground 82 "✓ Package Manager: $PACKAGE_MANAGER"
}

# Clone dotfiles
clone_dotfiles() {
  gum style --border double --padding "1 2" --border-foreground 212 "Cloning Hecate Dotfiles"

  if [ -d "$HECATEDIR" ]; then
    if gum confirm "Hecate directory already exists. Remove and re-clone?"; then
      rm -rf "$HECATEDIR"
    else
      gum style --foreground 220 "Using existing directory..."
      return
    fi
  fi

  gum style --foreground 220 "Cloning repository..."
  if ! git clone "$REPO_URL" "$HECATEDIR"; then
    gum style --foreground 196 "✗ Error cloning repository!"
    gum style --foreground 196 "Check your internet connection and try again."
    exit 1
  fi

  # Verify critical directories exist
  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "✗ Error: Config directory not found in cloned repo!"
    exit 1
  fi

  gum style --foreground 82 "✓ Dotfiles cloned successfully!"
}

# Backup config based on Hecate/config contents
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$CONFIGDIR/Hecate-backup/config-$timestamp"

  if [ -d "$HECATEDIR/config" ]; then
    local backed_up=false

    for folder in "$HECATEDIR/config"/*; do
      if [ -d "$folder" ]; then
        local folder_name=$(basename "$folder")

        # Check if config exists in user's .config
        if [ -d "$CONFIGDIR/$folder_name" ]; then
          if [ "$backed_up" = false ]; then
            mkdir -p "$backup_dir"
            backed_up=true
          fi
          gum style --foreground 220 "Backing up: $folder_name"
          cp -r "$CONFIGDIR/$folder_name" "$backup_dir/"
        fi

        # Backup shell rc files
        case "$folder_name" in
        zsh)
          if [ -f "$HOME/.zshrc" ]; then
            [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
            gum style --foreground 220 "Backing up: .zshrc"
            cp "$HOME/.zshrc" "$backup_dir/.zshrc"
          fi
          ;;
        bash)
          if [ -f "$HOME/.bashrc" ]; then
            [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
            gum style --foreground 220 "Backing up: .bashrc"
            cp "$HOME/.bashrc" "$backup_dir/.bashrc"
          fi
          ;;
        fish)
          if [ -f "$HOME/.config/fish/config.fish" ]; then
            [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
            gum style --foreground 220 "Backing up: fish config"
            mkdir -p "$backup_dir/fish"
            cp -r "$HOME/.config/fish"/* "$backup_dir/fish/"
          fi
          ;;
        esac
      fi
    done

    if [ "$backed_up" = true ]; then
      gum style --foreground 82 "✓ Backup created at: $backup_dir"
      echo "$backup_dir" >"$HOME/.config/hecate_last_backup.txt"
    else
      gum style --foreground 220 "No existing configs found to backup"
    fi
  fi
}

# Ask user preferences to customize installation
ask_preferences() {
  gum style --border double --padding "1 2" --border-foreground 212 "User Preferences"

  # Terminal preference
  USER_TERMINAL=$(gum choose --header "Select your preferred terminal:" \
    "kitty" \
    "alacritty" \
    "foot" \
    "ghostty")
  gum style --foreground 82 "✓ Terminal: $USER_TERMINAL"
  echo ""

  # Shell preference
  USER_SHELL=$(gum choose --header "Select your preferred shell:" \
    "zsh" \
    "bash" \
    "fish")
  gum style --foreground 82 "✓ Shell: $USER_SHELL"
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
    gum style --foreground 82 "✓ Browser: $USER_BROWSER_DISPLAY"
  fi
  echo ""

  # SDDM preference
  if gum confirm "Install SDDM login manager?"; then
    INSTALL_SDDM=true
    gum style --foreground 82 "✓ SDDM will be installed"
  else
    INSTALL_SDDM=false
    gum style --foreground 220 "Skipping SDDM installation"
  fi
  echo ""

  gum style --foreground 82 "This will download additional packages to your system"
  gum style --foreground 220 "Choose profile based on your needs"
  sleep 2

  while true; do
    USER_PROFILE=$(gum choose --header "Select your profile:" \
      "minimal" \
      "developer" \
      "gamer" \
      "madlad")
    gum style --foreground 82 "✓ Profile: $USER_PROFILE"
    echo ""

    if [ "$USER_PROFILE" = "madlad" ]; then
      gum style --foreground 220 "⚠️ This could take easily more than an hour or 2 to install"
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
  gum style --border double --padding "1 2" --border-foreground 212 "Installation Summary"
  gum style --foreground 220 "Terminal: $USER_TERMINAL"
  gum style --foreground 220 "Shell: $USER_SHELL"
  [ -n "$USER_BROWSER_DISPLAY" ] && gum style --foreground 220 "Browser: $USER_BROWSER_DISPLAY"
  gum style --foreground 220 "SDDM: $([ "$INSTALL_SDDM" = true ] && echo "Yes" || echo "No")"
  gum style --foreground 220 "Profile: $USER_PROFILE"
  echo ""

  if ! gum confirm "Proceed with these settings?"; then
    gum style --foreground 196 "Installation cancelled"
    exit 0
  fi
}

# Build package list based on preferences
build_package_list() {
  gum style --border double --padding "1 2" --border-foreground 212 "Building Package List"

  # Base packages - removed browser from here since we handle it separately
  INSTALL_PACKAGES+=(git wget curl unzip wl-clipboard wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar python-pywal btop base-devel cliphist jq hyprpaper inter-font ttf-jetbrains-mono-nerd noto-fonts-emoji swww hyprlock hypridle starship noto-fonts grim neovim nano)

  # Check if Hyprland is already installed
  if command -v Hyprland &>/dev/null; then
    gum style --foreground 82 "✓ Hyprland is already installed"
  else
    gum style --foreground 220 "Hyprland not found - will be installed"
    INSTALL_PACKAGES+=(cmake meson cpio pkg-config hyprland)
    HYPRLAND_NEWLY_INSTALLED=true
  fi

  # Terminal
  INSTALL_PACKAGES+=("$USER_TERMINAL")

  # Shell packages
  case "$USER_SHELL" in
  zsh)
    INSTALL_PACKAGES+=(zsh fzf bat exa fd thefuck)
    ;;
  bash)
    INSTALL_PACKAGES+=(bash fzf bat exa fd thefuck bash-completion)
    ;;
  fish)
    INSTALL_PACKAGES+=(fish fzf bat exa thefuck fisher)
    ;;
  esac

  # Browser - add to package list
  if [ -n "$USER_BROWSER_PKG" ]; then
    INSTALL_PACKAGES+=("$USER_BROWSER_PKG")
  fi

  # SDDM
  if [ "$INSTALL_SDDM" = true ]; then
    INSTALL_PACKAGES+=(sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg)
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
    gum style --foreground 220 "Adding all packages..."
    add_developer_packages
    add_gamer_packages
    ;;
  esac

  # Show package list
  gum style --foreground 220 "Total packages to install: ${#INSTALL_PACKAGES[@]}"
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
    gum style --foreground 220 "Skipping developer packages"
    return
  fi

  if echo "$dev_types" | grep -q "AI/ML"; then
    gum style --foreground 220 "Adding AI/ML packages..."
    INSTALL_PACKAGES+=(python python-pip python-numpy python-pandas python-matplotlib python-scikit-learn)
  fi

  if echo "$dev_types" | grep -q "Web Development"; then
    gum style --foreground 220 "Adding Web Development packages..."
    INSTALL_PACKAGES+=(nodejs npm yarn)
  fi

  if echo "$dev_types" | grep -q "Server/Backend"; then
    gum style --foreground 220 "Adding Server/Backend packages..."
    INSTALL_PACKAGES+=(docker docker-compose)
  fi

  if echo "$dev_types" | grep -q "Database"; then
    gum style --foreground 220 "Adding Database packages..."
    INSTALL_PACKAGES+=(postgresql sqlite)

    if gum confirm "Install MySQL/MariaDB?"; then
      INSTALL_PACKAGES+=(mariadb)
    fi

    if gum confirm "Install Redis?"; then
      INSTALL_PACKAGES+=(redis)
    fi
  fi

  if echo "$dev_types" | grep -q "Mobile Development"; then
    gum style --foreground 220 "Adding Mobile Development packages..."
    INSTALL_PACKAGES+=(android-tools)
  fi

  if echo "$dev_types" | grep -q "DevOps"; then
    gum style --foreground 220 "Adding DevOps packages..."
    INSTALL_PACKAGES+=(docker kubectl terraform ansible)
  fi

  if echo "$dev_types" | grep -q "Game Development"; then
    gum style --foreground 220 "Adding Game Development packages..."
    INSTALL_PACKAGES+=(godot blender)
  fi
}

# Add gamer packages
add_gamer_packages() {
  gum style --foreground 220 "Adding gaming packages..."

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

# Main package installation function with proper error handling
install_packages() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Packages"

  if [ ${#INSTALL_PACKAGES[@]} -eq 0 ]; then
    gum style --foreground 220 "No packages to install"
    return 0
  fi

  gum style --foreground 220 "Total packages to install: ${#INSTALL_PACKAGES[@]}"
  echo ""

  case "$PACKAGE_MANAGER" in
  paru | yay)
    gum style --foreground 220 "Installing packages with $PACKAGE_MANAGER..."

    # Try to install all packages at once, but don't exit on error
    set +e
    $PACKAGE_MANAGER -S --needed --noconfirm "${INSTALL_PACKAGES[@]}" 2>&1 | tee /tmp/hecate_install.log
    set -e

    # Check which packages actually installed
    local success_count=0
    FAILED_PACKAGES=()

    for pkg in "${INSTALL_PACKAGES[@]}"; do
      if pacman -Q "$pkg" &>/dev/null; then
        ((success_count++))
      else
        FAILED_PACKAGES+=("$pkg")
      fi
    done

    echo ""
    gum style --border double --padding "1 2" --border-foreground 212 "Installation Results"
    gum style --foreground 82 "✓ Successfully installed: $success_count/${#INSTALL_PACKAGES[@]} packages"

    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
      gum style --foreground 196 "✗ Failed packages: ${#FAILED_PACKAGES[@]}"
      for pkg in "${FAILED_PACKAGES[@]}"; do
        gum style --foreground 196 "  • $pkg"
      done
      echo ""

      # Save failed packages
      local failed_log="$HOME/hecate_failed_packages.txt"
      printf '%s\n' "${FAILED_PACKAGES[@]}" >"$failed_log"
      gum style --foreground 220 "Failed packages saved to: $failed_log"
      gum style --foreground 220 "Install them later with: $PACKAGE_MANAGER -S \$(cat $failed_log)"
      echo ""

      # Don't continue if critical packages failed
      if ! verify_critical_packages_installed; then
        gum style --foreground 196 "✗ Critical packages failed to install!"
        gum style --foreground 196 "Cannot continue without these packages."
        exit 1
      fi
    fi
    ;;

  pacman)
    # Need to install an AUR helper first
    if ! install_aur_helper; then
      gum style --foreground 196 "Failed to install AUR helper. Cannot continue."
      exit 1
    fi
    # Recursively call with new package manager
    install_packages
    return $?
    ;;

  dnf)
    set +e
    gum style --foreground 220 "Installing packages with DNF..."
    sudo dnf install -y "${INSTALL_PACKAGES[@]}"
    set -e
    gum style --foreground 82 "✓ Package installation complete!"
    ;;

  *)
    gum style --foreground 196 "✗ Unsupported package manager: $PACKAGE_MANAGER"
    exit 1
    ;;
  esac

  echo ""
}

# Install AUR helper (paru or yay)
install_aur_helper() {
  gum style --border normal --padding "0 1" --border-foreground 212 "Installing AUR Helper"
  gum style --foreground 220 "An AUR helper is required for some packages"
  echo ""

  if ! gum confirm "Install paru AUR helper now?"; then
    return 1
  fi

  gum style --foreground 220 "Installing build dependencies..."
  if ! sudo pacman -S --needed --noconfirm base-devel git; then
    gum style --foreground 196 "Failed to install build dependencies"
    return 1
  fi

  gum style --foreground 220 "Building paru from AUR..."
  local temp_dir="/tmp/paru-install-$$"
  mkdir -p "$temp_dir"

  if ! git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
    gum style --foreground 196 "Failed to clone paru repository"
    rm -rf "$temp_dir"
    return 1
  fi

  cd "$temp_dir/paru"

  if makepkg -si --noconfirm; then
    cd "$HOME"
    rm -rf "$temp_dir"
    PACKAGE_MANAGER="paru"
    gum style --foreground 82 "✓ Paru installed successfully!"
    return 0
  else
    cd "$HOME"
    rm -rf "$temp_dir"
    gum style --foreground 196 "✗ Failed to build paru"

    if gum confirm "Try installing yay instead?"; then
      if sudo pacman -S --needed --noconfirm yay; then
        PACKAGE_MANAGER="yay"
        gum style --foreground 82 "✓ Yay installed successfully!"
        return 0
      fi
    fi
    return 1
  fi
}

# Verify critical packages are installed (returns 0 if ok, 1 if critical failure)
verify_critical_packages_installed() {
  local critical_packages=("$USER_TERMINAL" "hyprland" "waybar" "rofi" "swaync" "hyprlock" "hypridle" "wallust" "starship" "wlogout" "grim" "wl-clipboard")
  local missing_critical=()

  for pkg in "${critical_packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null && ! pacman -Q "$pkg" &>/dev/null 2>&1; then
      missing_critical+=("$pkg")
    fi
  done

  if [ ${#missing_critical[@]} -gt 0 ]; then
    gum style --foreground 196 "Missing critical packages:"
    for pkg in "${missing_critical[@]}"; do
      gum style --foreground 196 "  • $pkg"
    done
    return 1
  fi

  return 0
}

# Verify critical packages after installation
verify_critical_packages() {
  clear
  gum style --border double --padding "1 2" --border-foreground 212 "Verifying Critical Packages"

  local critical_packages=("$USER_TERMINAL" "hyprland" "waybar" "rofi" "cliphist" "swaync" "hypridle" "hyprlock" "wallust" "fastfetch" "starship" "wlogout" "noto-fonts-emoji" "grim" "wl-clipboard")
  local missing_packages=()

  for pkg in "${critical_packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null && ! pacman -Q "$pkg" &>/dev/null 2>&1; then
      missing_packages+=("$pkg")
      gum style --foreground 196 "✗ Missing: $pkg"
    else
      gum style --foreground 82 "✓ Found: $pkg"
    fi
  done

  echo ""

  if [ ${#missing_packages[@]} -gt 0 ]; then
    gum style --foreground 196 "⚠ Critical packages are missing!"
    gum style --foreground 220 "The system may not function correctly."

    if gum confirm "Try to install missing critical packages now?"; then
      INSTALL_PACKAGES=("${missing_packages[@]}")
      install_packages

      # Re-verify
      if ! verify_critical_packages_installed; then
        gum style --foreground 196 "⚠ Critical packages still missing after retry"
        if ! gum confirm "Continue anyway? (Not recommended)"; then
          gum style --foreground 196 "Installation aborted"
          exit 1
        fi
      fi
    else
      if ! gum confirm "Continue without critical packages? (Not recommended)"; then
        gum style --foreground 196 "Installation aborted"
        exit 1
      fi
    fi
  else
    gum style --foreground 82 "✓ All critical packages verified!"
  fi

  echo ""
}

# Enable SDDM after installation
enable_sddm() {
  if [ "$INSTALL_SDDM" != true ]; then
    return
  fi

  # Verify SDDM actually installed
  if ! pacman -Q sddm &>/dev/null; then
    gum style --foreground 196 "✗ SDDM was not installed successfully"
    gum style --foreground 220 "Skipping SDDM configuration"
    return
  fi

  gum style --border double --padding "1 2" --border-foreground 212 "Enabling SDDM"

  local current_dm=$(systemctl is-enabled display-manager.service 2>/dev/null || echo "none")

  if [ "$current_dm" != "none" ] && [ "$current_dm" != "sddm.service" ]; then
    gum style --foreground 220 "Detected existing display manager: $current_dm"

    if gum confirm "Disable $current_dm and enable SDDM instead?"; then
      gum style --foreground 220 "Disabling $current_dm..."
      sudo systemctl disable display-manager.service 2>/dev/null || true
      sudo systemctl disable "$current_dm" 2>/dev/null || true

      gum style --foreground 220 "Enabling SDDM..."
      if sudo systemctl enable sddm && sudo systemctl set-default graphical.target; then
        gum style --foreground 82 "✓ SDDM enabled successfully!"
      else
        gum style --foreground 196 "✗ Failed to enable SDDM"
        gum style --foreground 220 "You may need to enable it manually"
      fi
    else
      gum style --foreground 220 "Keeping existing display manager"
    fi
  else
    if sudo systemctl enable sddm && sudo systemctl set-default graphical.target; then
      gum style --foreground 82 "✓ SDDM enabled successfully!"
    else
      gum style --foreground 196 "✗ Failed to enable SDDM"
    fi
  fi
}

# Setup shell plugins
setup_shell_plugins() {
  gum style --border double --padding "1 2" --border-foreground 212 "Setting Up Shell Plugins"

  case "$USER_SHELL" in
  zsh)
    setup_zsh_plugins
    ;;
  fish)
    setup_fish_plugins
    ;;
  bash)
    setup_bash_plugins
    ;;
  esac
}

# Setup Zsh plugins
setup_zsh_plugins() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    gum style --foreground 220 "Installing Oh My Zsh..."
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
      gum style --foreground 196 "Failed to install Oh My Zsh"
      return 1
    fi
  fi

  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    gum style --foreground 220 "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
  fi

  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    gum style --foreground 220 "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
  fi

  gum style --foreground 82 "✓ Zsh plugins installed!"
}

# Setup Fish plugins
setup_fish_plugins() {
  if ! fish -c "type -q fisher" 2>/dev/null; then
    gum style --foreground 220 "Installing Fisher..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true
  fi

  gum style --foreground 220 "Installing Fish plugins..."
  fish -c "
    fisher install jethrokuan/z 2>/dev/null || true
    fisher install PatrickF1/fzf.fish 2>/dev/null || true
    fisher install jorgebucaran/nvm.fish 2>/dev/null || true
  " 2>/dev/null || true

  gum style --foreground 82 "✓ Fish plugins installed!"
}

setup_bash_plugins() {
  gum style --foreground 220 "Setting up Bash with Starship..."

  if [ ! -f "$HOME/.fzf.bash" ]; then
    gum style --foreground 220 "Setting up FZF for Bash..."

    if [ -f /usr/share/fzf/key-bindings.bash ]; then
      cat >"$HOME/.fzf.bash" <<'FZFEOF'
# FZF Bash Integration
[ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
[ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
FZFEOF
      gum style --foreground 82 "✓ FZF integration created!"
    else
      gum style --foreground 220 "FZF integration will be available after FZF is installed"
    fi
  else
    gum style --foreground 82 "✓ FZF already configured"
  fi

  gum style --foreground 82 "✓ Bash setup complete!"
}

# Move config files
move_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Configuration Files"

  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "Error: Config directory not found!"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  for folder in "$HECATEDIR/config"/*; do
    if [ -d "$folder" ]; then
      local folder_name=$(basename "$folder")

      # Only install selected terminal config
      case "$folder_name" in
      alacritty | foot | ghostty | kitty)
        if [ "$folder_name" = "$USER_TERMINAL" ]; then
          gum style --foreground 82 "Installing $folder_name config..."
          rm -rf "$CONFIGDIR/$folder_name"
          cp -r "$folder" "$CONFIGDIR/"
        fi
        ;;
      zsh)
        if [ "$USER_SHELL" = "zsh" ] && [ -f "$folder/.zshrc" ]; then
          gum style --foreground 82 "Installing .zshrc..."
          cp "$folder/.zshrc" "$HOME/.zshrc"
        fi
        ;;
      bash)
        if [ "$USER_SHELL" = "bash" ] && [ -f "$folder/.bashrc" ]; then
          gum style --foreground 82 "Installing .bashrc..."
          cp "$folder/.bashrc" "$HOME/.bashrc"
        fi
        ;;
      fish)
        if [ "$USER_SHELL" = "fish" ]; then
          gum style --foreground 82 "Installing fish config..."
          mkdir -p "$CONFIGDIR/fish"
          cp -r "$folder/"* "$CONFIGDIR/fish/"
        fi
        ;;
      *)
        # Install other configs (hyprland, waybar, etc.)
        gum style --foreground 82 "Installing $folder_name..."
        rm -rf "$CONFIGDIR/$folder_name"
        cp -r "$folder" "$CONFIGDIR/"
        ;;
      esac
    fi
  done

  # Install apps from apps directory
  if [ -d "$HECATEAPPSDIR/Pulse/build/bin" ]; then
    gum style --foreground 82 "Installing Pulse..."
    if [ -f "$HECATEAPPSDIR/Pulse/build/bin/Pulse" ]; then
      cp "$HECATEAPPSDIR/Pulse/build/bin/Pulse" "$HOME/.local/bin/Pulse"
      chmod +x "$HOME/.local/bin/Pulse"
      gum style --foreground 82 "✓ Pulse installed to ~/.local/bin/Pulse"
    else
      gum style --foreground 220 "⚠ Pulse binary not found at expected location"
    fi
  else
    gum style --foreground 220 "⚠ Pulse build directory not found"
  fi

  # Install hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Installing hecate CLI tool..."
    cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    gum style --foreground 82 "✓ hecate command installed to ~/.local/bin/hecate"
  else
    gum style --foreground 220 "⚠ hecate.sh not found in config directory"
  fi

  # Install Starship config
  if [ -f "$HECATEDIR/config/starship/starship.toml" ]; then
    gum style --foreground 82 "Installing Starship config..."
    cp "$HECATEDIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
    gum style --foreground 82 "✓ Starship config installed"
  else
    gum style --foreground 220 "⚠ Starship config not found"
  fi

  # Install Hyprland plugin installer if it exists
  #   if [ -f "$HECATEDIR/config/install-hyprland-plugins.sh" ]; then
  #     gum style --foreground 82 "Installing Hyprland plugin installer..."
  #     cp "$HECATEDIR/config/install-hyprland-plugins.sh" "$HOME/.local/bin/install-hyprland-plugins"
  #     chmod +x "$HOME/.local/bin/install-hyprland-plugins"
  #     gum style --foreground 82 "✓ Plugin installer: install-hyprland-plugins"
  #   fi

  gum style --foreground 82 "✓ Configuration files installed successfully!"
}

# Build preferred app keybind
build_preferd_app_keybind() {
  gum style --border double --padding "1 2" --border-foreground 212 "Configuring App Keybinds"

  mkdir -p ~/.config/hypr/configs/UserConfigs

  cat >~/.config/hypr/configs/UserConfigs/app-names.conf <<EOF
# Set your default applications here
\$term = $USER_TERMINAL
\$browser = $USER_BROWSER_EXEC
EOF

  gum style --foreground 82 "✓ App keybinds configured!"
  gum style --foreground 220 "Terminal: $USER_TERMINAL"
  [ -n "$USER_BROWSER_DISPLAY" ] && gum style --foreground 220 "Browser: $USER_BROWSER_DISPLAY"
}

# Create Hecate configuration file
create_hecate_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Creating Hecate Configuration"

  local config_dir="$HOME/.config/hecate"
  local config_file="$config_dir/hecate.toml"
  local version="1.0.0"
  local install_date=$(date +%Y-%m-%d)

  # Try to get version from remote
  if command -v curl &>/dev/null; then
    local remote_version=$(curl -s "https://raw.githubusercontent.com/Aelune/Hecate/main/version.txt" 2>/dev/null || echo "")
    [ -n "$remote_version" ] && version="$remote_version"
  fi

  mkdir -p "$config_dir"

  # Ask about theme mode
  local theme_mode=$(gum choose --header "Select theme mode:" \
    "dynamic - Auto-update colors from wallpaper" \
    "static - Keep colors unchanged")

  if echo "$theme_mode" | grep -q "dynamic"; then
    theme_mode="dynamic"
  else
    theme_mode="static"
  fi

  # Create hecate.toml
  cat >"$config_file" <<EOF
# Hecate Dotfiles Configuration
# This file manages your Hecate installation settings

[metadata]
version = "$version"
install_date = "$install_date"
last_update = "$install_date"
repo_url = "$REPO_URL"

[theme]
# Theme mode: "dynamic" or "static"
# dynamic: Automatically updates system colors when wallpaper changes
# static: Keeps colors unchanged regardless of wallpaper
mode = "$theme_mode"

[preferences]
term = "$USER_TERMINAL"
browser = "$USER_BROWSER_EXEC"
shell = "$USER_SHELL"
profile = "$USER_PROFILE"
EOF

  gum style --foreground 82 "✓ Hecate config created at: $config_file"
  gum style --foreground 220 "Theme mode: $theme_mode"
}

# Setup Waybar - verify symlinks exist in waybar folder
setup_Waybar() {
  gum style --foreground 220 "Configuring waybar..."

  # Verify waybar config directory exists
  if [ ! -d "$HOME/.config/waybar" ]; then
    gum style --foreground 196 "✗ Waybar config directory not found!"
    return 1
  fi

  # Verify source files exist before creating symlinks
  if [ ! -f "$HOME/.config/waybar/configs/top" ]; then
    gum style --foreground 196 "✗ Waybar config source not found: configs/top"
    return 1
  fi

  if [ ! -f "$HOME/.config/waybar/style/default.css" ]; then
    gum style --foreground 196 "✗ Waybar style source not found: style/default.css"
    return 1
  fi

  # Create symlinks
  ln -sf "$HOME/.config/waybar/configs/top" "$HOME/.config/waybar/config"
  ln -sf "$HOME/.config/waybar/style/default.css" "$HOME/.config/waybar/style.css"

  gum style --foreground 82 "✓ Waybar configured!"
}

# Set default shell
set_default_shell() {
  local current_shell=$(basename "$SHELL")

  if [ "$current_shell" = "$USER_SHELL" ]; then
    gum style --foreground 82 "✓ $USER_SHELL is already your default shell"
    return
  fi

  # Verify the shell is actually installed
  if ! command -v "$USER_SHELL" &>/dev/null; then
    gum style --foreground 196 "✗ $USER_SHELL is not installed!"
    gum style --foreground 220 "Cannot set as default shell"
    return 1
  fi

  if gum confirm "Set $USER_SHELL as default shell?"; then
    local shell_path=$(which "$USER_SHELL")

    if [ -z "$shell_path" ]; then
      gum style --foreground 196 "Error: $USER_SHELL not found in PATH"
      return 1
    fi

    # Check if shell is in /etc/shells
    if ! grep -q "^${shell_path}$" /etc/shells; then
      gum style --foreground 220 "Adding $shell_path to /etc/shells..."
      echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
    fi

    gum style --foreground 220 "Changing default shell to $USER_SHELL..."

    if sudo chsh -s "$shell_path" "$USER"; then
      gum style --foreground 82 "✓ $USER_SHELL set as default shell!"
      gum style --foreground 220 "Note: Log out and log back in for this to take effect"
    else
      gum style --foreground 196 "✗ Failed to change shell"
      gum style --foreground 220 "Try manually: chsh -s $shell_path"
      return 1
    fi
  fi
}

# Configure SDDM theme at the end
configure_sddm_theme() {
  if [ "$INSTALL_SDDM" != true ]; then
    return
  fi

  gum style --border double --padding "1 2" --border-foreground 212 "SDDM Theme Configuration"

  if gum confirm "Install SDDM Astronaut theme?"; then
    gum style --foreground 220 "Installing SDDM theme..."

    local theme_script="/tmp/sddm-astronaut-setup.sh"
    if curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh -o "$theme_script"; then
      chmod +x "$theme_script"
      if bash "$theme_script"; then
        gum style --foreground 82 "✓ SDDM theme installed!"
      else
        gum style --foreground 196 "✗ SDDM theme installation failed"
      fi
      rm -f "$theme_script"
    else
      gum style --foreground 196 "✗ Failed to download SDDM theme installer"
    fi
  else
    gum style --foreground 220 "Skipping SDDM theme installation"
  fi
}

# Main function
main() {
  # Parse arguments
  case "${1:-}" in
  --help | -h)
    clear
    echo -e "${YELLOW}Prerequisites.${NC}"
    echo "  • gum - Interactive CLI tool"
    echo "    Install: sudo pacman -S gum"
    echo ""
    echo "  • paru (recommended) - AUR helper"
    echo "    Install: https://github.com/Morganamilo/paru#installation"
    echo ""
    echo -e "${YELLOW}Usage:"
    echo "  ./install.sh          Run the installer"
    echo "  ./install.sh --help   Show this message"
    echo "  ./install.sh --dry-run   ...why though?"
    echo ""
    echo "That's it. Now go install gum and paru if you haven't already."
    exit 0
    ;;
  --dry-run)
    echo -e "${BLUE}The \"I want to feel productive without doing anything mode\"${NC}"
    echo -e "${YELLOW}Simulating installation...${NC}"
    sleep 1
    echo ""
    echo -e "${GREEN}✓ System check: Passed (probably)${NC}"
    echo -e "${GREEN}✓ Packages: Would install ~47 packages${NC}"
    echo -e "${GREEN}✓ Configs: Would copy lots of dotfiles${NC}"
    echo ""
    echo -e "${YELLOW}Congratulations! You've successfully done... nothing.${NC}"
    echo -e "${ORANGE}Run without --dry-run when you're ready to actually install.${NC}"
    echo ""
    echo -e "${RED}Pro tip: Dry runs don't make your setup any cooler.${NC}"
    exit 0
    ;;
  -*)
    echo -e "${RED}Unknown option: $1${NC}"
    echo -e "${BLUE}Try: ./install.sh --help${NC}"
    exit 1
    ;;
  esac

  clear

  # Check for gum first
  check_gum

  # Welcome banner
  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "2 4" \
    'HECATE DOTFILES' 'Hyprland Configuration Installer' ''

  # Confirm installation
  if ! gum confirm "Do you want to proceed with Hecate installation?"; then
    gum style --foreground 220 "Installation cancelled"
    exit 0
  fi

  gum style --foreground 220 "Starting installation process..."
  sleep 1

  # System checks
  check_OS
  get_packageManager

  # Clone repo early to check configs
  clone_dotfiles

  # Backup existing configs
  backup_config

  # Ask all user preferences
  ask_preferences

  # Build complete package list
  build_package_list

  # Install all packages at once
  install_packages

  # Verify critical packages installed successfully
  verify_critical_packages

  # Enable SDDM if it was installed
  enable_sddm

  # Setup shell plugins
  setup_shell_plugins

  # Install configuration files
  move_config

  # Setup Waybar symlinks
  if ! setup_Waybar; then
    gum style --foreground 220 "⚠ Waybar setup had issues, but continuing..."
  fi

  build_preferd_app_keybind
  create_hecate_config

  # Set default shell
  set_default_shell

  # Configure SDDM theme
  configure_sddm_theme

  # Completion message
  echo ""
  gum style \
    --foreground 82 \
    --border-foreground 82 \
    --border double \
    --align left \
    --width 70 \
    --margin "1 2" \
    --padding "2 4" \
    '✓ Installation Complete!'

  echo ""

  if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    gum style --foreground 220 "Note: Some packages failed to install"
    gum style --foreground 220 "Check ~/hecate_failed_packages.txt for details"
    echo ""
  else
    gum style --foreground 85 '(surprisingly, nothing exploded)'
    echo ""
  fi

  gum style --foreground 82 \
    'Post-Install TODO:' \
    '1. Reboot (or live dangerously and just re-login)' \
    '2. Log into Hyprland' \
    '3. Run: install-hyprland-plugins' \
    '4. Take screenshot' \
    '5. Post to r/unixporn'
  echo ""
  gum style --foreground 92 "May your wallpapers be dynamic and your RAM usage low."
  echo ""
  sleep 3
  if gum confirm "Reboot now?"; then
    gum style --foreground 82 "Rebooting..."
    sleep 2
    sudo reboot
  else
    gum style --foreground 220 "Remember to reboot to apply all changes!"
  fi

}

# Run main function with arguments
main "$@"

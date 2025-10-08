#!/bin/bash

# Hyprland Dotfiles Installer with Gum
# Author: Hecate Dotfiles
# Description: Interactive installer for Hyprland configuration

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Global Variables
HECATEDIR="$HOME/Hecate"
CONFIGDIR="$HOME/.config"
REPO_URL="https://github.com/Aelune/Hecate.git"
OS=""
PACKAGE_MANAGER=""
HYPRLAND_NEWLY_INSTALLED=false

# User preferences
USER_TERMINAL=""
USER_SHELL=""
USER_BROWSER=""
USER_BROWSER_DISPLAY=""
USER_PROFILE=""
INSTALL_SDDM=false
INSTALL_PACKAGES=()

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
      gum style --foreground 220 "Supported: Arch Linux, Manjaro, EndeavourOS"
      gum style --foreground 220 "Partially Supported: Fedora, it runs on hopes and prayers"
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
    gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
    gum style --foreground 220 "Proceed at your own risk."

    if ! gum confirm "Do you want to continue on Fedora?"; then
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
  git clone "$REPO_URL" "$HECATEDIR"

  if [ $? -eq 0 ]; then
    gum style --foreground 82 "✓ Dotfiles cloned successfully!"
  else
    gum style --foreground 196 "✗ Error cloning repository!"
    exit 1
  fi
}

# Backup config based on Hecate/config contents
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$CONFIGDIR/Hecate-backup-$timestamp"

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
        esac
      fi
    done

    if [ "$backed_up" = true ]; then
      gum style --foreground 82 "✓ Backup created at: $backup_dir"
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
  # Map display names to package names, executable names, and display names
  case "$browser_choice" in
  "Firefox")
    USER_BROWSER_PKG="firefox"     # Package to install
    USER_BROWSER_EXEC="firefox"    # Command to run
    USER_BROWSER_DISPLAY="Firefox" # Display name
    ;;
  "Brave")
    USER_BROWSER_PKG="brave-bin" # Package to install (AUR)
    USER_BROWSER_EXEC="brave"    # Command to run
    USER_BROWSER_DISPLAY="Brave" # Display name
    ;;
  "Chromium")
    USER_BROWSER_PKG="chromium"     # Package to install
    USER_BROWSER_EXEC="chromium"    # Command to run
    USER_BROWSER_DISPLAY="Chromium" # Display name
    ;;
  "Google Chrome")
    USER_BROWSER_PKG="google-chrome"         # Package to install (AUR)
    USER_BROWSER_EXEC="google-chrome-stable" # Command to run
    USER_BROWSER_DISPLAY="Google Chrome"     # Display name
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

  gum style --foreground 82 "This will download additional packages to your system select based on your work"
  gum style --foreground 82 "This was designed for newly installed setup, by chosing profile you can break dependencies used by other softwares"
  sleep 2
  while true; do
    # User profile
    USER_PROFILE=$(gum choose --header "Select your profile:" \
      "minimal" \
      "developer" \
      "gamer" \
      "madlad")
    gum style --foreground 82 "✓ Profile: $USER_PROFILE"
    echo ""
    if [ $USER_PROFILE = "madlad"]; then
      gum style --foreground 82 "⚠️ This could take easily more than an hour or 2 to install depending upon netwrok speed and cpu power"
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

  # Base packages
  INSTALL_PACKAGES+=(git wget curl unzip wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar python-pywal btop base-devel cliphist jq hyprpaper inter-fonts ttf-jetbrains-mono-nerd noto-fonts-emoji swww hyprlock hypridle starship noto-fonts grim wl-clipboard)

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

  # Browser
  [ -n "$USER_BROWSER_PKG" ] && INSTALL_PACKAGES+=("$USER_BROWSER_PKG")

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
    gum style --foreground 220 "Adding all the things..."
    gum style --foreground 220 "this is going to take a long time so sit back relax and enjoy..."
    add_developer_packages
    add_gamer_packages
    ;;
  esac

  # Show package list
  gum style --foreground 220 "Packages to install:"
  printf '%s\n' "${INSTALL_PACKAGES[@]}" | gum format
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

  # AI/ML packages
  if echo "$dev_types" | grep -q "AI/ML"; then
    gum style --foreground 220 "Adding AI/ML packages..."
    INSTALL_PACKAGES+=(python python-pip python-numpy python-pandas python-matplotlib python-scikit-learn)
  fi

  # Web Development packages
  if echo "$dev_types" | grep -q "Web Development"; then
    gum style --foreground 220 "Adding Web Development packages..."
    INSTALL_PACKAGES+=(nodejs npm yarn)
  fi

  # Server/Backend packages
  if echo "$dev_types" | grep -q "Server/Backend"; then
    gum style --foreground 220 "Adding Server/Backend packages..."
    INSTALL_PACKAGES+=(docker docker-compose)
  fi

  # Database packages
  if echo "$dev_types" | grep -q "Database"; then
    gum style --foreground 220 "Adding Database packages..."
    INSTALL_PACKAGES+=(postgresql sqlite)

    # Ask about MySQL separately as it's larger
    if gum confirm "Install MySQL/MariaDB?"; then
      INSTALL_PACKAGES+=(mariadb)
    fi

    if gum confirm "Install Redis?"; then
      INSTALL_PACKAGES+=(redis)
    fi
  fi

  # Mobile Development packages
  if echo "$dev_types" | grep -q "Mobile Development"; then
    gum style --foreground 220 "Adding Mobile Development packages..."
    INSTALL_PACKAGES+=(android-tools)
  fi

  # DevOps packages
  if echo "$dev_types" | grep -q "DevOps"; then
    gum style --foreground 220 "Adding DevOps packages..."
    INSTALL_PACKAGES+=(docker kubectl terraform ansible)
  fi

  # Game Development packages
  if echo "$dev_types" | grep -q "Game Development"; then
    gum style --foreground 220 "Adding Game Development packages..."
    INSTALL_PACKAGES+=(godot blender)
  fi
}

# Add gamer packages
add_gamer_packages() {
  gum style --foreground 220 "Adding gaming packages..."

  # Core gaming packages
  INSTALL_PACKAGES+=(steam lutris wine-staging winetricks gamemode lib32-gamemode mangohud lib32-mangohud)

  # Discord
  if gum confirm "Install Discord?"; then
    INSTALL_PACKAGES+=(discord)
  fi

  # Emulators
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
      echo "$emulators" | grep -q "RPCS3" && INSTALL_PACKAGES+=(rpcs3-git)
    fi
  fi

  # Proton-GE
  if gum confirm "Install ProtonUp-Qt (for managing Proton-GE)?"; then
    INSTALL_PACKAGES+=(protonup-qt)
  fi
}

# Install user's preferred browser
install_user_browser() {
  if [ -n "$USER_BROWSER_PKG" ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Installing Browser"
    gum style --foreground 220 "Installing $USER_BROWSER_DISPLAY..."

    local retries=3
    local success=false

    for ((i = 1; i <= retries; i++)); do
      # Check if it's an AUR package
      case "$USER_BROWSER_PKG" in
      brave-bin | google-chrome)
        # Use AUR helper
        if command -v paru &>/dev/null; then
          gum style --foreground 220 "Using paru (attempt $i/$retries)..."
          if paru -S --needed --noconfirm "$USER_BROWSER_PKG"; then
            success=true
            break
          fi
        elif command -v yay &>/dev/null; then
          gum style --foreground 220 "Using yay (attempt $i/$retries)..."
          if yay -S --needed --noconfirm "$USER_BROWSER_PKG"; then
            success=true
            break
          fi
        else
          gum style --foreground 196 "Error: No AUR helper found! Install paru or yay first."
          return 1
        fi
        ;;
      *)
        # Regular pacman package
        gum style --foreground 220 "Using pacman (attempt $i/$retries)..."
        if sudo pacman -S --needed --noconfirm "$USER_BROWSER_PKG"; then
          success=true
          break
        fi
        ;;
      esac

      if [ $i -lt $retries ]; then
        gum style --foreground 220 "Retrying in 3 seconds..."
        sleep 3
      fi
    done

    if [ "$success" = true ]; then
      gum style --foreground 82 "✓ $USER_BROWSER_DISPLAY installed successfully!"
      echo ""
      return 0
    else
      gum style --foreground 196 "✗ Failed to install $USER_BROWSER_DISPLAY after $retries attempts"
      if gum confirm "Continue without browser installation?"; then
        gum style --foreground 220 "Continuing without browser..."
        echo ""
        return 0
      else
        gum style --foreground 196 "Installation cancelled"
        exit 1
      fi
    fi
  else
    gum style --foreground 220 "Skipping browser installation (user choice)"
    echo ""
  fi
}

# Check if a package is from official repos
is_official_package() {
  local pkg="$1"
  pacman -Si "$pkg" &>/dev/null
}

# Install a single package with retry logic
install_single_package() {
  local pkg="$1"
  local max_retries=3
  local success=false

  for ((i = 1; i <= max_retries; i++)); do
    gum style --foreground 220 "  → $pkg (attempt $i/$max_retries)..."

    if is_official_package "$pkg"; then
      # Official repo package
      if sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
        success=true
        break
      fi
    else
      # AUR package
      if $PACKAGE_MANAGER -S --needed --noconfirm "$pkg" 2>/dev/null; then
        success=true
        break
      fi
    fi

    if [ $i -lt $max_retries ]; then
      gum style --foreground 220 "    Retrying in 2 seconds..."
      sleep 2
    fi
  done

  if [ "$success" = true ]; then
    gum style --foreground 82 "    ✓ $pkg installed"
    return 0
  else
    gum style --foreground 196 "    ✗ Failed: $pkg"
    return 1
  fi
}

# Main package installation function
install_packages() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Packages"

  # Ensure package list is not empty
  if [ ${#INSTALL_PACKAGES[@]} -eq 0 ]; then
    gum style --foreground 220 "No packages to install"
    echo ""
    return 0
  fi

  gum style --foreground 220 "Total packages to install: ${#INSTALL_PACKAGES[@]}"
  echo ""

  case "$PACKAGE_MANAGER" in
  paru | yay)
    # Categorize packages
    local official_pkgs=()
    local aur_pkgs=()
    local failed_pkgs=()

    gum style --foreground 220 "Categorizing packages..."
    gum spin --spinner dot --title "Checking package sources..." -- sleep 1

    for pkg in "${INSTALL_PACKAGES[@]}"; do
      if is_official_package "$pkg"; then
        official_pkgs+=("$pkg")
      else
        aur_pkgs+=("$pkg")
      fi
    done

    echo ""
    gum style --foreground 212 "Package Summary:"
    gum style --foreground 220 "  Official repo: ${#official_pkgs[@]} packages"
    gum style --foreground 220 "  AUR: ${#aur_pkgs[@]} packages"
    echo ""

    # Install official packages first (batch install for speed)
    if [ ${#official_pkgs[@]} -gt 0 ]; then
      gum style --border normal --padding "0 1" --border-foreground 212 "Installing Official Repository Packages"

      if sudo pacman -S --needed --noconfirm "${official_pkgs[@]}" 2>&1 | tee /tmp/pacman_install.log; then
        gum style --foreground 82 "✓ Official packages installed"
      else
        gum style --foreground 196 "⚠ Some official packages failed"
        # Parse failed packages from log
        while IFS= read -r pkg; do
          if ! pacman -Q "$pkg" &>/dev/null; then
            failed_pkgs+=("$pkg")
          fi
        done < <(printf '%s\n' "${official_pkgs[@]}")
      fi
      echo ""
    fi

    # Install AUR packages one by one
    if [ ${#aur_pkgs[@]} -gt 0 ]; then
      gum style --border normal --padding "0 1" --border-foreground 212 "Installing AUR Packages"

      local installed_count=0
      for pkg in "${aur_pkgs[@]}"; do
        if install_single_package "$pkg"; then
          ((installed_count++))
        else
          failed_pkgs+=("$pkg")
        fi
      done

      echo ""
      gum style --foreground 82 "✓ AUR packages: $installed_count/${#aur_pkgs[@]} installed"
      echo ""
    fi

    # Summary
    gum style --border double --padding "1 2" --border-foreground 212 "Installation Summary"
    local total_installed=$((${#INSTALL_PACKAGES[@]} - ${#failed_pkgs[@]}))
    gum style --foreground 82 "✓ Successfully installed: $total_installed/${#INSTALL_PACKAGES[@]} packages"

    if [ ${#failed_pkgs[@]} -gt 0 ]; then
      gum style --foreground 196 "✗ Failed packages (${#failed_pkgs[@]}):"
      for pkg in "${failed_pkgs[@]}"; do
        gum style --foreground 196 "  • $pkg"
      done
      echo ""

      if gum confirm "Save failed packages list for manual installation?"; then
        local failed_log="$HOME/hecate_failed_packages.txt"
        printf '%s\n' "${failed_pkgs[@]}" >"$failed_log"
        gum style --foreground 220 "Failed packages saved to: $failed_log"
        gum style --foreground 220 "You can install them later with:"
        gum style --foreground 220 "  $PACKAGE_MANAGER -S \$(cat $failed_log)"
      fi
    fi
    ;;

  pacman)
    # Install paru first if needed
    if ! command -v paru &>/dev/null; then
      gum style --border normal --padding "0 1" --border-foreground 212 "Installing Paru AUR Helper"
      gum style --foreground 220 "Paru is required for AUR package support"
      echo ""

      if gum confirm "Install paru now?"; then
        # Install dependencies
        gum style --foreground 220 "Installing build dependencies..."
        sudo pacman -S --needed --noconfirm base-devel git

        # Clone and build paru
        gum style --foreground 220 "Building paru from AUR..."
        local temp_dir="/tmp/paru-install-$$"
        mkdir -p "$temp_dir"
        cd "$temp_dir"

        git clone https://aur.archlinux.org/paru.git
        cd paru

        if makepkg -si --noconfirm; then
          gum style --foreground 82 "✓ Paru installed successfully!"
          PACKAGE_MANAGER="paru"
          cd "$HOME"
          rm -rf "$temp_dir"
          echo ""

          # Recursively call with paru
          install_packages
          return $?
        else
          gum style --foreground 196 "✗ Failed to install paru"
          cd "$HOME"
          rm -rf "$temp_dir"

          if gum confirm "Try installing yay instead?"; then
            sudo pacman -S --needed --noconfirm yay
            if command -v yay &>/dev/null; then
              PACKAGE_MANAGER="yay"
              install_packages
              return $?
            fi
          fi

          gum style --foreground 196 "Cannot proceed without an AUR helper"
          exit 1
        fi
      else
        gum style --foreground 196 "Cannot proceed without an AUR helper"
        exit 1
      fi
    fi
    ;;

  dnf)
    gum style --foreground 220 "Installing packages with DNF..."
    if sudo dnf install -y "${INSTALL_PACKAGES[@]}"; then
      gum style --foreground 82 "✓ Package installation complete!"
    else
      gum style --foreground 196 "⚠ Some packages failed to install"
    fi
    ;;

  *)
    gum style --foreground 196 "✗ Unsupported package manager: $PACKAGE_MANAGER"
    return 1
    ;;
  esac

  echo ""
}

# Wrapper function to install everything
install_all_packages() {
  # First install system packages
  install_packages

  echo ""

  # Then install user's browser
  install_user_browser

  echo ""
  gum style --foreground 82 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  gum style --foreground 82 "  All package installations complete!"
  gum style --foreground 82 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Verify critical packages are installed
verify_critical_packages() {
  clear
  local critical_packages=("$USER_TERMINAL" "hyprland" "waybar" "rofi" "cliphist" "swaync" "hypridle" "hyprlock" "waybar" "wallust" "fastfetch" "starship" "wlogout" "notos-fonts-emoji" "rofi" "rofi-emoji" "grim" "wl-clipboard")
  local missing_packages=()

  gum style --border double --padding "1 2" --border-foreground 212 "Verifying Critical Packages"

  for pkg in "${critical_packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null && ! pacman -Q "$pkg" &>/dev/null; then
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
    else
      gum style --foreground 220 "Continuing anyway... (not recommended)"
    fi
  else
    gum style --foreground 82 "✓ All critical packages verified!"
  fi

  echo ""
}

# Enable SDDM after installation
enable_sddm() {
  if [ "$INSTALL_SDDM" = true ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Enabling SDDM"

    sudo systemctl enable sddm
    sudo systemctl set-default graphical.target

    gum style --foreground 82 "✓ SDDM enabled!"
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
  # Install Oh My Zsh
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    gum style --foreground 220 "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Install Powerlevel10k
  #   if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  #     gum style --foreground 220 "Installing Powerlevel10k..."
  #     git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  #   fi

  # Install plugins
  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    gum style --foreground 220 "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  fi

  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    gum style --foreground 220 "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  fi

  gum style --foreground 82 "✓ Zsh plugins installed!"
}

# Setup Fish plugins
setup_fish_plugins() {
  # Install fisher
  if ! fish -c "type -q fisher" 2>/dev/null; then
    gum style --foreground 220 "Installing Fisher..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  fi

  # Install useful Fish plugins
  gum style --foreground 220 "Installing Fish plugins..."
  fish -c "
        fisher install jethrokuan/z 2>/dev/null
        fisher install PatrickF1/fzf.fish 2>/dev/null
        fisher install jorgebucaran/nvm.fish 2>/dev/null
    " || true

  gum style --foreground 82 "✓ Fish plugins and Starship installed!"
}

setup_bash_plugins() {
  gum style --foreground 220 "Setting up Bash with Starship..."

  # Setup bash-completion if not already installed
  if ! [ -f /usr/share/bash-completion/bash_completion ] && ! [ -f /etc/bash_completion ]; then
    gum style --foreground 220 "bash-completion will be installed via package manager..."
  else
    gum style --foreground 82 "✓ bash-completion already installed"
  fi

  # Setup FZF for Bash (this creates ~/.fzf.bash)
  if [ ! -f "$HOME/.fzf.bash" ]; then
    gum style --foreground 220 "Setting up FZF for Bash..."

    # Check if fzf package includes the bash integration
    if [ -f /usr/share/fzf/key-bindings.bash ]; then
      # Create fzf.bash file that sources system fzf files
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
  gum style --foreground 220 "Note: Restart your terminal or run 'source ~/.bashrc' to apply changes"
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

  # Install hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Installing hecate CLI tool..."
    cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    gum style --foreground 82 "✓ hecate command installed to ~/.local/bin/hecate"
  fi

  if [ -f "$HECATEDIR/config/starship/starship.toml" ]; then
    gum style --foreground 82 "Installing Starship config..."
    mkdir -p "$HOME/.config"
    cp "$HECATEDIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
    gum style --foreground 82 "✓ Starship Config installed"
  fi

  # Install Hyprland plugin installer
  if [ -f "$HECATEDIR/config/install-hyprland-plugins.sh" ]; then
    gum style --foreground 82 "Installing Hyprland plugin installer..."
    cp "$HECATEDIR/config/install-hyprland-plugins.sh" "$HOME/.local/bin/install-hyprland-plugins"
    chmod +x "$HOME/.local/bin/install-hyprland-plugins"
    gum style --foreground 82 "✓ Plugin installer available: install-hyprland-plugins"
  fi

  gum style --foreground 220 "  Run 'hecate' or 'install-hyprland-plugins' from anywhere!"
  gum style --foreground 82 "✓ Configuration files installed successfully!"
}

# Build preferred app keybind
build_preferd_app_keybind() {
  gum style --border double --padding "1 2" --border-foreground 212 "Configuring App Keybinds"

  mkdir -p ~/.config/hypr/configs/UserConfigs

  # Use the display name if available, otherwise use package name
  local browser_name="${USER_BROWSER_DISPLAY:-$USER_BROWSER}"

  cat >~/.config/hypr/configs/UserConfigs/app-names.conf <<EOF
# Set your default applications here
\$term = $USER_TERMINAL
\$browser = $USER_BROWSER_EXEC
EOF

  gum style --foreground 82 "✓ App keybinds configured!"
  gum style --foreground 220 "Terminal: $USER_TERMINAL"
  [ -n "$browser_name" ] && gum style --foreground 220 "Browser: $browser_name"
}

# Create Hecate configuration file
create_hecate_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Creating Hecate Configuration"

  local config_dir="$HOME/.config/hecate"
  local config_file="$config_dir/hecate.toml"
  local version="0.3.6 blind owl"
  local install_date=$(date +%Y-%m-%d)

  # Create config directory
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
EOF

  gum style --foreground 82 "✓ Hecate config created at: $config_file"
  gum style --foreground 220 "Theme mode: $theme_mode"
}

# Setup Waybar
setup_Waybar() {
  gum style --foreground 220 "Configuring waybar..."
  ln -sf $HOME/.config/waybar/configs/top $HOME/.config/waybar/config
  ln -sf $HOME/.config/waybar/style/default.css $HOME/.config/waybar/style.css
  gum style --foreground 82 "✓ Waybar configured!"
}

# Set default shell
set_default_shell() {
  local current_shell=$(basename "$SHELL")

  if [ "$current_shell" = "$USER_SHELL" ]; then
    gum style --foreground 82 "✓ $USER_SHELL is already your default shell"
    return
  fi

  if gum confirm "Set $USER_SHELL as default shell?"; then
    local shell_path=$(which "$USER_SHELL")

    if [ -z "$shell_path" ]; then
      gum style --foreground 196 "Error: $USER_SHELL not found in PATH"
      return
    fi

    # Check if shell is in /etc/shells
    if ! grep -q "^${shell_path}$" /etc/shells; then
      gum style --foreground 220 "Adding $shell_path to /etc/shells..."
      echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
    fi

    gum style --foreground 220 "Changing default shell to $USER_SHELL..."
    gum style --foreground 220 "You may be prompted for your password..."

    if sudo chsh -s "$shell_path" "$USER"; then
      gum style --foreground 82 "✓ $USER_SHELL set as default shell!"
      gum style --foreground 220 "Note: You need to log out and log back in for this to take effect"
    else
      gum style --foreground 196 "✗ Failed to change shell. Try manually: chsh -s $shell_path"
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
      bash "$theme_script"
      rm -f "$theme_script"
      gum style --foreground 82 "✓ SDDM theme installed!"
    else
      gum style --foreground 196 "✗ Failed to download SDDM theme installer"
    fi
  else
    gum style --foreground 220 "Skipping SDDM theme installation"
    gum style --foreground 220 "You can configure SDDM theme later manually"
  fi
}

run_plugin_installer_if_in_hyprland() {
  # Only run if user is currently in Hyprland session
  if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"

    if gum confirm "You're currently in Hyprland. Install plugins now?"; then
      if [ -x "$HOME/.local/bin/install-hyprland-plugins" ]; then
        gum style --foreground 220 "Running plugin installer..."
        "$HOME/.local/bin/install-hyprland-plugins"
      else
        gum style --foreground 196 "Error: Plugin installer not found!"
      fi
    else
      gum style --foreground 220 "You can run 'install-hyprland-plugins' later"
    fi
  elif [ "$HYPRLAND_NEWLY_INSTALLED" = true ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"
    gum style --foreground 220 "Hyprland was just installed."
    gum style --foreground 220 "After reboot, log into Hyprland and run:"
    gum style --foreground 82 "  install-hyprland-plugins"
  else
    gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"
    gum style --foreground 220 "When you're in Hyprland, run: install-hyprland-plugins"
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
    echo -e "${RED}Unknown option: $1"
    echo -e "${ORANGE}HUH??? whats thats suppose to do?? drive f1 for FE---i and win??"
    echo -e "${BLUE}Try running again with${NC} ${GREEN}--help${NC} Cause You really need it"
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

  # Backup existing configs based on Hecate/config
  backup_config

  # Ask all user preferences first (including SDDM)
  ask_preferences

  # Build complete package list (includes SDDM if selected)
  build_package_list

  # Install everything at once
  install_packages

  # Enable SDDM if it was installed
  enable_sddm

  # Setup shell plugins
  setup_shell_plugins

  # Install configuration files
  move_config
  setup_Waybar
  build_preferd_app_keybind
  create_hecate_config

  # Set default shell
  set_default_shell

  # Configure SDDM theme at the end
  configure_sddm_theme

  # Runs hyperland plugin install script if user is already in hyperland and skips if hyperland is newly installed or not loged in
  run_plugin_installer_if_in_hyprland

  # Completion message
  gum style \
    --foreground 82 \
    --border-foreground 82 \
    --border double \
    --align left \
    --width 70 \
    --margin "1 2" \
    --padding "2 4" \
    '✓ Installation Complete!' \
    '(surprisingly, nothing exploded)' '' \
    'Your Hyprland rice is now 99% complete!' \
    'The remaining 1% is tweaking it at 3 AM for the next 6 months' ''

  gum style --foreground 62 \
    'Post-Install TODO:' \
    '1. Reboot (or live dangerously and just re-login)' \
    '2. Log into Hyprland' \
    '3. Run: install-hyprland-plugins' \
    '4. Take screenshot' \
    '5. Post to r/unixporn'
  echo ""
  echo "May your wallpapers be dynamic and your RAM usage low."
  echo ""
  sleep 3

  if gum confirm "Reboot now? (Recommended unless you enjoy living on the edge)"; then
    gum style --foreground 72 "See you on the other side..."
    sleep 2
    sudo reboot
  else
    gum style --foreground 220 "Bold choice. Remember to reboot eventually!"
    gum style --foreground 220 "Your computer will judge you silently until you do."
  fi
}

# Run main function with arguments
main "$@"

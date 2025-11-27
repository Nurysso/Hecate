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
FREYA_URL="https://github.com/Aelune/freya.git"
OS="arch"
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
  if ! git clone --depth 1 "$REPO_URL" "$HECATEDIR"; then
    gum style --foreground 196 "✗ Error cloning repository!"
    exit 1
  fi

  # Verify critical directories exist
  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "✗ Error: Config directory not found in cloned repo!"
    exit 1
  fi

  gum style --foreground 82 "✓ Dotfiles cloned successfully!"
}

# Backup existing configs to cache instead of .config
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.cache/hecate-backup/hecate-$timestamp"

  # List of config directories to check (excluding shell rc files)
   local config_dirs=(
 "alacritty"  "cava" "fastfetch"  "foot"     "gtk-3.0"  "hecate"  "kitty"    "quickshell"  "starship" "wallust" "waypaper" "zsh" "bash"  "fish" "ghostty" "gtk-4.0" "hypr" "matugen" "rofi" "swaync" "waybar" "wlogout"
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
      gum style --foreground 220 "Backing up: $dir"
      cp -r "$HOME/.config/$dir" "$backup_dir/config/"
    fi
  done

  # Backup shell rc files
  for file in "${shell_files[@]}"; do
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    gum style --foreground 220 "Backing up: $file"
    cp "$HOME/$file" "$backup_dir/"
  done

  if [ "$backed_up" = true ]; then
    gum style --foreground 82 "✓ Backup created at: $backup_dir"
    echo "$backup_dir" > "$HOME/.cache/hecate_last_backup.txt"
  else
    gum style --foreground 220 "No existing configs found to backup"
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
  INSTALL_PACKAGES+=(git wget curl unzip wl-clipboard wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar quickshell-git python-pywal btop base-devel cliphist jq hyprpaper inter-font ttf-jetbrains-mono-nerd tesseract noto-fonts-emoji swww hyprlock hypridle starship noto-fonts grim slurp   neovim nano webkit2gtk)

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

    # Try to install all packages at once, never exit on error
    set +e
    $PACKAGE_MANAGER -S --needed --noconfirm "${INSTALL_PACKAGES[@]}" 2>&1 | tee /tmp/hecate_install.log
    local install_exit_code=$?
    set -e

    # Check if all packages were already up to date
    if grep -q "there is nothing to do" /tmp/hecate_install.log 2>/dev/null || \
       grep -q "is up to date -- skipping" /tmp/hecate_install.log 2>/dev/null; then
      gum style --foreground 82 "✓ All packages are already installed and up to date!"
      echo ""
      return 0
    fi

    # Always check which packages are actually installed, regardless of exit code
    local success_count=0
    FAILED_PACKAGES=()

    gum style --foreground 220 "Verifying package installation..."
    for pkg in "${INSTALL_PACKAGES[@]}"; do
      if pacman -Q "$pkg" &>/dev/null; then
        ((success_count++))
      else
        FAILED_PACKAGES+=("$pkg")
      fi
    done

    echo ""
    gum style --border double --padding "1 2" --border-foreground 212 "Installation Results"
    gum style --foreground 82 "✓ Verified installed: $success_count/${#INSTALL_PACKAGES[@]} packages"

    # Handle failed packages gracefully
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
      gum style --foreground 196 "✗ Not installed: ${#FAILED_PACKAGES[@]} packages"
      for pkg in "${FAILED_PACKAGES[@]}"; do
        gum style --foreground 196 "  • $pkg"
      done
      echo ""

      # Save failed packages for later
      local failed_log="$HOME/hecate_failed_packages.txt"
      printf '%s\n' "${FAILED_PACKAGES[@]}" >"$failed_log"
      gum style --foreground 220 "Failed packages saved to: $failed_log"
      gum style --foreground 220 "Install them later with: $PACKAGE_MANAGER -S \$(cat $failed_log)"
      echo ""

      # Only check if CRITICAL packages failed
      if ! verify_critical_packages_installed; then
        gum style --foreground 196 "✗ Critical packages are missing!"

        if gum confirm "Some critical packages failed. Continue anyway? (May cause issues)"; then
          gum style --foreground 220 "⚠ Continuing with missing critical packages..."
          return 0
        else
          gum style --foreground 196 "Installation aborted by user"
          exit 1
        fi
      else
        gum style --foreground 82 "✓ All critical packages are installed"
        gum style --foreground 220 "Non-critical packages can be installed later"
      fi
    else
      gum style --foreground 82 "✓ All packages installed successfully!"
    fi

    # Always return success to continue the script
    return 0
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

  if ! git clone --depth 1 https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
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
  local critical_packages=("$USER_TERMINAL" "hyprland" "waybar" "rofi" "swaync" "hyprlock" "hypridle" "wallust" "starship" "wlogout" "grim" "wl-clipboard" "slurp" "tesseract" "webkit2gtk")
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

  local critical_packages=("$USER_TERMINAL" "hyprland" "waybar" "rofi" "swaync" "hyprlock" "hypridle" "wallust" "starship" "wlogout" "grim" "wl-clipboard" "slurp" "tesseract" "webkit2gtk")
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
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
  fi

  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    gum style --foreground 220 "Installing zsh-syntax-highlighting..."
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
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

# Install shell scripts to ~/.local/bin
install_shell_scripts() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Shell Scripts"

  mkdir -p "$HOME/.local/bin"

  local scripts_dir="$HECATEDIR/config/local-bin"

  if [ ! -d "$scripts_dir" ]; then
    gum style --foreground 220 "⚠ Scripts directory not found at $scripts_dir"
    return
  fi

  # Install hecate.sh
  if [ -f "$scripts_dir/hecate.sh" ]; then
    fancy_echo "Installing hecate script..." "slide"
    cp "$scripts_dir/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    fancy_echo "✓ hecate installed to ~/.local/bin/hecate" "slide"
  else
    gum style --foreground 220 "⚠ hecate.sh not found at $scripts_dir/hecate.sh"
  fi

  # Install freya.sh
  if [ -f "$scripts_dir/file_convert.sh" ]; then
    fancy_echo "Installing freya script..." "slide"
    cp "$scripts_dir/file_convert.sh" "$HOME/.local/bin/file_convert"
    chmod +x "$HOME/.local/bin/file_convert"
    fancy_echo "✓ freya installed to ~/.local/bin/file_convert" "slide"
  else
    gum style --foreground 220 "⚠ freya.sh not found at $scripts_dir/file_convert.sh"
  fi

  echo ""
  gum style --foreground 82 "✓ Shell scripts installed successfully!"
}

# Move configs from cloned repo to ~/.config
move_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Configuration Files"

  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "Error: Config directory not found at $HECATEDIR/config"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  # Copy all config directories except shell rc files
  for item in "$HECATEDIR/config"/*; do
    if [ -d "$item" ]; then
      local item_name=$(basename "$item")

      # Skip local-bin directory (handled separately)
      if [ "$item_name" = "local-bin" ]; then
        continue
      fi

      # Handle terminal configs - only install selected terminal
      case "$item_name" in
        alacritty|foot|ghostty|kitty)
          if [ "$item_name" = "$USER_TERMINAL" ]; then
            fancy_echo "Installing $item_name config..." "slide"
            cp -rT "$item" "$CONFIGDIR/$item_name"
          fi
          ;;
        *)
          # Install all other configs
          fancy_echo "Installing $item_name..." "slide"
          cp -rT "$item" "$CONFIGDIR/$item_name"
          ;;
      esac
    fi
  done

  # Handle shell rc files
  if [ -f "$HECATEDIR/config/zshrc" ]; then
    fancy_echo "Installing .zshrc..." "slide"
    cp "$HECATEDIR/config/zshrc" "$HOME/.zshrc"
    fancy_echo "✓ ZSH config installed" "slide"
  else
    gum style --foreground 220 "⚠ zshrc not found in config directory"
  fi

  if [ -f "$HECATEDIR/config/bashrc" ]; then
    fancy_echo "Installing .bashrc..." "slide"
    cp "$HECATEDIR/config/bashrc" "$HOME/.bashrc"
    fancy_echo "✓ BASH config installed" "slide"
  else
    gum style --foreground 220 "⚠ bashrc not found in config directory"
  fi

  # Install shell scripts
  install_shell_scripts

  # Install apps from apps directory
  install_app "Pulse" "$HECATEAPPSDIR/Pulse/build/bin/Pulse"
  install_app "Hecate-Settings" "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings"
  install_app "Aoiler" "$HECATEAPPSDIR/Aoiler/build/bin/Aoiler"

  echo ""
  fancy_echo "✓ Configuration files installed successfully!" "beams"
}

# Helper function to install apps
install_app() {
  local app_name="$1"
  local app_path="$2"
  local app_display="${3:-$app_name}"

  if [ -f "$app_path" ]; then
    fancy_echo "Installing $app_display..." "slide"
    cp "$app_path" "$HOME/.local/bin/$app_name"
    chmod +x "$HOME/.local/bin/$app_name"
    fancy_echo "✓ $app_display installed to ~/.local/bin/$app_name" "slide"
  else
    gum style --foreground 220 "⚠ $app_display binary not found at $app_path"
  fi
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

build_quickApps(){
      gum style --border double --padding "1 2" --border-foreground 212 "Configuring Widgets"

  cat >~/.config/hecate/quickapps.conf <<EOF
# Quick Apps Configuration
# Syntax name=command
# Max 12 characters in name
Browser=$USER_BROWSER_EXEC
Terminal=$USER_TERMINAL
Files=thunar
EOF
    gum style --foreground 82 "✓ widget configured!"
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

# Setup Waybar and link system colors
setup_Waybar() {
  gum style --foreground 220 "Configuring waybar..."

  # Define symlink paths
  local WAYBAR_STYLE_SYMLINK="$HOME/.config/waybar/style.css"
  local WAYBAR_CONFIG_SYMLINK="$HOME/.config/waybar/config"
  local WAYBAR_COLOR_SYMLINK="$HOME/.config/waybar/color.css"
  local SWAYNC_COLOR_SYMLINK="$HOME/.config/swaync/color.css"
  local STARSHIP_SYMLINK="$HOME/.config/starship.toml"
  local HYPRLOCK_SYMLINK="$HOME/.config/hypr/hyprlock.conf"

  # Remove old symlinks or files
  [ -e "$WAYBAR_STYLE_SYMLINK" ] && rm -f "$WAYBAR_STYLE_SYMLINK"
  [ -e "$WAYBAR_CONFIG_SYMLINK" ] && rm -f "$WAYBAR_CONFIG_SYMLINK"
  [ -e "$WAYBAR_COLOR_SYMLINK" ] && rm -f "$WAYBAR_COLOR_SYMLINK"
  [ -e "$SWAYNC_COLOR_SYMLINK" ] && rm -f "$SWAYNC_COLOR_SYMLINK"
  [ -e "$STARSHIP_SYMLINK" ] && rm -f "$STARSHIP_SYMLINK"
  [ -e "$HYPRLOCK_SYMLINK" ] && rm -f "$HYPRLOCK_SYMLINK"

  # Create new symlinks
  ln -s "$HOME/.config/waybar/style/default.css" "$WAYBAR_STYLE_SYMLINK"
  ln -s "$HOME/.config/waybar/configs/top" "$WAYBAR_CONFIG_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$WAYBAR_COLOR_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$SWAYNC_COLOR_SYMLINK"
  ln -s "$HOME/.config/starship/starship.toml" "$STARSHIP_SYMLINK"
  ln -s "$HOME/.config/hypr/hyprlock/hecate-lock.conf" "$HYPRLOCK_SYMLINK"
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

install_extra_tools(){
  gum style \
    --foreground 212 --border-foreground 212 \
    --align center \
    'Installing Aoiler helper kondo' 'used to organize dirs'
    curl -fsSL https://raw.githubusercontent.com/aelune/kondo/main/install.sh | bash
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

# Setup wallpapers
setup_wallpapers() {
  gum style --border double --padding "1 2" --border-foreground 212 "Wallpaper Setup"
  local wallpaper_dir="$HOME/Pictures/wallpapers"
  echo ""
  gum style --foreground 220 "Would you like to download the full wallpaper collection?"
  echo ""
  if gum confirm "Download full wallpaper repository?"; then
    # User wants full collection
    gum style --foreground 82 "Cloning wallpaper repository..."

    if [ -d "$wallpaper_dir" ]; then
      # Check if it's a git repository
      if [ -d "$wallpaper_dir/.git" ]; then
        # Get the remote URL
        local remote_url=$(git -C "$wallpaper_dir" config --get remote.origin.url 2>/dev/null)

        if [ -n "$remote_url" ]; then
          # Normalize URLs for comparison (handle both HTTPS and SSH formats)
          local normalized_remote=$(echo "$remote_url" | sed -e 's|\.git$||' -e 's|https://github.com/||' -e 's|git@github.com:||')
          local normalized_freya=$(echo "$FREYA_URL" | sed -e 's|\.git$||' -e 's|https://github.com/||' -e 's|git@github.com:||')

          if [ "$normalized_remote" = "$normalized_freya" ]; then
            # Same repo - do a git pull preserving user changes
            gum style --foreground 82 "Existing Freya wallpaper repository found. Updating..."

            # Stash any local changes
            git -C "$wallpaper_dir" stash push -m "Auto-stash before Freya update" 2>/dev/null

            # Pull latest changes
            if git -C "$wallpaper_dir" pull --rebase origin main 2>/dev/null || \
               git -C "$wallpaper_dir" pull --rebase origin master 2>/dev/null; then

              # Try to reapply stashed changes (don't fail if there's a conflict)
              git -C "$wallpaper_dir" stash pop 2>/dev/null || {
                gum style --foreground 220 "⚠ Some local changes were preserved in stash"
                gum style --foreground 220 "  Run 'git -C $wallpaper_dir stash list' to see them"
              }

              echo "✓ Wallpaper repository updated!" "beams"
            else
              gum style --foreground 196 "✗ Failed to update repository"
              return 1
            fi
            return 0
          else
            # Different repo - backup existing directory
            local backup_dir="$HOME/Pictures/wallpapers-personal"
            local counter=1

            # Find a unique backup directory name
            while [ -d "$backup_dir" ]; do
              backup_dir="$HOME/Pictures/wallpapers-personal-$counter"
              ((counter++))
            done

            gum style --foreground 220 "Found different wallpaper repository."
            gum style --foreground 220 "Moving to: $backup_dir"

            if mv "$wallpaper_dir" "$backup_dir"; then
              gum style --foreground 82 "✓ Personal wallpapers backed up"
            else
              gum style --foreground 196 "✗ Failed to backup existing wallpapers"
              return 1
            fi
          fi
        fi
      else
        # Not a git repo - backup the directory
        local backup_dir="$HOME/Pictures/wallpapers-personal"
        local counter=1

        while [ -d "$backup_dir" ]; do
          backup_dir="$HOME/Pictures/wallpapers-personal-$counter"
          ((counter++))
        done

        gum style --foreground 220 "Found existing non-git wallpaper directory."
        gum style --foreground 220 "Moving to: $backup_dir"

        if mv "$wallpaper_dir" "$backup_dir"; then
          gum style --foreground 82 "✓ Personal wallpapers backed up"
        else
          gum style --foreground 196 "✗ Failed to backup existing wallpapers"
          return 1
        fi
      fi
    fi

    # Clone the repository
    mkdir -p "$HOME/Pictures"
    if git clone --depth 1 "$FREYA_URL" "$HOME/Pictures/Freya-temp"; then
      # Move only the walls directory and rename to wallpapers
      if [ -d "$HOME/Pictures/Freya-temp/walls" ]; then
        mv "$HOME/Pictures/Freya-temp/walls" "$wallpaper_dir"
        rm -rf "$HOME/Pictures/Freya-temp"
        echo "✓ Full wallpaper collection downloaded!" "beams"
      else
        gum style --foreground 196 "✗ Walls directory not found in repository"
        rm -rf "$HOME/Pictures/Freya-temp"
        return 1
      fi
    else
      gum style --foreground 196 "✗ Failed to clone wallpaper repository"
      return 1
    fi
  else
    # User wants only default wallpapers
    gum style --foreground 82 "Downloading default wallpapers..."
    mkdir -p "$wallpaper_dir"
    local lock_screen_url="https://raw.githubusercontent.com/Aelune/Freya/main/walls/hecate-default/lock-screen.png"
    local wallpaper_url="https://raw.githubusercontent.com/Aelune/Freya/main/walls/hecate-default/wallpaper.png"
    local success=0
    # Download lock screen
    echo "Downloading lock-screen.png..." "slide"
    if curl -fsSL "$lock_screen_url" -o "$wallpaper_dir/lock-screen.png"; then
      echo "✓ lock-screen.png downloaded" "slide"
      ((success++))
    else
      gum style --foreground 196 "✗ Failed to download lock-screen.png"
    fi
    # Download wallpaper
    echo "Downloading wallpaper.png..." "slide"
    if curl -fsSL "$wallpaper_url" -o "$wallpaper_dir/wallpaper.png"; then
      echo "✓ wallpaper.png downloaded" "slide"
      ((success++))
    else
      gum style --foreground 196 "✗ Failed to download wallpaper.png"
    fi
    if [ $success -eq 2 ]; then
      echo ""
      echo "✓ Default wallpapers downloaded!" "beams"
    else
      echo ""
      gum style --foreground 220 "⚠ Some wallpapers failed to download"
    fi
  fi
  echo ""
  gum style --foreground 82 "Wallpapers saved to: $wallpaper_dir"
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

  # Confirm installation
    if ! gum confirm "Do you want to proceed with Hecate installation?"; then
      gum style --foreground 220 "Installation cancelled"
      echo "Exiting"
      exit 0
    fi


  gum style --foreground 220 "Starting installation process..."
  sleep 1

  # System checks
  # check_OS
  get_packageManager

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

  # Clone repo early to check configs
  clone_dotfiles

  # Backup existing configs
  backup_config

  # Install configuration files
  move_config

  # Setup Waybar symlinks
  setup_Waybar

  build_preferd_app_keybind
  build_quickApps
  create_hecate_config

  # Set default shell
  set_default_shell
  install_extra_tools
  setup_wallpapers
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
    '3. Take screenshot' \
    '4. Post to r/unixporn'
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

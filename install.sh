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

REPO_URL="https://github.com/nurysso/Hecate.git"
# https://github.com/nurysso/Hecate/blob/main/scripts/install/arch.sh
SCRIPT_BASE_URL="https://raw.githubusercontent.com/nurysso/Hecate/blod/main/scripts/install"
OS=""
PACKAGE_MANAGER=""
SKIP_DEPS=false

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --no-deps)
        SKIP_DEPS=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      --dry-run)
        dry_run
        exit 0
        ;;
      -*)
        echo -e "${RED}Unknown option: $1${NC}"
        echo -e "${BLUE}Try: ./install.sh --help${NC}"
        exit 1
        ;;
      *)
        shift
        ;;
    esac
  done
}

show_help() {
  clear
  echo -e "${YELLOW}Prerequisites:${NC}"
  echo "  • gum - Interactive CLI tool"
  echo "    (Will be installed automatically if missing)"
  echo ""
  echo "  • tte - Terminal text effects"
  echo "    Install: pip install terminaltexteffects"
  echo ""
  echo "  • paru (recommended) - AUR helper (Arch only)"
  echo "    Install: https://github.com/Morganamilo/paru#installation"
  echo ""
  echo -e "${YELLOW}Usage:${NC}"
  echo "  ./install.sh              Run the full installer"
  echo "  ./install.sh --no-deps    Skip dependency installation"
  echo "  ./install.sh --help       Show this message"
  echo "  ./install.sh --dry-run    Simulate installation"
  echo ""
  echo -e "${YELLOW}Options:${NC}"
  echo "  --no-deps    Skip OS-specific dependency installation"
  echo "               Only clones repo, backs up configs, and installs dotfiles"
  echo ""
  echo "Supported distributions: Arch, Fedora, Ubuntu/Debian(maybe in future for now run with --no-deps)"
}

dry_run() {
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
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    arch | manjaro | endeavouros | cachyos)
      OS="arch"
      ;;
    fedora)
      OS="fedora"
      ;;
    ubuntu | debian | pop | linuxmint)
      OS="ubuntu"
      ;;
    *)
      echo -e "${RED}Error: OS '$ID' is not supported!${NC}"
      exit 1
      ;;
    esac
  else
    echo -e "${RED}Error: Cannot detect OS!${NC}"
    exit 1
  fi
}

# Install gum based on detected OS
install_gum() {
  echo -e "${YELLOW}Installing gum...${NC}"
  echo ""

  case "$OS" in
  arch)
    if command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm gum
    else
      echo -e "${RED}pacman not found!${NC}"
      return 1
    fi
    ;;
  fedora)
    if command -v dnf &>/dev/null; then
      sudo dnf install -y gum
    else
      echo -e "${RED}dnf not found!${NC}"
      return 1
    fi
    ;;
  ubuntu)
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
    ;;
  *)
    echo -e "${RED}Unsupported OS for automatic gum installation${NC}"
    return 1
    ;;
  esac

  if command -v gum &>/dev/null; then
    echo -e "${GREEN}✓ Gum installed successfully!${NC}"
    return 0
  else
    echo -e "${RED}✗ Gum installation failed!${NC}"
    return 1
  fi
}


check_dependencies() {
  local missing=()

  # Check gum
  if ! command -v gum &>/dev/null; then missing+=("gum"); fi
  # Check figlet
  if ! command -v figlet &>/dev/null; then missing+=("figlet"); fi
  # Check tte
  if ! command -v tte &>/dev/null; then missing+=("tte"); fi

  if [ ${#missing[@]} -eq 0 ]; then
    return 0
  fi

  echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
  echo -e "${YELLOW}Required for this installer to work.${NC}"
  echo ""

  # Detect AUR helper
  local aur_helper=""
  if command -v paru &>/dev/null; then
    aur_helper="paru"
  elif command -v yay &>/dev/null; then
    aur_helper="yay"
  fi

  # Prompt user to install
  read -p "Would you like to install missing dependencies now? (y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    if install_dependencies "${missing[@]}"; then
      echo ""
      echo -e "${GREEN}All dependencies installed successfully!${NC}"
      echo -e "${GREEN}Continuing with installation...${NC}"
      echo ""
      sleep 1
    else
      echo -e "${RED}Failed to install dependencies. Exiting.${NC}"
      exit 1
    fi
  else
    echo ""
    echo -e "${YELLOW}Installation cancelled.${NC}"
    echo -e "${BLUE}Install dependencies manually and run this script again.${NC}"
    echo ""
    echo "Manual installation instructions (Arch):"
    echo -e "${GREEN}  sudo pacman -S figlet gum${NC}"
    echo -e "${GREEN}  $aur_helper -S terminaltexteffects${NC}"
    echo ""
    echo "Other distros:"
    case "$OS" in
      fedora)
        echo -e "${GREEN}  sudo dnf install gum figlet${NC}"
        echo -e "${GREEN}  pip install terminaltexteffects${NC}"
        ;;
      ubuntu)
        echo -e "${GREEN}  sudo apt install figlet${NC}"
        echo -e "${GREEN}  # Gum (Charm repo):${NC}"
        echo -e "${GREEN}  sudo mkdir -p /etc/apt/keyrings${NC}"
        echo -e "${GREEN}  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg${NC}"
        echo -e "${GREEN}  echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list${NC}"
        echo -e "${GREEN}  sudo apt update && sudo apt install gum${NC}"
        echo -e "${GREEN}  pip install terminaltexteffects${NC}"
        ;;
      *)
        echo "  Visit: https://github.com/charmbracelet/gum"
        echo "  sudo pacman -S figlet (or equivalent)"
        echo "  pip install terminaltexteffects"
        ;;
    esac
    echo ""
    exit 1
  fi
}

install_dependencies() {
  local deps=("$@")

  case "$OS" in
    arch)
      # Install official packages first
      sudo pacman -S --noconfirm "${deps[@]}" 2>/dev/null || true

      # Install tte via AUR helper if missing
      if ! command -v tte &>/dev/null; then
        local aur_helper=""
        if command -v paru &>/dev/null; then
          aur_helper="paru"
        elif command -v yay &>/dev/null; then
          aur_helper="yay"
        else
          echo -e "${RED}No AUR helper (paru/yay) found. Install paru/yay first.${NC}"
          return 1
        fi

        echo "Installing terminaltexteffects via $aur_helper..."
        $aur_helper -S --noconfirm terminaltexteffects || {
          echo -e "${RED}Failed to install terminaltexteffects via AUR.${NC}"
          echo -e "${YELLOW}Trying pip install as fallback...${NC}"
          pip install terminaltexteffects || return 1
        }
      fi
      ;;
    *)
      # Fallback for other distros (pip for tte)
      pip install terminaltexteffects || return 1
      ;;
  esac

  return 0
}


# Check if tte is installed
check_tte() {
  if ! command -v tte &>/dev/null; then
    gum style --foreground 220 "⚠ TTE (Terminal Text Effects) not found"
    gum style --foreground 220 "Install with: pip install terminaltexteffects"
    echo ""
    if gum confirm "Continue without TTE effects?"; then
      return 0
    else
      exit 1
    fi
  fi
}

# Use tte if available, otherwise fallback to echo
fancy_echo() {
  local text="$1"
  local effect="${2:-slide}"

  if command -v tte &>/dev/null; then
    echo "$text" | tte "$effect" --movement-speed 0.5 2>/dev/null || echo "$text"
  else
    echo "$text"
  fi
}

# Check OS and display appropriate messages
check_OS() {
  case "$OS" in
  arch)
    fancy_echo "✓ Detected OS: Arch Linux" "slide"
    ;;
  fedora)
    gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
    gum style --foreground 220 "Proceed at your own risk or follow the Fedora guide if available at:"
    gum style --foreground 220 "https://github.com/nurysso/Hecate/tree/main/documentation/install-fedora.md"
    if ! gum confirm "Continue with Fedora installation?"; then
      exit 1
    fi
    ;;
  ubuntu)
    gum style --foreground 220 --bold "⚠️ Warning: Ubuntu/Debian-based OS detected!"
    gum style --foreground 220 "Hecate installer support for Ubuntu is experimental."
    gum style --foreground 220 "Manual installation instructions:"
    gum style --foreground 220 "https://github.com/nurysso/Hecate/tree/main/documentation/install-ubuntu.md"
    if ! gum confirm "Continue with Ubuntu installation?"; then
      exit 1
    fi
    ;;
  esac
}

# Download and execute OS-specific installation script
run_os_script() {
  local script_name="${OS}.sh"
  local script_url="${SCRIPT_BASE_URL}/${script_name}"
  local temp_script="/tmp/hecate_install_${OS}.sh"

  gum style --foreground 82 "Downloading ${OS} installation script..."
  echo ""

  if curl -fsSL "$script_url" -o "$temp_script"; then
    fancy_echo "✓ Script downloaded successfully" "slide"
    chmod +x "$temp_script"

    echo ""
    gum style --foreground 220 "Executing ${OS} installation script..."
    echo ""

    # Execute the script
    if bash "$temp_script"; then
      fancy_echo "✓ Installation script completed successfully" "beams"
    else
      gum style --foreground 196 "✗ Installation script failed"
      rm -f "$temp_script"
      exit 1
    fi

    # Clean up
    rm -f "$temp_script"
  else
    gum style --foreground 196 "✗ Failed to download installation script from:"
    gum style --foreground 196 "  $script_url"
    echo ""
    gum style --foreground 220 "Please check:"
    gum style --foreground 220 "  1. Your internet connection"
    gum style --foreground 220 "  2. The script exists in the repository"
    gum style --foreground 220 "  3. The URL is correct"
    exit 1
  fi
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
    gum style --foreground 196 "Check your internet connection and try again."
    exit 1
  fi

  # Verify critical directories exist
  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "✗ Error: Config directory not found in cloned repo!"
    exit 1
  fi

  fancy_echo "✓ Dotfiles cloned successfully!" "beams"
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

backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.cache/hecate-backup/hecate-$timestamp"

  # List of config directories to check
  local config_dirs=(
    "alacritty" "cava" "fastfetch" "foot" "gtk-3.0" "hecate" "kitty"
    "quickshell" "starship" "wallust" "waypaper" "zsh" "bash" "fish"
    "ghostty" "gtk-4.0" "hypr" "matugen" "rofi" "swaync" "waybar" "wlogout"
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
      fancy_echo "Backing up: $dir" "slide"
      cp -r "$HOME/.config/$dir" "$backup_dir/config/"
    fi
  done

  # Backup shell rc files
  for file in "${shell_files[@]}"; do
    if [ "$backed_up" = false ]; then
      mkdir -p "$backup_dir"
      backed_up=true
    fi
    fancy_echo "Backing up: $file" "slide"
    cp "$HOME/$file" "$backup_dir/"
  done

  if [ "$backed_up" = true ]; then
    echo ""
    fancy_echo "✓ Backup created at: $backup_dir" "beams"
    echo "$backup_dir" > "$HOME/.cache/hecate_last_backup.txt"
  else
    gum style --foreground 220 "No existing configs found to backup"
  fi
}

# Main function
main() {
  # Parse arguments first
  parse_args "$@"

  # Detect OS first (needed before gum check)
  detect_os

  # Check deps install gum if needed
  check_dependencies

  # Check for tte
  check_tte

  # Now we can use gum for pretty output
  clear

  if command -v tte &>/dev/null; then
    figlet -f slant "Hecate Dotfiles Installer" | tte laseretch --etch-speed 4
    echo 'Preparing to install Hyprland configuration...' | tte slide --movement-speed 0.5
  else
    gum style \
      --foreground 82 \
      --border-foreground 82 \
      --border double \
      --align center \
      --width 70 \
      --margin "1 2" \
      --padding "2 4" \
      'Hecate Dotfiles Installer' \
      '' \
      'Preparing to install Hyprland configuration...'
  fi

  echo ""
  check_OS
  echo ""

  # Run OS-specific installation script only if --no-deps not specified
  if [ "$SKIP_DEPS" = false ]; then
    gum style --foreground 82 "Running OS-specific dependency installation..."
    echo ""
    run_os_script
    echo ""
  else
    gum style --foreground 220 "⚠ Skipping dependency installation (--no-deps flag)"
    echo ""
  fi

  # Always run these steps
  backup_config
  echo ""

  clone_dotfiles
  echo ""

  move_config
  echo ""

  if command -v tte &>/dev/null; then
    echo '✓ Installation Complete!' | tte beams --beam-delay 30
  else
    gum style \
      --foreground 82 \
      --border-foreground 82 \
      --border double \
      --align left \
      --width 70 \
      --margin "1 2" \
      --padding "2 4" \
      '✓ Installation Complete!'
  fi

  echo ""
  gum style --foreground 85 '(surprisingly, nothing exploded)'
  echo ""

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
    fancy_echo "Rebooting..." "slide"
    sleep 2
    sudo reboot
  else
    gum style --foreground 220 "Remember to reboot to apply all changes!"
  fi
}

# Run main function with arguments
main "$@"

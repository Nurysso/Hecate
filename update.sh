#!/bin/bash

# Hecate Update Script
# Description: Updates Hecate dotfiles with backup and configuration preservation

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
CONFIG_FILE="$HOME/.config/hecate/hecate.toml"
VERSION_FILE="$HECATEDIR/version.txt"

# Check if gum is installed
check_gum() {
  if ! command -v gum &>/dev/null; then
    echo -e "${RED}Gum is not installed!${NC}"
    echo -e "${YELLOW}Gum is required for this updater to work.${NC}"
    echo ""
    echo "Please install Gum using:"
    echo "  sudo pacman -S gum"
    exit 1
  fi
}

# Check if Hecate is installed
check_hecate_installed() {
  if [ ! -f "$CONFIG_FILE" ]; then
    gum style --foreground 196 --bold "❌ Error: Hecate is not installed!"
    gum style --foreground 220 "Please run the installer first."
    exit 1
  fi
}

# Parse TOML value - Enhanced to handle sections
get_config_value() {
  local key="$1"
  local section="${2:-}"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    return
  fi

  if [ -n "$section" ]; then
    # Extract value from specific section
    awk -v section="$section" -v key="$key" '
      /^\[.*\]/ {
        current_section = $0
        gsub(/^\[|\]$/, "", current_section)
      }
      current_section == section && $0 ~ "^" key " *= *" {
        sub("^" key " *= *\"?", "")
        sub("\"? *(#.*)?$", "")
        print
        exit
      }
    ' "$CONFIG_FILE"
  else
    # Original behavior for backwards compatibility
    grep -E "^\s*$key\s*=" "$CONFIG_FILE" 2>/dev/null |
      head -n1 |
      sed -E "s/^\s*$key\s*=\s*\"?([^\"]*)\"?/\1/" || echo ""
  fi
}

# Set TOML value in specific section
set_config_value() {
  local key="$1"
  local value="$2"
  local section="${3:-metadata}"

  # Use awk to update value in correct section
  awk -v section="$section" -v key="$key" -v value="$value" '
    /^\[.*\]/ {
      current_section = $0
      gsub(/^\[|\]$/, "", current_section)
      print
      next
    }
    current_section == section && $0 ~ "^" key " *= *" {
      print key " = \"" value "\""
      next
    }
    { print }
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Read configuration values
read_user_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Reading Configuration"

  # Read from [metadata] section
  current_version=$(get_config_value "version" "metadata")

  # Read from [preferences] section
  USER_TERMINAL=$(get_config_value "term" "preferences")
  USER_BROWSER=$(get_config_value "browser" "preferences")
  USER_SHELL=$(get_config_value "shell" "preferences")
  USER_PROFILE=$(get_config_value "profile" "preferences")

  # Read from [theme] section
  THEME_MODE=$(get_config_value "mode" "theme")

  gum style --foreground 82 "✓ Configuration loaded:"
  gum style --foreground 82 "  Version: ${current_version}"
  gum style --foreground 82 "  Terminal: ${USER_TERMINAL}"
  gum style --foreground 82 "  Browser: ${USER_BROWSER}"
  gum style --foreground 82 "  Shell: ${USER_SHELL}"
  gum style --foreground 82 "  Profile: ${USER_PROFILE}"
  gum style --foreground 82 "  Theme: ${THEME_MODE}"

  # Validate required values
  if [ -z "$USER_TERMINAL" ] || [ -z "$USER_SHELL" ]; then
    gum style --foreground 196 "❌ Error: Missing required configuration values!"
    exit 1
  fi
}

# Get current and remote versions
check_versions() {
  remote_version=$(curl -s "https://raw.githubusercontent.com/Aelune/Hecate/main/version.txt" 2>/dev/null || echo "")

  if [ -z "$remote_version" ]; then
    gum style --foreground 196 "❌ Failed to fetch remote version"
    gum style --foreground 220 "Check your internet connection"
    exit 1
  fi

  if [ "$current_version" = "$remote_version" ]; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi

  gum style --foreground 62 "Current version: ${current_version}"
  gum style --foreground 82 "Latest version:  $remote_version"
}

# Show update warning and get confirmation
show_update_warning() {
  gum style --border double --padding "1 2" --border-foreground 196 "⚠️  Update Warning"

  gum style --foreground 220 --bold "IMPORTANT: Please read carefully before proceeding!"
  echo ""
  gum style --foreground 220 "This update will:"
  gum style --foreground 220 "  1. Backup your current configuration to:"
  gum style --foreground 220 "     ~/.cache/hecate-backup/update-[timestamp]"
  echo ""
  gum style --foreground 220 "  2. Replace all Hecate configuration files with new versions"
  echo ""
  gum style --foreground 196 --bold "  3. ⚠️  ANY CUSTOM CHANGES YOU MADE WILL BE GONE BUT YOU CAN COPY THEM FROM BACKUP!"
  echo ""
  gum style --foreground 82 "Your backed up configs will be available at the backup location."
  echo ""

  if ! gum confirm "Do you understand and want to proceed with the update?"; then
    gum style --foreground 220 "Update cancelled. Your configuration remains unchanged."
    exit 0
  fi

  echo ""
  gum style --foreground 196 --bold "Final confirmation:"
  if ! gum confirm "Are you absolutely sure you want to continue?"; then
    gum style --foreground 220 "Update cancelled."
    exit 0
  fi
}

# Checks user OS
check_OS() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    arch | manjaro | endeavouros)
      OS="arch"
      gum style --foreground 82 "✓ Detected OS: $OS"
      ;;
    *)
      gum style --foreground 196 --bold "❌ Error: OS '$ID' is not supported by updater!"
      exit 1
      ;;
    esac
  else
    gum style --foreground 196 --bold "Error: Cannot detect OS!"
    exit 1
  fi
}

# Clone dotfiles
clone_dotfiles() {
  gum style --border double --padding "1 2" --border-foreground 212 "Cloning Hecate Dotfiles"

  if [ -d "$HECATEDIR" ]; then
    if gum confirm "Hecate directory already exists. Move it to backup?"; then
      local timestamp=$(date +%Y%m%d_%H%M%S)
      mkdir -p "$HOME/.cache/hecate-backup"
      mv "$HECATEDIR" "$HOME/.cache/hecate-backup/hecate-source-$timestamp"
      gum style --foreground 82 "✓ Old Hecate directory moved to backup"
    else
      gum style --foreground 220 "Removing existing Hecate directory..."
      rm -rf "$HECATEDIR"
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

# Backup existing configs to cache instead of .config
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.cache/hecate-backup/hecate-$timestamp"

  # List of config directories to check (excluding shell rc files)
  local config_dirs=(
    "alacritty" "fish" "hecate" "rofi" "waypaper" "bash" "foot"
    "hypr" "starship" "swaync" "wlogout" "cava" "ghostty" "kitty"
    "eww" "gtk-3.0" "matugen" "wallust" "fastfetch" "gtk-4.0"
    "quickshell" "waybar"
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

verify_critical_packages_installed() {
  local critical_packages=(
    "$USER_TERMINAL" "hyprland" "waybar" "rofi" "swaync"
    "hyprlock" "hypridle" "wallust" "starship" "wlogout"
    "grim" "wl-clipboard" "webkit2gtk" "quickshell-git"
    "python-pywal" "fastfetch" "matugen-bin" "waypaper"
  )
  local missing_critical=()

  for pkg in "${critical_packages[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      if ! pacman -Q "$pkg" &>/dev/null 2>&1 && ! paru -Q "$pkg" &>/dev/null 2>&1; then
        missing_critical+=("$pkg")
      fi
    fi
  done

  if [ ${#missing_critical[@]} -gt 0 ]; then
    gum style --foreground 196 "Missing critical packages:"
    for pkg in "${missing_critical[@]}"; do
      gum style --foreground 196 "  • $pkg"
    done

    if gum confirm "Install missing packages now?"; then
      if command -v paru &>/dev/null; then
        paru -S --needed "${missing_critical[@]}"
      else
        sudo pacman -S --needed "${missing_critical[@]}"
      fi
    else
      return 1
    fi
  fi

  return 0
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

  # Copy all config directories except shell rc files and hecate.sh
  for item in "$HECATEDIR/config"/*; do
    if [ -d "$item" ]; then
      local item_name=$(basename "$item")

      # Handle terminal configs - only install selected terminal
      case "$item_name" in
        alacritty|foot|ghostty|kitty)
          if [ "$item_name" = "$USER_TERMINAL" ]; then
            gum style --foreground 82 "Installing $item_name config..."
            cp -rT "$item" "$CONFIGDIR/$item_name"
          fi
          ;;
        *)
          # Install all other configs
          gum style --foreground 82 "Installing $item_name..."
          cp -rT "$item" "$CONFIGDIR/$item_name"
          ;;
      esac
    fi
  done

  # Handle shell rc files
  if [ -f "$HECATEDIR/config/zshrc" ]; then
    gum style --foreground 82 "Installing .zshrc..."
    cp "$HECATEDIR/config/zshrc" "$HOME/.zshrc"
    gum style --foreground 82 "✓ ZSH config installed"
  else
    gum style --foreground 220 "⚠ zshrc not found in config directory"
  fi

  if [ -f "$HECATEDIR/config/bashrc" ]; then
    gum style --foreground 82 "Installing .bashrc..."
    cp "$HECATEDIR/config/bashrc" "$HOME/.bashrc"
    gum style --foreground 82 "✓ BASH config installed"
  else
    gum style --foreground 220 "⚠ bashrc not found in config directory"
  fi

  # Install hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Installing hecate CLI tool..."
    cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    gum style --foreground 82 "✓ hecate command installed"
  else
    gum style --foreground 220 "⚠ hecate.sh not found in config directory"
  fi

  # Install apps from apps directory
  install_app "Pulse" "$HECATEAPPSDIR/Pulse/build/bin/Pulse"
  install_app "Hecate-Settings" "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings"
  install_app "Aoiler" "$HECATEAPPSDIR/Aoiler/build/bin/Aoiler"

  gum style --foreground 82 "✓ Configuration files installed successfully!"
}

# Helper function to install apps
install_app() {
  local app_name="$1"
  local app_path="$2"
  local app_display="${3:-$app_name}"

  if [ -f "$app_path" ]; then
    gum style --foreground 82 "Installing $app_display..."
    cp "$app_path" "$HOME/.local/bin/$app_name"
    chmod +x "$HOME/.local/bin/$app_name"
    gum style --foreground 82 "✓ $app_display installed to ~/.local/bin/$app_name"
  else
    gum style --foreground 220 "⚠ $app_display binary not found at $app_path"
  fi
}
# Update Hecate config file with new version
update_hecate_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Updating Hecate Configuration"

  local update_date=$(date +%Y-%m-%d)

  # Update metadata section
  set_config_value "version" "$remote_version" "metadata"
  set_config_value "last_update" "$update_date" "metadata"

  gum style --foreground 82 "✓ Hecate config updated"
  gum style --foreground 82 "  Version: $remote_version"
  gum style --foreground 82 "  Date: $update_date"
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

  # Remove old symlinks or files
  [ -e "$WAYBAR_STYLE_SYMLINK" ] && rm -f "$WAYBAR_STYLE_SYMLINK"
  [ -e "$WAYBAR_CONFIG_SYMLINK" ] && rm -f "$WAYBAR_CONFIG_SYMLINK"
  [ -e "$WAYBAR_COLOR_SYMLINK" ] && rm -f "$WAYBAR_COLOR_SYMLINK"
  [ -e "$SWAYNC_COLOR_SYMLINK" ] && rm -f "$SWAYNC_COLOR_SYMLINK"
  [ -e "$STARSHIP_SYMLINK" ] && rm -f "$STARSHIP_SYMLINK"

  # Create new symlinks
  ln -s "$HOME/.config/waybar/style/default.css" "$WAYBAR_STYLE_SYMLINK"
  ln -s "$HOME/.config/waybar/configs/top" "$WAYBAR_CONFIG_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$WAYBAR_COLOR_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$SWAYNC_COLOR_SYMLINK"
  ln -s "$HOME/.config/starship/starship.toml" "$STARSHIP_SYMLINK"

  gum style --foreground 82 "✓ Waybar configured!"
}

# Post-update actions
post_update() {
  gum style --border double --padding "1 2" --border-foreground 212 "Finalizing Update"

  # Reload Hyprland if running
  if [[ "${XDG_SESSION_DESKTOP,,}" == "hyprland" ]]; then
    gum style --foreground 82 "Hyprland session detected, reloading..."

    if command -v hyprctl &>/dev/null; then
      hyprctl reload 2>/dev/null || true

      # Restart widgets and waybar
      if [ -f "$HOME/.config/hypr/scripts/launch-widgets.sh" ]; then
        "$HOME/.config/hypr/scripts/launch-widgets.sh" &
      fi

      if [ -f "$HOME/.config/hypr/scripts/launch-waybar.sh" ]; then
        "$HOME/.config/hypr/scripts/launch-waybar.sh" &
      fi

      gum style --foreground 82 "✓ Hyprland reloaded"
    fi
  else
    gum style --foreground 220 "Not in Hyprland session. Please log out and back in to apply changes."
  fi
}

install_extra_tools(){
  gum style \
    --foreground 212 --border-foreground 212 \
    --align center \
    'Installing Aoiler helper kondo' 'used to organize dirs'
    curl -fsSL https://raw.githubusercontent.com/aelune/kondo/main/install.sh | bash
}

# Show update complete message
show_completion_message() {
  local backup_path=$(cat "$HOME/.cache/hecate_last_backup.txt" 2>/dev/null || echo "")

  echo ""
  gum style --border double --padding "1 2" --border-foreground 82 "✓ Update Complete!"

  gum style --foreground 82 --bold "Hecate has been successfully updated!"
  echo ""
  gum style --foreground 220 "📦 Your old configuration was backed up to:"
  gum style --foreground 82 "   $backup_path"
  echo ""
  gum style --foreground 220 "📝 To restore custom changes:"
  gum style --foreground 82 "   1. Compare backup files with new configs"
  gum style --foreground 82 "   2. Manually reapply your modifications"
  echo ""
  gum style --foreground 220 "🎨 If you're in Hyprland, changes have been applied automatically."
  gum style --foreground 220 "   Otherwise, log out and back in to see the updates."
  echo ""
  gum style --foreground 82 "Thank you for using Hecate! 🌙"
}

# Main update flow
main() {
  clear

  gum style \
    --border double \
    --padding "1 2" \
    --border-foreground 212 \
    --bold \
    "🌙 Hecate Update Manager"

  echo ""

  # Pre-flight checks
  check_gum
  check_hecate_installed
  check_OS

  echo ""

  # Read user configuration
  read_user_config

  echo ""

  # Check versions and get confirmation
  check_versions
  echo ""
  show_update_warning

  echo ""

  # Perform update
  clone_dotfiles
  echo ""
  backup_config
  echo ""
  verify_critical_packages_installed
  echo ""
  move_config
  echo ""
  update_hecate_config
  echo ""
  setup_waybar
  echo ""
  install_extra_tools
  echo ""
  post_update

  # Show completion
  show_completion_message

  # Clean up cloned repository
  rm -rf "$HECATEDIR"
}

# Run main function
main

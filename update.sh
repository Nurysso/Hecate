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

# Parse TOML value
get_config_value() {
  local key="$1"
  if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    return
  fi
  grep -E "^\s*$key\s*=" "$CONFIG_FILE" 2>/dev/null |
    head -n1 |
    sed -E "s/^\s*$key\s*=\s*\"?([^\"]*)\"?/\1/" || echo ""
}

# Set TOML value
set_config_value() {
  local key="$1"
  local value="$2"
  sed -i "s|^$key\s*=.*|$key = \"$value\"|" "$CONFIG_FILE"
}

current_version=$(get_config_value "version")
remote_version=$(curl -s "https://raw.githubusercontent.com/Aelune/Hecate/main/version.txt" 2>/dev/null || echo "")
USER_TERMINAL=$(get_config_value "term")
USER_SHELL=$(get_config_value "shell")

# Get current and remote versions
check_versions() {
  gum style --border double --padding "1 2" --border-foreground 212 "Checking for Updates"
  if [ -z "$remote_version" ]; then
    gum style --foreground 196 "❌ Failed to fetch remote version"
    gum style --foreground 220 "Check your internet connection"
    exit 1
  fi

  gum style --foreground 62 "Current version: ${current_version:-Unknown}"
  gum style --foreground 82 "Latest version:  $remote_version"

  if [ "$current_version" = "$remote_version" ]; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi
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
  gum style --foreground 196 --bold "  3. ⚠️  ANY CUSTOM CHANGES YOU MADE WILL BE OVERWRITTEN!"
  echo ""
  gum style --foreground 220 "If you made custom modifications to:"
  gum style --foreground 220 "  • Hyprland keybindings"
  gum style --foreground 220 "  • Waybar configuration"
  gum style --foreground 220 "  • Theme colors"
  gum style --foreground 220 "  • Any other config files"
  echo ""
  gum style --foreground 82 "You will need to manually reapply them after the update."
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

# Backup existing config - FIXED VERSION
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Creating Backup"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$HOME/.cache/hecate-backup/update-$timestamp"

  mkdir -p "$backup_dir"

  # Get list of folders that exist in Hecate config
  local hecate_configs=()
  if [ -d "$HECATEDIR/config" ]; then
    for folder in "$HECATEDIR/config"/*; do
      if [ -d "$folder" ]; then
        local folder_name=$(basename "$folder")
        # Skip shell configs (zsh, bash, fish) as they're handled separately
        if [[ ! "$folder_name" =~ ^(zsh|bash|fish)$ ]]; then
          hecate_configs+=("$folder_name")
        fi
      fi
    done
  fi

  # Backup configs that exist in both Hecate and ~/.config/
  for config in "${hecate_configs[@]}"; do
    if [ -d "$CONFIGDIR/$config" ]; then
      gum style --foreground 220 "Backing up: $config"
      mkdir -p "$backup_dir"
      cp -r "$CONFIGDIR/$config" "$backup_dir/"
    fi
  done

  # Backup terminal config
  if [ -n "$USER_TERMINAL" ] && [ -d "$CONFIGDIR/$USER_TERMINAL" ]; then
    gum style --foreground 220 "Backing up: $USER_TERMINAL"
    cp -r "$CONFIGDIR/$USER_TERMINAL" "$backup_dir/"
  fi

  # Backup shell configs
  case "$USER_SHELL" in
  zsh)
    if [ -f "$HOME/.zshrc" ]; then
      gum style --foreground 220 "Backing up: .zshrc"
      mkdir -p "$backup_dir/zsh"
      cp "$HOME/.zshrc" "$backup_dir/zsh/.zshrc"
    fi
    ;;
  bash)
    if [ -f "$HOME/.bashrc" ]; then
      gum style --foreground 220 "Backing up: .bashrc"
      mkdir -p "$backup_dir/bash"
      cp "$HOME/.bashrc" "$backup_dir/bash/.bashrc"
    fi
    ;;
  fish)
    if [ -d "$HOME/.config/fish" ]; then
      gum style --foreground 220 "Backing up: fish config"
      cp -r "$HOME/.config/fish" "$backup_dir/"
    fi
    ;;
  esac

  # Backup starship
  if [ -f "$HOME/.config/starship.toml" ]; then
    gum style --foreground 220 "Backing up: starship.toml"
    mkdir -p "$backup_dir/starship"
    cp "$HOME/.config/starship.toml" "$backup_dir/starship/"
  fi

  gum style --foreground 82 --bold "✓ Backup created at:"
  gum style --foreground 82 "  $backup_dir"
  echo "$backup_dir" >"$HOME/.cache/hecate_last_backup.txt"

  echo ""
  gum style --foreground 220 "💡 Tip: Save this path to restore custom changes later!"
  sleep 2
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

# Install updated config files - FIXED VERSION
install_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Updated Configuration"

  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "Error: Config directory not found!"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  for folder in "$HECATEDIR/config"/*; do
    if [ ! -d "$folder" ]; then
      continue
    fi

    local folder_name=$(basename "$folder")

    # Skip the 'hecate' directory entirely (preserved from user settings)
    [ "$folder_name" = "hecate" ] && continue

    case "$folder_name" in
    alacritty | foot | ghostty | kitty)
      if [ "$folder_name" = "$USER_TERMINAL" ]; then
        gum style --foreground 82 "Updating $folder_name config..."
        mkdir -p "$CONFIGDIR/$folder_name"
        cp -rf "$folder/"* "$CONFIGDIR/$folder_name/"
      fi
      ;;
    zsh)
      if [ "$USER_SHELL" = "zsh" ] && [ -f "$folder/.zshrc" ]; then
        gum style --foreground 82 "Updating .zshrc..."
        cp "$folder/.zshrc" "$HOME/.zshrc"
      fi
      ;;
    bash)
      if [ "$USER_SHELL" = "bash" ] && [ -f "$folder/.bashrc" ]; then
        gum style --foreground 82 "Updating .bashrc..."
        cp "$folder/.bashrc" "$HOME/.bashrc"
      fi
      ;;
    fish)
      if [ "$USER_SHELL" = "fish" ]; then
        gum style --foreground 82 "Updating fish config..."
        mkdir -p "$CONFIGDIR/fish"
        cp -rf "$folder/"* "$CONFIGDIR/fish/"
      fi
      ;;
    starship)
      if [ -f "$folder/starship.toml" ]; then
        gum style --foreground 82 "Updating Starship config..."
        cp "$folder/starship.toml" "$HOME/.config/starship.toml"
      fi
      ;;
    *)
      # For all other configs, copy contents into ~/.config/folder_name/
      gum style --foreground 82 "Updating $folder_name..."
      mkdir -p "$CONFIGDIR/$folder_name"
      cp -rf "$folder/"* "$CONFIGDIR/$folder_name/"
      ;;
    esac
  done

  # Update Pulse app
  if [ -d "$HECATEAPPSDIR/Pulse/build/bin" ] && [ -f "$HECATEAPPSDIR/Pulse/build/bin/Pulse" ]; then
    gum style --foreground 82 "Updating Pulse..."
    cp "$HECATEAPPSDIR/Pulse/build/bin/Pulse" "$HOME/.local/bin/Pulse"
    chmod +x "$HOME/.local/bin/Pulse"
  fi

  # Update Hecate-Help app
  if [ -d "$HECATEAPPSDIR/Hecate-Help/build/bin" ] && [ -f "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings" ]; then
    gum style --foreground 82 "Updating Hecate Settings App..."
    sleep 2
    cp "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings" "$HOME/.local/bin/Hecate-Settings"
    chmod +x "$HOME/.local/bin/Hecate-Settings"
  fi

  # Update hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Updating hecate CLI..."
    cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
  fi

    if [ -d "$HECATEAPPSDIR/Aoiler/build/bin" ] && [ -f "$HECATEAPPSDIR/Aoiler/build/bin/Aoiler" ]; then
    gum style --foreground 120 "Installing Hecate Assistant..."
    sleep 2
    cp "$HECATEAPPSDIR/Hecate-Help/build/bin/Aoiler" "$HOME/.local/bin/Aoiler"
    chmod +x "$HOME/.local/bin/Aoiler"
  fi

  gum style --foreground 82 "✓ Configuration files updated successfully!"
}

# Update Hecate config file with new version
update_hecate_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Updating Hecate Configuration"
  local update_date=$(date +%Y-%m-%d)
  set_config_value "version" "$remote_version"
  set_config_value "last_update" "$update_date"

  gum style --foreground 82 "✓ Hecate config updated"
  gum style --foreground 82 "  Version: $remote_version"
  gum style --foreground 82 "  Date: $update_date"
}

setup_waybar() {
  gum style --foreground 220 "Reconfiguring Waybar symlinks..."

  local WAYBAR_STYLE_SYMLINK="$HOME/.config/waybar/style.css"
  local WAYBAR_CONFIG_SYMLINK="$HOME/.config/waybar/config"
  local WAYBAR_COLOR_SYMLINK="$HOME/.config/waybar/color.css"
  local SWAYNC_COLOR_SYMLINK="$HOME/.config/swaync/color.css"

  # Remove existing symlinks
  [ -L "$WAYBAR_STYLE_SYMLINK" ] && rm -f "$WAYBAR_STYLE_SYMLINK"
  [ -L "$WAYBAR_CONFIG_SYMLINK" ] && rm -f "$WAYBAR_CONFIG_SYMLINK"
  [ -L "$WAYBAR_COLOR_SYMLINK" ] && rm -f "$WAYBAR_COLOR_SYMLINK"
  [ -L "$SWAYNC_COLOR_SYMLINK" ] && rm -f "$SWAYNC_COLOR_SYMLINK"

  # Create new symlinks
  ln -sf "$HOME/.config/waybar/style/default.css" "$WAYBAR_STYLE_SYMLINK"
  ln -sf "$HOME/.config/waybar/configs/top" "$WAYBAR_CONFIG_SYMLINK"
  ln -sf "$HOME/.config/hecate/hecate.css" "$WAYBAR_COLOR_SYMLINK"
  ln -sf "$HOME/.config/hecate/hecate.css" "$SWAYNC_COLOR_SYMLINK"

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
  install_config
  echo ""
  update_hecate_config
  echo ""
  setup_waybar
  echo ""
  post_update

  # Show completion
  show_completion_message

  # Clean up cloned repository
  rm -rf "$HECATEDIR"
}

# Run main function
main

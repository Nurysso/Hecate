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
  gum style --foreground 220 "     ~/.config/Hecate-backup/config-[timestamp]"
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
    if gum confirm "Hecate directory already exists. move it to backup if you made any changes if not "; then
      mv "$HECATEDIR" "$CONFIGDIR/Hecate-backup/hecate-$timestamp"
    else
      exit 0
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

# Backup existing config
backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Creating Backup"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="$CONFIGDIR/Hecate-backup/config-$timestamp"

  mkdir -p "$backup_dir"

  local USER_SHELL=$(get_config_value "shell")

  # Backup main Hecate configs
  local configs=("hypr" "waybar" "rofi" "swaync" "wlogout" "hecate" "fastfetch" "quickshell" "waypaper" "wallust")

  for config in "${configs[@]}"; do
    if [ -d "$CONFIGDIR/$config" ]; then
      gum style --foreground 220 "Backing up: $config"
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
      cp "$HOME/.zshrc" "$backup_dir/.zshrc"
    fi
    ;;
  bash)
    if [ -f "$HOME/.bashrc" ]; then
      gum style --foreground 220 "Backing up: .bashrc"
      cp "$HOME/.bashrc" "$backup_dir/.bashrc"
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
    cp "$HOME/.config/starship.toml" "$backup_dir/"
  fi

  gum style --foreground 82 --bold "✓ Backup created at:"
  gum style --foreground 82 "  $backup_dir"
  echo "$backup_dir" >"$HOME/.config/hecate_last_backup.txt"

  echo ""
  gum style --foreground 220 "💡 Tip: Save this path to restore custom changes later!"
  sleep 2
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
          # rm -rf "$CONFIGDIR/$folder_name"
          cp -rT "$folder" "$CONFIGDIR/"
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
        # rm -rf "$CONFIGDIR/$folder_name"
        cp -rT "$folder" "$CONFIGDIR/"
        ;;
      esac
    fi
  done

  # Install apps from apps directory
  if [ -d "$HECATEAPPSDIR/Pulse/build/bin" ]; then
    gum style --foreground 82 "Installing Pulse..."
    if [ -f "$HECATEAPPSDIR/Pulse/build/bin/Pulse" ]; then
      rm -f "$HOME/.local/bin/Pulse"
      cp "$HECATEAPPSDIR/Pulse/build/bin/Pulse" "$HOME/.local/bin/Pulse"
      chmod +x "$HOME/.local/bin/Pulse"
      gum style --foreground 82 "✓ Pulse installed to ~/.local/bin/Pulse"
    else
      gum style --foreground 220 "⚠ Pulse binary not found at expected location"
    fi
  else
    gum style --foreground 220 "⚠ Pulse build directory not found"
  fi
  if [ -d "$HECATEAPPSDIR/Hecate-Help/build/bin" ]; then
    gum style --foreground 82 "Installing Hecate-Help..."
    if [ -f "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Help" ]; then
      rm -f "$HOME/.local/bin/Hecate-Help"
      cp "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Help" "$HOME/.local/bin/Hecate-Help"
      chmod +x "$HOME/.local/bin/Hecate-Help"
      gum style --foreground 82 "✓ Hecate-Help installed to ~/.local/bin/Pulse"
    else
      gum style --foreground 220 "⚠ Hecate-Help binary not found at expected location"
    fi
  else
    gum style --foreground 220 "⚠ Hecate-Help build directory not found"
  fi

  # Install hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Installing hecate CLI tool..."
    rm -f "$HOME/.local/bin/hecate"
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


# Install updated config files
install_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Updated Configuration"

  USER_TERMINAL=$(get_config_value "term")
  USER_SHELL=$(get_config_value "shell")

  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "Error: Config directory not found!"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  for folder in "$HECATEDIR/config"/*; do
    folder_name=$(basename "$folder")

    # Skip the 'hecate' directory entirely
    [ "$folder_name" = "hecate" ] && continue

    if [ -d "$folder" ]; then
      case "$folder_name" in
      alacritty | foot | ghostty | kitty)
        if [ "$folder_name" = "$USER_TERMINAL" ]; then
          gum style --foreground 82 "Updating $folder_name config..."
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
      *)
        gum style --foreground 82 "Updating $folder_name..."
        mkdir -p "$CONFIGDIR/$folder_name"
        cp -rf "$folder/"* "$CONFIGDIR/$folder_name/"
        ;;
      esac
    fi
  done

  # Update Pulse app
  if [ -d "$HECATEAPPSDIR/Pulse/build/bin" ] && [ -f "$HECATEAPPSDIR/Pulse/build/bin/Pulse" ]; then
    gum style --foreground 82 "Updating Pulse..."
    cp "$HECATEAPPSDIR/Pulse/build/bin/Pulse" "$HOME/.local/bin/Pulse"
    chmod +x "$HOME/.local/bin/Pulse"
  fi

  # Update Hecate-Help app
  if [ -d "$HECATEAPPSDIR/Hecate-Help/build/bin" ] && [ -f "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Help" ]; then
    gum style --foreground 82 "Updating Hecate-Help..."
    cp "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Help" "$HOME/.local/bin/Hecate-Help"
    chmod +x "$HOME/.local/bin/Hecate-Help"
  fi

  # Update hecate CLI tool
  if [ -f "$HECATEDIR/config/hecate.sh" ]; then
    gum style --foreground 82 "Updating hecate CLI..."
    cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
  fi

  # Update Starship config
  if [ -f "$HECATEDIR/config/starship/starship.toml" ]; then
    gum style --foreground 82 "Updating Starship config..."
    cp "$HECATEDIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
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
  local backup_path=$(cat "$HOME/.config/hecate_last_backup.txt" 2>/dev/null || echo "")

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
  #   gum style --foreground 82 "   3. Or use: diff -r $backup_path ~/.config/[app]"
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
  backup_config
  echo ""
  clone_dotfiles
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
  rm -rf $HECATEDIR
}

# Run main function
main

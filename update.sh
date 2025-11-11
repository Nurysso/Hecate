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

# Backup existing config
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

  # Backup hecate.toml
  if [ -f "$CONFIG_FILE" ]; then
    gum style --foreground 220 "Backing up: hecate.toml"
    mkdir -p "$backup_dir/hecate"
    cp "$CONFIG_FILE" "$backup_dir/hecate/"
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

# Install updated config files
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

  if [ -d "$HECATEAPPSDIR/Hecate-Help/build/bin" ]; then
    gum style --foreground 82 "Installing Hecate Settings Apps..."
    sleep 1
    if [ -f "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings" ]; then
      cp "$HECATEAPPSDIR/Hecate-Help/build/bin/Hecate-Settings" "$HOME/.local/bin/Hecate-Settings"
      chmod +x "$HOME/.local/bin/Hecate-Settings"
      gum style --foreground 82 "✓ Hecate Settings Apps installed to ~/.local/bin"
    else
      gum style --foreground 220 "⚠ Hecate-Settings binary not found at expected location"
    fi
  else
    gum style --foreground 220 "⚠ Hecate-Settings build directory not found"
  fi

  if [ -d "$HECATEAPPSDIR/Aoiler/build/bin" ]; then
    gum style --foreground 120 "Installing Hecate Assistant..."
    sleep 1
    if [ -f "$HECATEAPPSDIR/Aoiler/build/bin/Aoiler" ]; then
      cp "$HECATEAPPSDIR/Aoiler/build/bin/Aoiler" "$HOME/.local/bin/Aoiler"
      chmod +x "$HOME/.local/bin/Aoiler"
      gum style --foreground 82 "✓ Assistant installed to ~/.local/bin"
    else
      gum style --foreground 220 "⚠ Assistant binary not found at expected location"
    fi
  else
    gum style --foreground 220 "⚠ Assistant build directory not found"
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

  if [ -f "$HECATEDIR/config/zsh" ]; then
    cp "$HECATEDIR/config/zsh" "$HOME/.zshrc"
    gum style --foreground 82 "✓ ZSH config installed"
  else
    gum style --foreground 220 "⚠ zshrc config not found in config directory"
  fi

  if [ -f "$HECATEDIR/config/bash" ]; then
    cp "$HECATEDIR/config/bash" "$HOME/.bashrc"
    gum style --foreground 82 "✓ BASH config installed"
  else
    gum style --foreground 220 "⚠ bashrc config not found in config directory"
  fi

  gum style --foreground 82 "✓ Configuration files installed successfully!"
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

# Setup Waybar and links system colors
setup_Waybar() {
  gum style --foreground 220 "Configuring waybar..."

  # Define the symlink paths
  WAYBAR_STYLE_SYMLINK="$HOME/.config/waybar/style.css"
  WAYBAR_CONFIG_SYMLINK="$HOME/.config/waybar/config"
  WAYBAR_COLOR_SYMLINK="$HOME/.config/waybar/color.css"
  SWAYNC_COLOR_SYMLINK="$HOME/.config/swaync/color.css"
  STATSHIP_SHYMLINK="$HOME/.config/starship.toml"
  # Remove existing symlinks if they exist
  [ -L "$WAYBAR_STYLE_SYMLINK" ] && rm -f "$WAYBAR_STYLE_SYMLINK"
  [ -L "$WAYBAR_CONFIG_SYMLINK" ] && rm -f "$WAYBAR_CONFIG_SYMLINK"
  [ -L "$WAYBAR_COLOR_SYMLINK" ] && rm -f "$WAYBAR_COLOR_SYMLINK"
  [ -L "$SWAYNC_COLOR_SYMLINK" ] && rm -f "$SWAYNC_COLOR_SYMLINK"
  [ -L "$STARSHIP_SYMLINK" ] && rm -f "$STARSHIP_SYMLINK"

  # Create new symlinks
  ln -s "$HOME/.config/waybar/style/default.css" "$WAYBAR_STYLE_SYMLINK"
  ln -s "$HOME/.config/waybar/configs/top" "$WAYBAR_CONFIG_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$WAYBAR_COLOR_SYMLINK"
  ln -s "$HOME/.config/hecate/hecate.css" "$SWAYNC_COLOR_SYMLINK"
  ln -s "$HOME/.config/starship/starship.toml" "$STATSHIP_SHYMLINK"

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

install_extra_tools() {
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

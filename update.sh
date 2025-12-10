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
REPO_URL="https://github.com/nurysso/Hecate.git"
FREYA_URL="https://github.com/nurysso/freya.git"
CONFIG_FILE="$HOME/.config/hecate/hecate.toml"
VERSION_FILE="$HECATEDIR/version.txt"

# Use tte if available, otherwise fallback to echo
fancy_echo() {
  local text="$1"
  local effect="${2:-slide}"

  if command -v tte &>/dev/null; then
    echo "$text" | tte "$effect" --movement-speed 2 2>/dev/null || echo "$text"
  else
    echo "$text"
  fi
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
  remote_version=$(curl -s "https://raw.githubusercontent.com/nurysso/Hecate/main/version.txt" 2>/dev/null || echo "")
  if [ -z "$remote_version" ]; then
    gum style --foreground 196 "❌ Failed to fetch remote version"
    gum style --foreground 220 "Check your internet connection"
    exit 1
  fi

  # Extract numeric versions (remove any suffix like "shy eagle")
  local_numeric=$(echo "$current_version" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
  remote_numeric=$(echo "$remote_version" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')

  gum style --foreground 62 "Current version: ${current_version}"
  gum style --foreground 82 "Latest version:  $remote_version"

  # Compare versions using sort -V (version sort)
  if [ "$local_numeric" = "$remote_numeric" ]; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi

  # Check if local is newer than remote (shouldn't happen, but handle it)
  if printf '%s\n' "$remote_numeric" "$local_numeric" | sort -V -C; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi

  # If we get here, update is available
  gum style --foreground 220 "🔄 Update available!"
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
    echo "Installing hecate script..." "slide"
    cp "$scripts_dir/hecate.sh" "$HOME/.local/bin/hecate"
    chmod +x "$HOME/.local/bin/hecate"
    echo "✓ hecate installed to ~/.local/bin/hecate" "slide"
  else
    gum style --foreground 220 "⚠ hecate.sh not found at $scripts_dir/hecate.sh"
  fi

  # Install freya.sh
  if [ -f "$scripts_dir/file_convert.sh" ]; then
    echo "Installing freya script..." "slide"
    cp "$scripts_dir/file_convert.sh" "$HOME/.local/bin/file_convert"
    chmod +x "$HOME/.local/bin/file_convert"
    echo "✓ freya installed to ~/.local/bin/file_convert" "slide"
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

#   mkdir -p "$CONFIGDIR"
#   mkdir -p "$HOME/.local/bin"

  # only moves specific files/directories
run cp -T "$HECATEDIR/config/quickshell/widgets/SystemInfoWidget.qml" "$HOME/.config/quickshell/widgets/SystemInfoWidget.qml"
run cp -T "$HECATEDIR/config/waybar/configs/left" "$HOME/.config/waybar/configs/left"
run cp -T "$HECATEDIR/config/waybar/configs/right" "$HOME/.config/waybar/configs/right"
run rm -f "$HOME/.config/waybar/configs/side"
#   for item in "$HECATEDIR/config"/*; do
#     if [ -d "$item" ]; then
#       local item_name=$(basename "$item")

#       # Skip local-bin directory (handled separately)
#       if [ "$item_name" = "local-bin" ]; then
#         continue
#       fi

#       # Handle terminal configs - only install selected terminal
#       case "$item_name" in
#         alacritty|foot|ghostty|kitty)
#           if [ "$item_name" = "$USER_TERMINAL" ]; then
#             fancy_echo "Installing $item_name config..." "slide"
#             cp -rT "$item" "$CONFIGDIR/$item_name"
#           fi
#           ;;
#         *)
#           # Install all other configs
#           fancy_echo "Installing $item_name..." "slide"
#           cp -rT "$item" "$CONFIGDIR/$item_name"
#           ;;
#       esac
#     fi
#   done

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

  if [ "$backed_up" = true ]; then
    echo ""
    fancy_echo "✓ Backup created at: $backup_dir" "beams"
    echo "$backup_dir" > "$HOME/.cache/hecate_last_backup.txt"
  else
    gum style --foreground 220 "No existing configs found to backup"
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

install_extra_tools(){
  gum style \
    --foreground 212 --border-foreground 212 \
    --align center \
    'Installing Aoiler helper Tyr' 'used to organize dirs'
    curl -fsSL https://raw.githubusercontent.com/nurysso/tyr/main/install.sh | bash
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
    local lock_screen_url="https://raw.githubusercontent.com/nurysso/Freya/main/walls/hecate-default/lock-screen.png"
    local wallpaper_url="https://raw.githubusercontent.com/nurysso/Freya/main/walls/hecate-default/wallpaper.png"
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
  check_dependencies
  check_hecate_installed
  detect_os

  echo ""

  # Read user configuration
  read_user_config

  echo ""
  # Check versions and get confirmation
  check_versions

  echo ""
#   show_update_warning
  # Perform update
  clone_dotfiles
  backup_config
#   verify_critical_packages_installed
  move_config
  update_hecate_config
  setup_Waybar
  install_extra_tools
  setup_wallpapers

  # Show completion
  show_completion_message

  # Clean up cloned repository
  rm -rf "$HECATEDIR"
}

# Run main function
main

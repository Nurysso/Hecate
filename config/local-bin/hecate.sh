#!/bin/bash

# Hecate Dotfiles Manager
# Manages updates, configuration, and theme settings

set -e

CONFIG_FILE="$HOME/.config/hecate/hecate.toml"
HECATE_DIR="$HOME/Hecate"
REPO_URL="https://github.com/Nurysso/Hecate.git"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/Nurysso/Hecate/main/update.sh"

# Ensure config directory exists
mkdir -p "$HOME/.config/hecate"

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo "Error: gum is not installed!"
  echo "How did you even get here without gum?"
  exit 1
fi

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
  gum style --foreground 196 "Error: Hecate config not found!"
  gum style --foreground 220 "Did you forget to run the installer?"
  gum style --foreground 220 "Or did you rm -rf the wrong directory again?"
  exit 1
fi

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
      current_section == section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\"?", "")
        sub("\"?[[:space:]]*(#.*)?$", "")
        print
        exit
      }
    ' "$CONFIG_FILE"
  else
    # Legacy: try to find key anywhere (backwards compatibility)
    awk -v key="$key" '
      $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\"?", "")
        sub("\"?[[:space:]]*(#.*)?$", "")
        print
        exit
      }
    ' "$CONFIG_FILE"
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
    current_section == section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      print key " = \"" value "\""
      next
    }
    { print }
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

# Get current version
get_current_version() {
  get_config_value "version" "metadata"
}

# Get remote version
get_remote_version() {
  local remote_version=$(curl -s "https://raw.githubusercontent.com/Nurysso/Hecate/main/version.txt" 2>/dev/null || echo "")
  echo "$remote_version"
}

# Send notification
send_notification() {
  local title="$1"
  local message="$2"
  local urgency="${3:-normal}"

  if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    notify-send "$title" "$message" -u "$urgency" -t 5000
  fi
}

# Check network connectivity
check_network() {
  local silent="${1:-false}"

  if [ "$silent" = "false" ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Network Status Check"
    gum spin --spinner dot --title "Pinging the void..." -- sleep 1
  fi

  # Try multiple methods to check connectivity
  if ping -c 1 -W 2 8.8.8.8 &>/dev/null ||
    ping -c 1 -W 2 1.1.1.1 &>/dev/null ||
    curl -s --max-time 3 https://www.google.com &>/dev/null; then

    if [ "$silent" = "false" ]; then
      gum style --foreground 82 "✓ Network connected"
      gum style --foreground 220 "The internet still exists. What a time to be alive."
      send_notification "✓ Network Connected" "Ohh internet still up WoW..." "low"
    fi
    return 0
  else
    if [ "$silent" = "false" ]; then
      gum style --foreground 196 "✗ No network connection"
      gum style --foreground 220 "Did you try unplugging it and plugging it back in?"
      gum style --foreground 220 "Or did your ISP finally give up on you?"
      send_notification "✗ No connection" "wanna touch grass?" "critical"
    fi
    return 1
  fi
}

change_lock(){
    ~/.config/hypr/scripts/hyprlock.sh
}
# Check for updates
check_updates() {
  local mode="${1:-normal}"

  if [ "$mode" = "normal" ]; then
    gum style --border double --padding "1 2" --border-foreground 212 "Checking for Updates"
    gum spin --spinner moon --title "Consulting the GitHub oracles..." -- sleep 1
  fi

  local current_version=$(get_current_version)
  local remote_version=$(get_remote_version)

  if [ -z "$remote_version" ]; then
    gum style --foreground 196 "⚠ Unable to check for updates"
    gum style --foreground 220 "GitHub is either down or plotting against you"
    gum style --foreground 220 "Check back when the servers wake up"
    send_notification "Hecate Update Check" "Failed to reach GitHub (skill issue?)" "normal"
    return 1
  fi

  if [ "$mode" = "normal" ]; then
    gum style --foreground 220 "Current version: $current_version"
    gum style --foreground 220 "Latest version:  $remote_version"
    echo ""
  fi

  # Extract just version numbers for comparison (ignore stage names like "blind owl")
  local current_num=$(echo "$current_version" | awk '{print $1}')
  local remote_num=$(echo "$remote_version" | awk '{print $1}')

  if [ "$current_num" != "$remote_num" ]; then
    if [ "$mode" = "normal" ]; then
      gum style \
        --foreground 82 --border-foreground 82 --border double \
        --align center --width 50 --margin "1 2" --padding "1 2" \
        '🎉 NEW VERSION AVAILABLE!' \
        '' \
        "v$remote_version is here" \
        "(and it's probably breaking changes)"

      gum style --foreground 220 "Run: hecate update"
      gum style --foreground 220 "Or stay on $current_version and pretend nothing happened"
    fi

    send_notification "Hecate Update Available" \
      "v$remote_version dropped!\n\nYour config files are about to become outdated\nRun: hecate update" \
      "normal"
    return 0
  else
    if [ "$mode" = "normal" ]; then
      gum style --foreground 82 "✓ You're on the latest version!"
      gum style --foreground 220 "No updates found. You can go back to ricing now."
    fi
    send_notification "Hecate Update Check" "Already on latest version. Nothing to do here." "low"
    return 1
  fi
}

# Startup check (network + updates)
startup_check() {
  local local_version remote_data remote_version remote_stage

  local_version=$(get_current_version)

  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 55 --margin "1 2" --padding "1 2" \
    'HECATE STARTUP CHECK' \
    "Local Version: $local_version" \
    "Connecting to GitHub for remote info..."

  remote_data=$(curl -fsSL --max-time 3 "https://raw.githubusercontent.com/Nurysso/Hecate/main/version.txt" 2>/dev/null)

  if [ -n "$remote_data" ]; then
    # Extract version number and stage
    remote_version=$(echo "$remote_data" | awk '{print $1}')
    remote_stage=$(echo "$remote_data" | cut -d' ' -f2-)

    send_notification "✓ Network Connected" "Ohh internet still up WoW..." "low"
    sleep 2

    local local_num=$(echo "$local_version" | awk '{print $1}')
    local local_stage=$(echo "$local_version" | cut -d' ' -f2-)

    if [ "$remote_version" != "$local_num" ]; then
      # Check if remote > local using version comparison
      if printf '%s\n%s\n' "$remote_version" "$local_num" | sort -V | head -n1 | grep -q "^$local_num$"; then
        gum style --foreground 82 --border double --border-foreground 82 \
          --align center --width 60 --margin "1 2" --padding "1 2" \
          "🎉 NEW VERSION AVAILABLE!" \
          "Remote: $remote_data" \
          "Local:  $local_version" \
          "" \
          "Run: hecate update"

        send_notification "Hecate Update Available" \
          "New version detected!\nRemote: $remote_data\nLocal: $local_version\nRun: hecate update" "critical"
      else
        gum style --foreground 196 --border double --border-foreground 196 \
          --align center --width 60 --margin "1 2" --padding "1 2" \
          "⚠️ LOCAL VERSION AHEAD" \
          "Local:  $local_version" \
          "Remote: $remote_data" \
          "" \
          "You might be running a dev build."

        send_notification "Hecate Version Mismatch" \
          "⚠️ Local version ($local_version) is ahead of remote ($remote_data)\nPossible dev or wrong branch." "critical"
      fi
    else
      gum style --foreground 82 "✓ Already on the latest version ($local_version)"
    fi
  else
    gum style --foreground 196 "✗ No internet connection or GitHub unreachable"
    gum style --foreground 220 "Skipping update check (offline mode)"
    send_notification "✗ No connection" "wanna touch grass?" "critical"
  fi
}

# Update Hecate using update.sh from GitHub
update_hecate() {
  # Check network first
  if ! check_network "true"; then
    gum style --foreground 196 "✗ Cannot update: No network connection"
    gum style --foreground 220 "Can't update without internet. That's just science."
    send_notification "Hecate Update Failed" "No network = no update. Pretty simple." "critical"
    exit 1
  fi

  # Download update.sh
  local update_script="/tmp/hecate-update.sh"

  gum spin --spinner dot --title "Downloading update script from the cloud..." -- \
    curl -fsSL "$UPDATE_SCRIPT_URL" -o "$update_script"

  if [ -f "$update_script" ]; then
    chmod +x "$update_script"
    gum style --foreground 82 "✓ Update script acquired"
    gum style --foreground 220 "About to run mystery code from the internet"
    gum style --foreground 220 "What could possibly go wrong?"
    echo ""

    sleep 1

    # Run update script
    gum style --foreground 220 "Running update script..."
    bash "$update_script"

    # Clean up
    rm -f "$update_script"

    # Get new version after update
    local new_version=$(get_current_version)

    echo ""
    gum style \
      --foreground 82 --border-foreground 82 --border double \
      --align center --width 50 --margin "1 2" --padding "2 4" \
      '✓ UPDATE COMPLETE!' \
      '' \
      'Your configs are now 0.1% better' \
      'Or worse. Who knows?'

    send_notification "Hecate Updated" \
      "Successfully updated to v$new_version\n\nTime to find all the new bugs!" \
      "normal"
  else
    gum style --foreground 196 "✗ Failed to download update script"
    gum style --foreground 220 "GitHub refused our download request"
    gum style --foreground 220 "Maybe they know something we don't"
    send_notification "Hecate Update Failed" "Couldn't download update. Try again later?" "critical"
    exit 1
  fi
}

# Toggle theme mode
toggle_theme() {
  local current_mode=$(get_config_value "mode" "theme")

  gum style --border double --padding "1 2" --border-foreground 212 "Theme Mode Toggle"
  gum style --foreground 220 "Current mode: $current_mode"
  echo ""

  if [ "$current_mode" = "dynamic" ]; then
    gum spin --spinner dot --title "Switching to static mode..." -- sleep 1
    set_config_value "mode" "static" "theme"

    gum style --foreground 82 "✓ Theme mode: STATIC"
    gum style --foreground 220 "Colors will now stay the same forever"
    gum style --foreground 220 "Like a relationship that's lost its spark"

    send_notification "Hecate Theme Changed" \
      "Mode: Static\n\nYour colors are now commitment-phobic" \
      "normal"
  else
    gum spin --spinner dot --title "Switching to dynamic mode..." -- sleep 1
    set_config_value "mode" "dynamic" "theme"

    gum style --foreground 82 "✓ Theme mode: DYNAMIC"
    gum style --foreground 220 "Colors will now change with every wallpaper"
    gum style --foreground 220 "Prepare for constant visual chaos"

    send_notification "Hecate Theme Changed" \
      "Mode: Dynamic\n\nYour wallpaper now controls your entire aesthetic" \
      "normal"
  fi
}

# Show info
show_info() {
  local version=$(get_config_value "version" "metadata")
  local install_date=$(get_config_value "install_date" "metadata")
  local last_update=$(get_config_value "last_update" "metadata")
  local theme_mode=$(get_config_value "mode" "theme")
  local terminal=$(get_config_value "term" "preferences")
  local shell=$(get_config_value "shell" "preferences")
  local browser=$(get_config_value "browser" "preferences")
  local profile=$(get_config_value "profile" "preferences")

  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    'HECATE INFO'
  echo ""
  gum style --foreground 82 --bold "System Information:"
  gum style --foreground 220 "  Version:        $version"
  gum style --foreground 220 "  Installed:      $install_date"
  gum style --foreground 220 "  Last Update:    $last_update"
  gum style --foreground 220 "  Theme Mode:     $theme_mode"

  echo ""
  gum style --foreground 82 --bold "Your Choices (for better or worse):"
  gum style --foreground 220 "  Terminal:       $terminal"
  gum style --foreground 220 "  Shell:          $shell"
  gum style --foreground 220 "  Browser:        $browser"
  gum style --foreground 220 "  Profile:        $profile"

  echo ""
  gum style --foreground 82 --bold "Available Commands:"
  gum style --foreground 220 "  hecate check      Check for updates"
  gum style --foreground 220 "  hecate update     Update dotfiles"
  gum style --foreground 220 "  hecate theme      Toggle theme mode"
  gum style --foreground 220 "  hecate network    Check network"
}

# Show help
show_help() {
  gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    'HECATE DOTFILES HELPER'
  echo ""
  gum style --foreground 82 --bold "Usage:"
  gum style --foreground 220 "  hecate [command]"

  echo ""
  gum style --foreground 82 --bold "Commands:"
  gum style --foreground 220 "  startup     Run startup checks (network + updates)"
  gum style --foreground 220 "  network     Check if internet exists"
  gum style --foreground 220 "  check       Check for updates"
  gum style --foreground 220 "  update      Update dotfiles (scary)"
  gum style --foreground 220 "  theme       Toggle dynamic/static mode"
  gum style --foreground 220 "  info        Show installation info"
  gum style --foreground 220 "  term        Show configured terminal"
  gum style --foreground 220 "  lock        change hyprlock layout"
  gum style --foreground 220 "  help        You're reading it right now"

  echo ""
  gum style --foreground 82 --bold "Examples:"
  gum style --foreground 220 "  hecate startup    # Morning ritual"
  gum style --foreground 220 "  hecate check      # See if updates exist"
  gum style --foreground 220 "  hecate update     # YOLO"
  gum style --foreground 220 "  hecate theme      # Identity crisis mode"

  echo ""
  gum style --foreground 196 "Remember: With great config power comes great responsibility"
  gum style --foreground 196 "And probably some broken keybindings"
}

show_term() {
  # Use get_config_value to safely extract terminal from preferences section
  terminal=$(get_config_value "term" "preferences")

  # Fallback if terminal is empty
  if [ -z "$terminal" ]; then
    gum style --foreground 196 "Error: Terminal not configured"
    notify-send "Hecate Error" "Terminal preference not found in config" "critical"
    return 1
  fi

  echo "$terminal"
}

# Main command handler
case "${1:-help}" in
term)
  show_term
  ;;
startup)
  startup_check
  ;;
network)
  check_network "false"
  ;;
check)
  check_updates
  ;;
update)
  if check_updates; then
    echo ""
    if gum confirm "Actually run the update?"; then
      echo ""
      update_hecate
    else
      gum style --foreground 220 "Wise choice. Change is scary."
      send_notification "Hecate Update" "Update cancelled. Coward." "low"
    fi
  fi
  ;;
theme)
  toggle_theme
  ;;
info)
  show_info
  ;;
  lock)
  change_lock
  ;;
help | --help | -h)
  show_help
  ;;
*)
  gum style --foreground 196 "Unknown command: $1"
  gum style --foreground 220 "That's not a thing. Try 'hecate help'"
  echo ""
  show_help
  send_notification "Hecate Error" "Invalid command. RTFM." "critical"
  exit 1
  ;;
esac

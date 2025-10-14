#!/bin/bash
# Script to switch between master and dwindle layouts (Enhanced Version)
# This version includes all layout-specific keybindings
#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

set -euo pipefail

# Configuration
NOTIF_ICON="$HOME/.config/swaync/images/hecate.png"
ENABLE_LAYOUT_BINDINGS=true # Set to false to disable automatic keybinding changes

# Fallback icon if hecate.png doesn't exist
[[ ! -f "$NOTIF_ICON" ]] && NOTIF_ICON=""

# Get current layout
get_current_layout() {
  hyprctl -j getoption general:layout | jq -r '.str'
}

# Switch to dwindle layout
switch_to_dwindle() {
  echo "Switching to Dwindle layout..."
  hyprctl keyword general:layout dwindle

  if [[ "$ENABLE_LAYOUT_BINDINGS" == "true" ]]; then
    # Remove master-specific bindings
    hyprctl keyword unbind SUPER,J 2>/dev/null || true
    hyprctl keyword unbind SUPER,K 2>/dev/null || true
    hyprctl keyword unbind SUPER,I 2>/dev/null || true
    hyprctl keyword unbind SUPER_CTRL,D 2>/dev/null || true
    hyprctl keyword unbind SUPER_CTRL,Return 2>/dev/null || true

    # Add dwindle-specific bindings
    # Toggle split orientation
    hyprctl keyword bind SUPER_SHIFT,I,togglesplit

    # Pseudo-tiling
    hyprctl keyword bind SUPER,P,pseudo

    # Optional: Add J/K for window cycling in dwindle
    # hyprctl keyword bind SUPER,J,cyclenext
    # hyprctl keyword bind SUPER,K,cyclenext,prev
  fi

  if [[ -n "$NOTIF_ICON" ]]; then
    notify-send -e -u low -i "$NOTIF_ICON" "Layout Switched" "Dwindle Layout Active\nOptimal for floating-style workflow"
  else
    notify-send -e -u low "Layout Switched" "󰯌 Dwindle Layout Active"
  fi
}

# Switch to master layout
switch_to_master() {
  echo "Switching to Master layout..."
  hyprctl keyword general:layout master

  if [[ "$ENABLE_LAYOUT_BINDINGS" == "true" ]]; then
    # Remove dwindle-specific bindings
    hyprctl keyword unbind SUPER,J 2>/dev/null || true
    hyprctl keyword unbind SUPER,K 2>/dev/null || true
    hyprctl keyword unbind SUPER_SHIFT,I 2>/dev/null || true
    hyprctl keyword unbind SUPER,P 2>/dev/null || true

    # Add master-specific bindings
    # Cycle through windows
    hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
    hyprctl keyword bind SUPER,K,layoutmsg,cycleprev

    # Add/remove master windows
    hyprctl keyword bind SUPER,I,layoutmsg,addmaster
    hyprctl keyword bind SUPER_CTRL,D,layoutmsg,removemaster

    # Swap with master
    hyprctl keyword bind SUPER_CTRL,Return,layoutmsg,swapwithmaster

    # Change master orientation
    hyprctl keyword bind SUPER,M,layoutmsg,orientationcenter
  fi

  if [[ -n "$NOTIF_ICON" ]]; then
    notify-send -e -u low -i "$NOTIF_ICON" "Layout Switched" "Master Layout Active\nOptimal for tiling workflow"
  else
    notify-send -e -u low "Layout Switched" "󰯋 Master Layout Active"
  fi
}

# Show current layout info
show_layout_info() {
  local layout=$1
  local bindings=""

  case "$layout" in
  master)
    bindings="Master Layout Keybindings:
• SUPER+J/K - Cycle windows
• SUPER+I - Add master
• SUPER+CTRL+D - Remove master
• SUPER+CTRL+Return - Swap with master"
    ;;
  dwindle)
    bindings="Dwindle Layout Keybindings:
• SUPER+SHIFT+I - Toggle split
• SUPER+P - Pseudo-tiling"
    ;;
  esac

  if [[ "$ENABLE_LAYOUT_BINDINGS" == "true" ]] && [[ -n "$bindings" ]]; then
    echo "$bindings"
  fi
}

# Main execution
main() {
  local current_layout
  current_layout=$(get_current_layout)

  echo "Current layout: $current_layout"

  case "$current_layout" in
  master)
    switch_to_dwindle
    show_layout_info "dwindle"
    ;;
  dwindle)
    switch_to_master
    show_layout_info "master"
    ;;
  *)
    echo "Unknown layout: $current_layout"
    notify-send -e -u critical "Layout Error" "Unknown layout: $current_layout"
    exit 1
    ;;
  esac

  echo "Layout switch complete!"
}

main

#!/bin/bash
# Script for waybar styles

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

set -euo pipefail
IFS=$'\n\t'

# Directories
WAYBAR_STYLES="$HOME/.config/waybar/style"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
ROFI_CONFIG="$HOME/.config/rofi/config-waybar-style.rasi"
MSG='🎌 NOTE: Some waybar STYLES may not fully work with some LAYOUTS'
MARKER="✓"

# Check required directories
if [[ ! -d "$WAYBAR_STYLES" ]]; then
  notify-send -u critical "Waybar Styles" "Styles directory not found: $WAYBAR_STYLES"
  exit 1
fi

apply_style() {
  local style="$1"
  local style_path="$WAYBAR_STYLES/$style.css"

  if [[ ! -f "$style_path" ]]; then
    notify-send -u critical "Waybar Styles" "Style not found: $style"
    exit 1
  fi

  ln -sf "$style_path" "$WAYBAR_STYLE"

  if [[ -x "$SCRIPTSDIR/Refresh.sh" ]]; then
    "$SCRIPTSDIR/Refresh.sh" &
  else
    # Fallback: restart waybar manually
    pkill waybar || true
    waybar &
  fi
}

main() {
  # Get current style name (strip .css)
  local current_target current_name
  current_target=$(readlink -f "$WAYBAR_STYLE" 2>/dev/null || echo "")
  current_name=$(basename "$current_target" .css 2>/dev/null || echo "")

  # Get available styles
  local options=()
  mapfile -t options < <(
    find -L "$WAYBAR_STYLES" -maxdepth 1 -type f -name '*.css' \
      -exec basename {} .css \; 2>/dev/null | sort
  )

  if [[ ${#options[@]} -eq 0 ]]; then
    notify-send -u critical "Waybar Styles" "No styles found in $WAYBAR_STYLES"
    exit 1
  fi

  # Mark active style
  local default_row=0
  for i in "${!options[@]}"; do
    if [[ "${options[i]}" == "$current_name" ]]; then
      options[i]="$MARKER ${options[i]}"
      default_row=$i
      break
    fi
  done

  # Launch rofi menu
  local choice
  choice=$(
    printf '%s\n' "${options[@]}" |
      rofi -i -dmenu \
        -config "$ROFI_CONFIG" \
        -mesg "$MSG" \
        -selected-row "$default_row" \
        -p "Waybar Style"
  ) || {
    echo "No option selected. Exiting."
    exit 0
  }

  [[ -z "$choice" ]] && {
    echo "No option selected. Exiting."
    exit 0
  }

  # Remove marker
  choice="${choice#$MARKER }"

  apply_style "$choice"
  notify-send "Waybar Style" "Applied: $choice"
}

# Kill running rofi if needed
if pgrep -x rofi >/dev/null; then
  pkill rofi
  sleep 0.1
fi

main

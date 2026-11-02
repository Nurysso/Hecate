#!/bin/bash
# Screenshot script for Hyprland
# Requires: grim, slurp, wl-clipboard (wl-copy), jq, hyprctl, notify-send

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

set -euo pipefail

# [screenshot] dir in hecate.toml, ~ allowed; Pictures/Screenshots when unset
SAVE_DIR=$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1],"rb")).get("screenshot",{}).get("dir",""))' \
  "$HOME/.config/hecate/hecate.toml" 2>/dev/null || true)
SAVE_DIR="${SAVE_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
SAVE_DIR="${SAVE_DIR/#\~/$HOME}"
mkdir -p "$SAVE_DIR"

# ScreenShot-<focused window class>-mm-dd-hh-mm-ss.png; "Desktop" when nothing is focused
CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null || true)
CLASS=$(tr -c 'A-Za-z0-9._\n-' '_' <<<"${CLASS:-Desktop}")
TIMESTAMP=$(date +"%m-%d-%H-%M-%S")
FILE="$SAVE_DIR/ScreenShot-$CLASS-$TIMESTAMP.png"

# Argument: full | window | area
MODE="${1:-full}"

take_screenshot() {
  local mode="$1"
  local temp_file="$FILE"

  case "$mode" in
  full)
    grim "$temp_file"
    wl-copy <"$temp_file"
    notify-send -i "$temp_file" "Screenshot" "Fullscreen saved"
    ;;
  window)
    # Get active window geometry
    if ! WIN_GEOM=$(hyprctl activewindow -j 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'); then
      notify-send -u critical "Screenshot Error" "Could not get active window geometry"
      exit 1
    fi

    if [[ -z "$WIN_GEOM" ]] || [[ "$WIN_GEOM" == "null,null 0x0" ]]; then
      notify-send -u critical "Screenshot Error" "No active window found"
      exit 1
    fi

    grim -g "$WIN_GEOM" "$temp_file"
    wl-copy <"$temp_file"
    notify-send -i "$temp_file" "Screenshot" "Active window saved"
    ;;
  area)
    # Select area with slurp
    if ! AREA=$(slurp 2>/dev/null); then
      notify-send "Screenshot" "Area selection canceled"
      exit 0
    fi

    if [[ -z "$AREA" ]]; then
      exit 0
    fi

    grim -g "$AREA" "$temp_file"
    wl-copy <"$temp_file"
    notify-send -i "$temp_file" "Screenshot" "Area screenshot saved"
    ;;
  *)
    echo "Usage: $0 [full|window|area]"
    echo "  full   : Fullscreen screenshot"
    echo "  window : Active window screenshot"
    echo "  area   : Select area screenshot"
    exit 1
    ;;
  esac

  echo "$temp_file"
}

# Main execution
take_screenshot "$MODE"

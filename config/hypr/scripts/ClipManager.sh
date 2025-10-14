#!/bin/bash
# Clipboard Manager - Uses cliphist, rofi, and wl-copy

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

set -euo pipefail

# Configuration
ROFI_THEME="$HOME/.config/rofi/config-clipboard.rasi"
MSG="📋 Clipboard Manager | CTRL+DEL: Delete entry | ALT+DEL: Clear all"

# Check if cliphist is installed
if ! command -v cliphist >/dev/null 2>&1; then
  notify-send -u critical "Clipboard Manager" "cliphist not installed"
  exit 1
fi

# Kill existing rofi instance
pkill rofi 2>/dev/null || true

# Main loop
while true; do
  # Show clipboard history with rofi
  result=$(
    cliphist list | rofi -i -dmenu \
      -kb-custom-1 "Control-Delete" \
      -kb-custom-2 "Alt-Delete" \
      -config "$ROFI_THEME" \
      -mesg "$MSG" \
      -p "Clipboard"
  ) || exit_code=$?

  # Handle rofi exit codes
  case "${exit_code:-0}" in
  0) # Entry selected
    if [[ -n "$result" ]]; then
      cliphist decode <<<"$result" | wl-copy
      notify-send -t 2000 "📋 Copied to clipboard"
      exit 0
    fi
    ;;
  1) # Escape pressed
    exit 0
    ;;
  10) # CTRL+Delete - Delete entry
    if [[ -n "$result" ]]; then
      cliphist delete <<<"$result"
      notify-send -t 2000 "🗑️ Entry deleted"
    fi
    ;;
  11) # ALT+Delete - Wipe all
    if cliphist wipe; then
      notify-send -t 2000 "🧹 Clipboard cleared"
      exit 0
    fi
    ;;
  *) # Any other exit
    exit 0
    ;;
  esac
done

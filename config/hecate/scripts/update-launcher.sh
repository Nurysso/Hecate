#!/usr/bin/env sh
set -e

CONFIG="$HOME/.config/hecate/hecate.toml"
SCRIPT="$HOME/.config/hecate/scripts/install-updates.sh"

# Extract terminal preference safely
terminal=$(awk -F'=' '
  /^\[preferences\]/ { in_pref=1; next }
  /^\[/ { in_pref=0 }
  in_pref && $1 ~ /term/ {
    gsub(/"/, "", $2)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
    print $2
    exit
  }
' "$CONFIG")

if [ -z "$terminal" ]; then
  echo "Error: no terminal found in $CONFIG"
  exit 1
fi

# Choose correct command based on terminal
case "$terminal" in
kitty)
  exec kitty --class dotfiles-floating -e "$SCRIPT"
  ;;
alacritty)
  exec alacritty --class dotfiles-floating -e "$SCRIPT"
  ;;
foot)
  exec foot -T dotfiles-floating -e "$SCRIPT"
  ;;
ghostty)
  exec ghostty -e "$SCRIPT"
  ;;
*)
  echo "Unsupported terminal: $terminal"
  exit 1
  ;;
esac

#!/bin/bash
# Wallust Colors Generator
# Generates color schemes from current wallpaper (Hyprpaper)
# dosent work switched to pywall to update all the sytem colors
#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# Configuration
waypaper_history="$HOME/.config/waypaper/history.txt"
rofi_wallpaper="$HOME/.config/rofi/.current_wallpaper"
effects_wallpaper="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Get current focused monitor
current_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [[ -z "$current_monitor" ]]; then
  echo "Error: Could not detect focused monitor"
  exit 1
fi

echo "Current monitor: $current_monitor"

# Get wallpaper path from waypaper history
if [[ -f "$waypaper_history" ]]; then
  # Try to get wallpaper for specific monitor first
  wallpaper_path=$(grep "$current_monitor" "$waypaper_history" | tail -n 1 | awk '{print $2}')

  # If not found, get the last wallpaper set
  if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path=$(tail -n 1 "$waypaper_history" | awk '{print $2}')
  fi
else
  echo "Error: Waypaper history file not found"
  exit 1
fi

if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
  echo "Error: Wallpaper not found: $wallpaper_path"
  exit 1
fi

echo "Wallpaper: $wallpaper_path"

# Create symlink for Rofi
if ln -sf "$wallpaper_path" "$rofi_wallpaper"; then
  echo "✓ Rofi wallpaper symlink created"
else
  echo "Error: Failed to create Rofi symlink"
  exit 1
fi

# Copy wallpaper for effects
if cp "$wallpaper_path" "$effects_wallpaper"; then
  echo "✓ Effects wallpaper copied"
else
  echo "Warning: Failed to copy wallpaper for effects"
fi

# Execute wallust
echo "Executing wallust..."
wallust run "$wallpaper_path" -s &

echo "✓ Color scheme generation started"

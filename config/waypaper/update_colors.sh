#!/usr/bin/env bash
#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|


CONFIG="$HOME/.config/waypaper/config.ini"
COLOR_CACHE="$HOME/.cache/wal/colors.json"

# Extract wallpaper path
WP_PATH=$(grep '^wallpaper' "$CONFIG" | cut -d '=' -f2 | tr -d ' ')
WP_PATH="${WP_PATH/#\~/$HOME}"

if [ ! -f "$WP_PATH" ]; then
    echo "Error: Wallpaper not found at $WP_PATH"
    exit 1
fi

echo "Wallpaper changed to: $WP_PATH"
echo "Generating color scheme..."

# Ensure cache directory exists
mkdir -p "$HOME/.cache/wal"

# Try running wal - using wal backend (default, most compatible)
# You can also try: --backend colorthief, schemer2, or haishoku
# -n flag prevents terminal theme changes, so "Remote control is disabled" is expected
if ! wal -n -i "$WP_PATH" -q -t -s 2>&1 | grep -v "Remote control is disabled" | tee /tmp/wal_error.log; then
    # Check if there were actual errors (not just the remote control warning)
    if grep -qv "Remote control is disabled" /tmp/wal_error.log 2>/dev/null; then
        echo "Error: wal command failed. Check /tmp/wal_error.log for details"
        cat /tmp/wal_error.log
        exit 1
    fi
fi

# Wait for wal to finish and verify colors.json exists
max_attempts=10
attempt=0
while [ ! -f "$COLOR_CACHE" ] && [ $attempt -lt $max_attempts ]; do
    sleep 0.2
    attempt=$((attempt + 1))
done

if [ ! -f "$COLOR_CACHE" ]; then
    echo "Error: Pywal failed to generate colors.json"
    echo "Last wal output:"
    cat /tmp/wal_error.log 2>/dev/null
    exit 1
fi

# Verify colors.json is valid JSON and has required fields
if ! jq -e '.special.background' "$COLOR_CACHE" > /dev/null 2>&1; then
    echo "Error: colors.json is invalid or incomplete"
    echo "Content:"
    cat "$COLOR_CACHE"
    exit 1
fi

echo "✓ Color scheme generated successfully"

# Small delay to ensure file is fully written
sleep 0.3

# Generate Rofi colors
echo "Updating Rofi theme..."
if ~/.config/rofi/generate_colors.sh; then
    notify-send "✓ Rofi colors updated"
else
    notify-send "✗ Rofi color update failed"
fi

# Generate SwayNC theme
echo "Updating SwayNC theme..."
if ~/.config/swaync/update_colors.sh; then
    notify-send "✓ SwayNC theme updated"
else
    notify-send "✗ SwayNC theme update failed"
fi

# Generate Waybar theme
echo "Updating Waybar theme..."
if ~/.config/waybar/update_colors.sh; then
    notify-send "✓ Waybar theme updated"
else
    notify-send "✗ Waybar theme update failed"
fi
echo "Updating Wlogout theme..."
if ~/.config/wlogout/update_colors.sh; then
    notify-send "✓ wlogout theme updated"
else
    notify-send "✗ wlogout theme update failed"
fi
echo ""
notify-send "✓ All themes updated successfully!"

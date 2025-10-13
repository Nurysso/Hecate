#!/bin/bash

# Waypaper Color Update Script
# Updates system-wide colors based on wallpaper
# Respects Hecate theme mode (dynamic/static)

CONFIG="$HOME/.config/waypaper/config.ini"
COLOR_CACHE="$HOME/.cache/wal/colors.json"
HECATE_CONFIG="$HOME/.config/hecate.toml"
HECATE_UPDATE_SCRIPT="$HOME/.config/hecate/scripts/update_hecate_colors.sh"

# Check theme mode from hecate.toml
get_theme_mode() {
    if [ -f "$HECATE_CONFIG" ]; then
        local mode=$(grep "^mode" "$HECATE_CONFIG" | cut -d '=' -f2 | tr -d ' "')
        echo "$mode"
    else
        echo "dynamic"  # Default to dynamic if config not found
    fi
}

THEME_MODE=$(get_theme_mode)

# If theme is static, exit without updating
if [ "$THEME_MODE" = "static" ]; then
    echo "Theme mode is set to static. Skipping color update."
    notify-send "Wallpaper Changed" "Theme mode: Static (colors not updated)" -u low
    exit 0
fi

# Extract wallpaper path
WP_PATH=$(grep '^wallpaper' "$CONFIG" | cut -d '=' -f2 | tr -d ' ')
WP_PATH="${WP_PATH/#\~/$HOME}"

if [ ! -f "$WP_PATH" ]; then
    echo "Error: Wallpaper not found at $WP_PATH"
    exit 1
fi

echo "Wallpaper changed to: $WP_PATH"
echo "Theme mode: $THEME_MODE - Generating color scheme..."

# Ensure cache directory exists
mkdir -p "$HOME/.cache/wal"

# Run pywal
if ! wal -n -i "$WP_PATH" -q -t -s 2>&1 | grep -v "Remote control is disabled" | tee /tmp/wal_error.log; then
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

# Verify colors.json is valid JSON
if ! jq -e '.special.background' "$COLOR_CACHE" > /dev/null 2>&1; then
    echo "Error: colors.json is invalid or incomplete"
    echo "Content:"
    cat "$COLOR_CACHE"
    exit 1
fi

echo "✓ Color scheme generated successfully"
sleep 0.3

# Run centralized color update script
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Updating Hecate Theme..."
echo "═══════════════════════════════════════════════════════════"

if [ -f "$HECATE_UPDATE_SCRIPT" ]; then
    if bash "$HECATE_UPDATE_SCRIPT"; then
        notify-send "✓ Hecate Theme Updated" "All components synced successfully!" -u normal
        exit 0
    else
        notify-send "✗ Theme Update Failed" "Check logs for details" -u critical
        exit 1
    fi
else
    echo "Error: Hecate update script not found at $HECATE_UPDATE_SCRIPT"
    echo "Expected location: $HECATE_UPDATE_SCRIPT"
    notify-send "✗ Theme Script Missing" "Cannot find update_hecate_colors.sh" -u critical
    exit 1
fi

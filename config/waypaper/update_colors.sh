#!/bin/bash

# Waypaper Color Update Script
# Updates system-wide colors based on wallpaper
# Respects Hecate theme mode (dynamic/static)

CONFIG="$HOME/.config/waypaper/config.ini"
COLOR_CACHE="$HOME/.cache/wal/colors.json"
HECATE_CONFIG="$HOME/.config/hecate.toml"

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

# Track update status
FAILED_UPDATES=()
SUCCESSFUL_UPDATES=()

# Generate Rofi colors
echo "Updating Rofi theme..."
if [ -f "$HOME/.config/rofi/generate_colors.sh" ]; then
    if ~/.config/rofi/generate_colors.sh; then
        SUCCESSFUL_UPDATES+=("Rofi")
    else
        FAILED_UPDATES+=("Rofi")
    fi
else
    echo "⚠ Rofi color script not found, skipping..."
fi

# Generate SwayNC theme
echo "Updating SwayNC theme..."
if [ -f "$HOME/.config/swaync/update_colors.sh" ]; then
    if ~/.config/swaync/update_colors.sh; then
        SUCCESSFUL_UPDATES+=("SwayNC")
    else
        FAILED_UPDATES+=("SwayNC")
    fi
else
    echo "⚠ SwayNC color script not found, skipping..."
fi

# Generate Waybar theme
echo "Updating Waybar theme..."
if [ -f "$HOME/.config/waybar/update_colors.sh" ]; then
    if ~/.config/waybar/update_colors.sh; then
        SUCCESSFUL_UPDATES+=("Waybar")
    else
        FAILED_UPDATES+=("Waybar")
    fi
else
    echo "⚠ Waybar color script not found, skipping..."
fi

# Generate Wlogout theme
echo "Updating Wlogout theme..."
if [ -f "$HOME/.config/wlogout/update_colors.sh" ]; then
    if ~/.config/wlogout/update_colors.sh; then
        SUCCESSFUL_UPDATES+=("Wlogout")
    else
        FAILED_UPDATES+=("Wlogout")
    fi
else
    echo "⚠ Wlogout color script not found, skipping..."
fi

# Summary
echo ""
echo "═══════════════════════════════════"
echo "Theme Update Summary"
echo "═══════════════════════════════════"

if [ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]; then
    echo "✓ Successfully updated:"
    printf '  • %s\n' "${SUCCESSFUL_UPDATES[@]}"
fi

if [ ${#FAILED_UPDATES[@]} -gt 0 ]; then
    echo "✗ Failed to update:"
    printf '  • %s\n' "${FAILED_UPDATES[@]}"
fi

echo "═══════════════════════════════════"

# Send notification
if [ ${#FAILED_UPDATES[@]} -eq 0 ]; then
    notify-send "✓ Theme Updated" "All components updated successfully!" -u normal
else
    notify-send "⚠ Theme Partially Updated" "${#SUCCESSFUL_UPDATES[@]} succeeded, ${#FAILED_UPDATES[@]} failed" -u normal
fi

echo ""
echo "✓ Color update complete!"

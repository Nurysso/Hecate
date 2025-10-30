#!/usr/bin/env bash
# Watch for changes in hyprlock.conf and auto-update Wallust + Hyprlock

CONFIG="$HOME/.config/hypr/hyprlock.conf"
WALL_DIR="$HOME/.config/hypr/wallpaper" # optional, if you also want to monitor wallpapers
LAST_WALL_PATH=""

echo "👀 Watching $CONFIG for background.path changes..."

# Function to extract background.path from hyprlock.conf
get_wall_path() {
    grep -E '^\s*path\s*=' "$CONFIG" | head -n 1 | cut -d '=' -f2- | xargs \
        | sed -e 's#\$wall#'"$WALL_DIR"'#g' -e "s#~#$HOME#g"
}

# Initialize current wallpaper path
LAST_WALL_PATH="$(get_wall_path)"
echo "🎨 Initial wallpaper: $LAST_WALL_PATH"

# Function to update colors + restart hyprlock
update_wall() {
    local new_path="$1"
    echo "🖼 Wallpaper changed: $new_path"
    wallust run "$new_path"
    pkill hyprlock && hyprlock &
}

# Start watching for changes in hyprlock.conf
inotifywait -m -e close_write,move,create "$CONFIG" | while read -r directory events file; do
    NEW_WALL_PATH="$(get_wall_path)"

    if [[ "$NEW_WALL_PATH" != "$LAST_WALL_PATH" && -n "$NEW_WALL_PATH" ]]; then
        update_wall "$NEW_WALL_PATH"
        LAST_WALL_PATH="$NEW_WALL_PATH"
    fi
done

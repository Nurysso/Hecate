#!/usr/bin/env bash
# Requires: gum

set -euo pipefail

SRC_DIR="$HOME/.config/hypr/hyprlock"
TARGET="$HOME/.config/hypr/hyprlock.conf"

# Collect usable layout files
mapfile -t FILES < <(find "$SRC_DIR" -maxdepth 1 -type f)

# Convert snake_case and camelCase → normal text
to_normal_text() {
    local name
    name="$(basename "$1")"
    name="${name%.*}"
    name="$(echo "$name" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1 \2/g')"
    name="${name//_/ }"
    echo "$name"
}

# Build display list for gum
declare -A MAP
DISPLAY_LIST=()
for f in "${FILES[@]}"; do
    readable="$(to_normal_text "$f")"
    DISPLAY_LIST+=("$readable")
    MAP["$readable"]="$f"
done

# Ask user to choose a layout
CHOICE="$(printf "%s\n" "${DISPLAY_LIST[@]}" | gum choose --header "Select Hyprlock layout")"

# Resolve original filename
SELECTED_FILE="${MAP[$CHOICE]}"

# Remove old symlink or file
[ -e "$TARGET" ] && rm -f "$TARGET"

# Create symlink directly to the chosen layout file
ln -s "$SELECTED_FILE" "$TARGET"

echo "Linked: $TARGET → $SELECTED_FILE"


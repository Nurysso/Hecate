#!/usr/bin/env bash

COLOR_FILE="$HOME/.cache/wal/colors.json"
CSS_OUTPUT="$HOME/.config/wlogout/color.css"
WALLPAPER_OUTPUT="$HOME/.cache/wlogout/blurred_wallpaper.png"

# Verify colors.json exists
if [ ! -f "$COLOR_FILE" ]; then
    echo "Error: wal colors.json not found at $COLOR_FILE"
    exit 1
fi

# Verify jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

# Extract colors
extract_color() {
    local key="$1"
    local value
    value=$(jq -r "$key" "$COLOR_FILE" 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "Error: Failed to extract $key"
        exit 1
    fi
    echo "$value"
}

# Extract all colors
COLOR0=$(extract_color '.colors.color0')
COLOR1=$(extract_color '.colors.color1')
COLOR2=$(extract_color '.colors.color2')
COLOR3=$(extract_color '.colors.color3')
COLOR4=$(extract_color '.colors.color4')
COLOR5=$(extract_color '.colors.color5')
COLOR6=$(extract_color '.colors.color6')
COLOR7=$(extract_color '.colors.color7')
COLOR8=$(extract_color '.colors.color8')
COLOR9=$(extract_color '.colors.color9')
COLOR10=$(extract_color '.colors.color10')
COLOR11=$(extract_color '.colors.color11')
COLOR12=$(extract_color '.colors.color12')
COLOR13=$(extract_color '.colors.color13')
COLOR14=$(extract_color '.colors.color14')
COLOR15=$(extract_color '.colors.color15')
BACKGROUND=$(extract_color '.special.background')
FOREGROUND=$(extract_color '.special.foreground')

# Create wlogout cache directory
mkdir -p "$HOME/.cache/wlogout"
mkdir -p "$(dirname "$CSS_OUTPUT")"

# Generate blurred wallpaper from current wallpaper
CONFIG="$HOME/.config/waypaper/config.ini"
if [ -f "$CONFIG" ]; then
    WP_PATH=$(grep '^wallpaper' "$CONFIG" | cut -d '=' -f2 | tr -d ' ')
    WP_PATH="${WP_PATH/#\~/$HOME}"

    if [ -f "$WP_PATH" ] && command -v convert &> /dev/null; then
        convert "$WP_PATH" -blur 0x10 -scale 1920x1080^ -gravity center -extent 1920x1080 "$WALLPAPER_OUTPUT" 2>/dev/null
        echo "✓ Generated blurred wallpaper"
    fi
fi

# Create backup
if [ -f "$CSS_OUTPUT" ]; then
    cp "$CSS_OUTPUT" "${CSS_OUTPUT}.backup"
fi

# Generate color.css with GTK color definitions
cat > "$CSS_OUTPUT" <<EOF
/* Wlogout Colors - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

@define-color background ${BACKGROUND};
@define-color foreground ${FOREGROUND};

@define-color color0  ${COLOR0};
@define-color color1  ${COLOR1};
@define-color color2  ${COLOR2};
@define-color color3  ${COLOR3};
@define-color color4  ${COLOR4};
@define-color color5  ${COLOR5};
@define-color color6  ${COLOR6};
@define-color color7  ${COLOR7};
@define-color color8  ${COLOR8};
@define-color color9  ${COLOR9};
@define-color color10 ${COLOR10};
@define-color color11 ${COLOR11};
@define-color color12 ${COLOR12};
@define-color color13 ${COLOR13};
@define-color color14 ${COLOR14};
@define-color color15 ${COLOR15};

/* Semantic color names for wlogout */
@define-color primary ${COLOR4};
@define-color secondary ${COLOR6};
@define-color accent ${COLOR5};
@define-color success ${COLOR2};
@define-color warning ${COLOR3};
@define-color error ${COLOR1};
EOF

echo "✓ Wlogout colors updated at $CSS_OUTPUT"
echo "✓ Primary color: $COLOR4"

# Optional: Recolor SVG icons if they exist
SVG_DIR="$HOME/.config/wlogout/icons"
if [ -d "$SVG_DIR" ] && command -v sed &> /dev/null; then
    echo "↻ Updating SVG icon colors..."
    for svg in "$SVG_DIR"/*.svg; do
        if [ -f "$svg" ]; then
            # Replace common fill colors with foreground color
            sed -i "s/fill=\"#[0-9a-fA-F]\{6\}\"/fill=\"${FOREGROUND}\"/g" "$svg"
            sed -i "s/stroke=\"#[0-9a-fA-F]\{6\}\"/stroke=\"${FOREGROUND}\"/g" "$svg"
        fi
    done
    echo "✓ SVG icons recolored"
fi

#!/usr/bin/env bash
# ⚠️ Script abandoned after v0.3.8 blind owl check out ~/.config/hecate/scripts/update_hecate_colors.sh
# Now Hecate uses a centeralize css file to add colors to waybar,rofi,wlogout,rofi
COLOR_FILE="$HOME/.cache/wal/colors.json"
OUTPUT_FILE="$HOME/.config/waybar/color.css"

# Verify colors.json exists and is readable
if [ ! -f "$COLOR_FILE" ]; then
    echo "Error: wal colors.json not found at $COLOR_FILE"
    exit 1
fi

# Verify jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

# Extract colors with error checking
extract_color() {
    local key="$1"
    local value
    value=$(jq -r "$key" "$COLOR_FILE" 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "Error: Failed to extract $key from colors.json"
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

# Convert hex to rgba function
hex_to_rgba() {
    local hex=$1
    local alpha=$2
    hex=${hex#"#"}

    if [ ${#hex} -ne 6 ]; then
        echo "Error: Invalid hex color: $hex"
        return 1
    fi

    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

# Generate RGBA colors
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.15")
COLOR4_RGBA_HOVER=$(hex_to_rgba "$COLOR4" "0.4")
COLOR4_RGBA_BORDER=$(hex_to_rgba "$COLOR4" "0.6")
COLOR1_RGBA=$(hex_to_rgba "$COLOR1" "0.4")
COLOR1_RGBA_BORDER=$(hex_to_rgba "$COLOR1" "0.6")
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.2")
BG_DARK=$(hex_to_rgba "$BACKGROUND" "0.5")

# Create backup
if [ -f "$OUTPUT_FILE" ]; then
    cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
fi

# Generate the color.css file
cat > "$OUTPUT_FILE" <<EOF
/* Waybar Colors - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

/* Base Colors */
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

/* RGBA Variants for transparency */
@define-color color4_rgba ${COLOR4_RGBA};
@define-color color4_rgba_hover ${COLOR4_RGBA_HOVER};
@define-color color4_rgba_border ${COLOR4_RGBA_BORDER};
@define-color color1_rgba ${COLOR1_RGBA};
@define-color color1_rgba_border ${COLOR1_RGBA_BORDER};
@define-color bg_rgba ${BG_RGBA};
@define-color bg_dark ${BG_DARK};

/* Semantic Color Names */
@define-color primary ${COLOR4};
@define-color secondary ${COLOR6};
@define-color accent ${COLOR5};
@define-color success ${COLOR2};
@define-color warning ${COLOR3};
@define-color error ${COLOR1};
@define-color muted ${COLOR8};
EOF

# Verify file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create CSS file"
    exit 1
fi

echo "✓ Waybar colors updated at $OUTPUT_FILE"
echo "✓ Color mapping:"
echo "  • Background: ${BACKGROUND}"
echo "  • Foreground: ${FOREGROUND}"
echo "  • Primary: ${COLOR4}"
echo "  • Success: ${COLOR2}"
echo "  • Warning: ${COLOR3}"
echo "  • Error: ${COLOR1}"

# Reload Waybar
if pgrep -x waybar > /dev/null; then
    pkill -SIGUSR2 waybar
    echo "✓ Waybar reloaded"
else
    echo "⚠ Waybar is not running"
fi

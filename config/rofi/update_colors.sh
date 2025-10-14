#!/usr/bin/env bash
# ⚠️ script abandoned after v0.3.8 blind owl check out ~/.config/hecate/scripts/update_hecate_colors.sh
# Now Hecate uses a centeralize css file to add colors to waybar,rofi,wlogout,rofi
COLOR_FILE="$HOME/.cache/wal/colors.json"
OUTPUT_DIR="$HOME/.config/rofi/wallust"
OUTPUT_FILE="$OUTPUT_DIR/colors-rofi.rasi"

# Check if pywal colors exist
if [ ! -f "$COLOR_FILE" ]; then
  echo "Error: Pywal colors not found at $COLOR_FILE"
  echo "Run 'wal -i /path/to/wallpaper' first"
  exit 1
fi

# Verify jq is installed
if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed"
  exit 1
fi

# Verify colors.json is valid
if ! jq empty "$COLOR_FILE" 2>/dev/null; then
  echo "Error: colors.json is not valid JSON"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

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

# Calculate relative luminance (0-1, where 1 is white)
get_luminance() {
  local hex=$1
  hex=${hex#\#}

  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  # Convert to 0-1 range
  local r_norm=$(echo "scale=4; $r / 255" | bc)
  local g_norm=$(echo "scale=4; $g / 255" | bc)
  local b_norm=$(echo "scale=4; $b / 255" | bc)

  # Apply gamma correction
  r_norm=$(echo "scale=4; if ($r_norm <= 0.03928) $r_norm / 12.92 else e(2.4 * l(($r_norm + 0.055) / 1.055))" | bc -l)
  g_norm=$(echo "scale=4; if ($g_norm <= 0.03928) $g_norm / 12.92 else e(2.4 * l(($g_norm + 0.055) / 1.055))" | bc -l)
  b_norm=$(echo "scale=4; if ($b_norm <= 0.03928) $b_norm / 12.92 else e(2.4 * l(($b_norm + 0.055) / 1.055))" | bc -l)

  # Calculate luminance using WCAG formula
  local luminance=$(echo "scale=4; 0.2126 * $r_norm + 0.7152 * $g_norm + 0.0722 * $b_norm" | bc -l)
  echo "$luminance"
}

# Check if background is light (luminance > 0.5)
is_light() {
  local luminance=$1
  # Return 0 (true) if light, 1 (false) if dark
  [ $(echo "$luminance > 0.5" | bc) -eq 1 ]
}

# Extract special colors
BACKGROUND=$(extract_color '.special.background')
FOREGROUND=$(extract_color '.special.foreground')
CURSOR=$(extract_color '.special.cursor')

# Extract all 16 colors into an array
declare -a COLORS
for i in {0..15}; do
  COLORS[$i]=$(extract_color ".colors.color$i")
done

# Calculate luminance for background and foreground
BG_LUMINANCE=$(get_luminance "$BACKGROUND")
FG_LUMINANCE=$(get_luminance "$FOREGROUND")

echo "Background luminance: $BG_LUMINANCE"
echo "Foreground luminance: $FG_LUMINANCE"

# Smart contrast adjustment
# If background is light, ensure we use dark colors for text
# If background is dark, ensure we use light colors for text
if is_light "$BG_LUMINANCE"; then
  echo "⚠ Light background detected - adjusting for contrast"
  # Background is light, so use dark colors for text
  SMART_FG="${COLORS[0]}" # Use darkest color
  SMART_FG_DIM="${COLORS[8]}"
  SMART_FG_BRIGHT="${COLORS[7]}"
  SMART_BG_ALT="${COLORS[15]}" # Light accent
else
  echo "✓ Dark background detected - using standard colors"
  # Background is dark, use light colors for text
  SMART_FG="${COLORS[7]}" # Use lightest color
  SMART_FG_DIM="${COLORS[8]}"
  SMART_FG_BRIGHT="${COLORS[15]}"
  SMART_BG_ALT="${COLORS[1]}"
fi

# Also check if foreground has poor contrast with background
FG_CONTRAST=$(echo "scale=4; sqrt(($BG_LUMINANCE - $FG_LUMINANCE)^2)" | bc -l)
if [ $(echo "$FG_CONTRAST < 0.3" | bc) -eq 1 ]; then
  echo "⚠ Poor contrast detected between BG and FG - using smart colors"
  FOREGROUND="$SMART_FG"
fi

# Create backup of existing file
if [ -f "$OUTPUT_FILE" ]; then
  cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
fi

# Generate the Rofi colors file with smart contrast
cat >"$OUTPUT_FILE" <<EOF
/* Rofi Colors - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */
/* Background Luminance: $BG_LUMINANCE ($(is_light "$BG_LUMINANCE" && echo "Light" || echo "Dark")) */

* {
    /* Special colors */
    background:     ${BACKGROUND};
    foreground:     ${SMART_FG};
    cursor:         ${CURSOR};

    /* Base16 color palette */
    color0:         ${COLORS[0]};
    color1:         ${COLORS[1]};
    color2:         ${COLORS[2]};
    color3:         ${COLORS[3]};
    color4:         ${COLORS[4]};
    color5:         ${COLORS[5]};
    color6:         ${COLORS[6]};
    color7:         ${COLORS[7]};
    color8:         ${COLORS[8]};
    color9:         ${COLORS[9]};
    color10:        ${COLORS[10]};
    color11:        ${COLORS[11]};
    color12:        ${COLORS[12]};
    color13:        ${COLORS[13]};
    color14:        ${COLORS[14]};
    color15:        ${COLORS[15]};

    /* Semantic color aliases with smart contrast */
    bg:             @background;
    fg:             @foreground;
    bg-alt:         ${SMART_BG_ALT};
    bg-dim:         @color0;
    fg-dim:         ${SMART_FG_DIM};
    fg-bright:      ${SMART_FG_BRIGHT};

    accent:         @color4;
    accent-alt:     @color12;

    red:            @color1;
    green:          @color2;
    yellow:         @color3;
    blue:           @color4;
    magenta:        @color5;
    cyan:           @color6;

    red-bright:     @color9;
    green-bright:   @color10;
    yellow-bright:  @color11;
    blue-bright:    @color12;
    magenta-bright: @color13;
    cyan-bright:    @color14;
}
EOF

# Verify file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
  echo "Error: Failed to create Rofi colors file"
  exit 1
fi

echo "✓ Rofi colors generated successfully!"
echo "  File: $OUTPUT_FILE"
echo "  BG: $BACKGROUND | FG: $SMART_FG | Accent: ${COLORS[4]}"
echo "  Contrast ratio improved: $(echo "scale=2; $FG_CONTRAST * 100" | bc)%"

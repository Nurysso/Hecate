#!/usr/bin/env bash

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
if ! command -v jq &> /dev/null; then
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

# Extract special colors
BACKGROUND=$(extract_color '.special.background')
FOREGROUND=$(extract_color '.special.foreground')
CURSOR=$(extract_color '.special.cursor')

# Extract all 16 colors into an array
declare -a COLORS
for i in {0..15}; do
    COLORS[$i]=$(extract_color ".colors.color$i")
done

# Create backup of existing file
if [ -f "$OUTPUT_FILE" ]; then
    cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
fi

# Generate the Rofi colors file
cat > "$OUTPUT_FILE" << EOF
/* Rofi Colors - Generated from Pywal */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

* {
    /* Special colors */
    background:     ${BACKGROUND};
    foreground:     ${FOREGROUND};
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
    
    /* Semantic color aliases */
    bg:             @background;
    fg:             @foreground;
    bg-alt:         @color1;
    bg-dim:         @color0;
    fg-dim:         @color8;
    fg-bright:      @color15;
    
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
echo "  BG: $BACKGROUND | FG: $FOREGROUND | Accent: ${COLORS[4]}"


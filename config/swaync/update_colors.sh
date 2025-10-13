#!/bin/bash
# ⚠️ Script abandoned after v0.3.8 blind owl check out ~/.config/hecate/scripts/update_hecate_colors.sh
# Now Hecate uses a centeralize css file to add colors to waybar,rofi,wlogout,rofi

# SwayNC Color Updater
# Generates color.css for SwayNC theme from pywal colors

# Path to color.css
COLOR_FILE="$HOME/.config/swaync/color.css"

# Source pywal colors
if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    source "$HOME/.cache/wal/colors.sh"
else
    echo "Error: Pywal colors not found at ~/.cache/wal/colors.sh"
    echo "Please run 'wal' to generate colors first."
    exit 1
fi

# Function to convert hex to RGB values
hex_to_rgb() {
    hex=$1
    hex=${hex#\#}  # Remove # if present
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}

# Convert colors to RGB
rgb0=$(hex_to_rgb "$color0")
rgb1=$(hex_to_rgb "$color1")
rgb2=$(hex_to_rgb "$color2")
rgb3=$(hex_to_rgb "$color3")
rgb4=$(hex_to_rgb "$color4")
rgb5=$(hex_to_rgb "$color5")
rgb6=$(hex_to_rgb "$color6")
rgb7=$(hex_to_rgb "$color7")
rgb8=$(hex_to_rgb "$color8")
rgb9=$(hex_to_rgb "$color9")
rgb10=$(hex_to_rgb "$color10")
rgb11=$(hex_to_rgb "$color11")
rgb12=$(hex_to_rgb "$color12")
rgb13=$(hex_to_rgb "$color13")
rgb14=$(hex_to_rgb "$color14")
rgb15=$(hex_to_rgb "$color15")

# Create the color.css file
cat > "$COLOR_FILE" << EOF
/*
  SwayNC Color Definitions
  Generated from Pywal on $(date '+%Y-%m-%d %H:%M:%S')
*/

@define-color BACKGROUND ${color0};
@define-color FOREGROUND ${color7};

@define-color COLOR0  ${color0};
@define-color COLOR1  ${color1};
@define-color COLOR2  ${color2};
@define-color COLOR3  ${color3};
@define-color COLOR4  ${color4};
@define-color COLOR5  ${color5};
@define-color COLOR6  ${color6};
@define-color COLOR7  ${color7};
@define-color COLOR8  ${color8};
@define-color COLOR9  ${color9};
@define-color COLOR10 ${color10};
@define-color COLOR11 ${color11};
@define-color COLOR12 ${color12};
@define-color COLOR13 ${color13};
@define-color COLOR14 ${color14};
@define-color COLOR15 ${color15};

/* RGBA Variants for transparency effects */
@define-color BG_RGBA rgba($rgb0, 0.85);
@define-color BG_RGBA_LIGHT rgba($rgb0, 0.7);
@define-color BG_RGBA_LIGHTER rgba($rgb0, 0.5);

@define-color COLOR1_RGBA rgba($rgb1, 0.4);
@define-color COLOR1_RGBA_LIGHT rgba($rgb1, 0.3);
@define-color COLOR1_RGBA_DIM rgba($rgb1, 0.1);

@define-color COLOR4_RGBA rgba($rgb4, 0.5);
@define-color COLOR4_RGBA_LIGHT rgba($rgb4, 0.4);
@define-color COLOR4_RGBA_DIM rgba($rgb4, 0.3);
@define-color COLOR4_RGBA_BORDER rgba($rgb4, 0.2);
EOF

echo "✓ Colors updated successfully at $COLOR_FILE"

# Reload SwayNC if it's running
if pgrep -x swaync > /dev/null; then
    echo "↻ Reloading SwayNC..."
    swaync-client -rs
    echo "✓ SwayNC reloaded"
else
    echo "⚠ SwayNC is not running"
fi

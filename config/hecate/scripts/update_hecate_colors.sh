#!/usr/bin/env bash

# Centralized Color Generator for Hecate Theme
# Creates a single hecate.css that all components import

COLOR_FILE="$HOME/.cache/wal/colors.json"
HECATE_CSS="$HOME/.config/hecate/hecate.css"
HECATE_DIR="$HOME/.config/hecate"

# Component CSS files that will import hecate.css
WAYBAR_CSS="$HOME/.config/waybar/color.css"
SWAYNC_CSS="$HOME/.config/swaync/color.css"
WLOGOUT_CSS="$HOME/.config/wlogout/color.css"
ROFI_RASI="$HOME/.config/rofi/theme/colors-rofi.rasi"

# Verify dependencies
if [ ! -f "$COLOR_FILE" ]; then
  echo "Error: wal colors.json not found at $COLOR_FILE"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is not installed"
  exit 1
fi

# Extract color with error checking
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

# Convert hex to rgba
hex_to_rgba() {
  local hex=$1
  local alpha=$2
  hex=${hex#"#"}

  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "rgba($r, $g, $b, $alpha)"
}

# Calculate luminance for contrast detection
get_luminance() {
  local hex=$1
  hex=${hex#\#}

  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))

  local r_norm=$(echo "scale=4; $r / 255" | bc)
  local g_norm=$(echo "scale=4; $g / 255" | bc)
  local b_norm=$(echo "scale=4; $b / 255" | bc)

  r_norm=$(echo "scale=4; if ($r_norm <= 0.03928) $r_norm / 12.92 else e(2.4 * l(($r_norm + 0.055) / 1.055))" | bc -l)
  g_norm=$(echo "scale=4; if ($g_norm <= 0.03928) $g_norm / 12.92 else e(2.4 * l(($g_norm + 0.055) / 1.055))" | bc -l)
  b_norm=$(echo "scale=4; if ($b_norm <= 0.03928) $b_norm / 12.92 else e(2.4 * l(($b_norm + 0.055) / 1.055))" | bc -l)

  local luminance=$(echo "scale=4; 0.2126 * $r_norm + 0.7152 * $g_norm + 0.0722 * $b_norm" | bc -l)
  echo "$luminance"
}

is_light() {
  local luminance=$1
  [ $(echo "$luminance > 0.5" | bc) -eq 1 ]
}

echo "Extracting colors from pywal..."

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
CURSOR=$(extract_color '.special.cursor')

# Smart contrast adjustment
BG_LUMINANCE=$(get_luminance "$BACKGROUND")
echo "Background luminance: $BG_LUMINANCE"

if is_light "$BG_LUMINANCE"; then
  echo "⚠ Light background detected - adjusting for contrast"
  SMART_FG="${COLOR0}"
  SMART_FG_DIM="${COLOR8}"
  SMART_FG_BRIGHT="${COLOR7}"
  SMART_BG_ALT="${COLOR15}"
else
  echo "✓ Dark background detected - using standard colors"
  SMART_FG="${COLOR7}"
  SMART_FG_DIM="${COLOR8}"
  SMART_FG_BRIGHT="${COLOR15}"
  SMART_BG_ALT="${COLOR1}"
fi

# Generate RGBA variants
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.15")
COLOR4_RGBA_HOVER=$(hex_to_rgba "$COLOR4" "0.4")
COLOR4_RGBA_BORDER=$(hex_to_rgba "$COLOR4" "0.6")
COLOR1_RGBA=$(hex_to_rgba "$COLOR1" "0.4")
COLOR1_RGBA_BORDER=$(hex_to_rgba "$COLOR1" "0.6")
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.85")
BG_RGBA_LIGHT=$(hex_to_rgba "$BACKGROUND" "0.7")
BG_RGBA_LIGHTER=$(hex_to_rgba "$BACKGROUND" "0.5")
BG_RGBA_DIM=$(hex_to_rgba "$BACKGROUND" "0.2")

# Generate RGB values for SwayNC
hex_to_rgb() {
  local hex=$1
  hex=${hex#\#}
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "$r, $g, $b"
}

RGB0=$(hex_to_rgb "$COLOR0")
RGB1=$(hex_to_rgb "$COLOR1")
RGB4=$(hex_to_rgb "$COLOR4")

# Create backup
mkdir -p "$(dirname "$HECATE_CSS")"
if [ -f "$HECATE_CSS" ]; then
  cp "$HECATE_CSS" "${HECATE_CSS}.backup"
fi

# Generate the master hecate.css file
cat >"$HECATE_CSS" <<EOF
/* ═══════════════════════════════════════════════════════════════
   Hecate Theme - Centralized Color Definitions
   Generated from Pywal on $(date '+%Y-%m-%d %H:%M:%S')

   This file is the single source of truth for all theme colors.
   All component CSS files import from this file.
   ═══════════════════════════════════════════════════════════════ */

/* ─────────────────────────────────────────────────────────────── */
/* Base Colors (Pywal)                                             */
/* ─────────────────────────────────────────────────────────────── */

@define-color background ${BACKGROUND};
@define-color foreground ${SMART_FG};
@define-color cursor ${CURSOR};

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

/* ─────────────────────────────────────────────────────────────── */
/* Smart Contrast Variants                                         */
/* ─────────────────────────────────────────────────────────────── */

@define-color bg ${BACKGROUND};
@define-color fg ${SMART_FG};
@define-color bg-alt ${SMART_BG_ALT};
@define-color bg-dim ${COLOR0};
@define-color fg-dim ${SMART_FG_DIM};
@define-color fg-bright ${SMART_FG_BRIGHT};

/* ─────────────────────────────────────────────────────────────── */
/* Semantic Colors                                                 */
/* ─────────────────────────────────────────────────────────────── */

@define-color primary ${COLOR4};
@define-color secondary ${COLOR6};
@define-color accent ${COLOR5};
@define-color accent-alt ${COLOR12};
@define-color success ${COLOR2};
@define-color warning ${COLOR3};
@define-color error ${COLOR1};
@define-color muted ${COLOR8};

@define-color red ${COLOR1};
@define-color green ${COLOR2};
@define-color yellow ${COLOR3};
@define-color blue ${COLOR4};
@define-color magenta ${COLOR5};
@define-color cyan ${COLOR6};

@define-color red-bright ${COLOR9};
@define-color green-bright ${COLOR10};
@define-color yellow-bright ${COLOR11};
@define-color blue-bright ${COLOR12};
@define-color magenta-bright ${COLOR13};
@define-color cyan-bright ${COLOR14};

/* ─────────────────────────────────────────────────────────────── */
/* RGBA Variants (for transparency effects)                        */
/* ─────────────────────────────────────────────────────────────── */

/* Background variants */
@define-color bg_rgba ${BG_RGBA};
@define-color bg_rgba_light ${BG_RGBA_LIGHT};
@define-color bg_rgba_lighter ${BG_RGBA_LIGHTER};
@define-color bg_dark ${BG_RGBA_LIGHTER};
@define-color bg_rgba_dim ${BG_RGBA_DIM};

/* Primary/Accent variants */
@define-color color4_rgba ${COLOR4_RGBA};
@define-color color4_rgba_hover ${COLOR4_RGBA_HOVER};
@define-color color4_rgba_border ${COLOR4_RGBA_BORDER};

/* Error/Warning variants */
@define-color color1_rgba ${COLOR1_RGBA};
@define-color color1_rgba_border ${COLOR1_RGBA_BORDER};
@define-color color1_rgba_light rgba(${RGB1}, 0.3);
@define-color color1_rgba_dim rgba(${RGB1}, 0.1);

/* SwayNC specific RGBA variants */
@define-color BG_RGBA rgba(${RGB0}, 0.85);
@define-color BG_RGBA_LIGHT rgba(${RGB0}, 0.7);
@define-color BG_RGBA_LIGHTER rgba(${RGB0}, 0.5);
@define-color COLOR1_RGBA rgba(${RGB1}, 0.4);
@define-color COLOR1_RGBA_LIGHT rgba(${RGB1}, 0.3);
@define-color COLOR1_RGBA_DIM rgba(${RGB1}, 0.1);
@define-color COLOR4_RGBA rgba(${RGB4}, 0.5);
@define-color COLOR4_RGBA_LIGHT rgba(${RGB4}, 0.4);
@define-color COLOR4_RGBA_DIM rgba(${RGB4}, 0.3);
@define-color COLOR4_RGBA_BORDER rgba(${RGB4}, 0.2);

/* ─────────────────────────────────────────────────────────────── */
/* Component-Specific Aliases                                      */
/* ─────────────────────────────────────────────────────────────── */

/* Waybar */
@define-color BACKGROUND ${BACKGROUND};
@define-color FOREGROUND ${SMART_FG};

/* Wlogout */
/* (uses same definitions as above) */

/* ═══════════════════════════════════════════════════════════════
   End of Hecate Theme Colors
   ═══════════════════════════════════════════════════════════════ */
EOF

echo "✓ Generated master hecate.css"

# Create symlinks from component directories to hecate.css
# This makes dotfiles portable across systems
echo "Creating symlinks to hecate.css..."

mkdir -p "$(dirname "$WAYBAR_CSS")"
if [ -L "$WAYBAR_CSS" ] || [ -f "$WAYBAR_CSS" ]; then
  rm -f "$WAYBAR_CSS"
fi
ln -sf "$HECATE_CSS" "$WAYBAR_CSS"
echo "  ✓ $WAYBAR_CSS -> $HECATE_CSS"

mkdir -p "$(dirname "$SWAYNC_CSS")"
if [ -L "$SWAYNC_CSS" ] || [ -f "$SWAYNC_CSS" ]; then
  rm -f "$SWAYNC_CSS"
fi
ln -sf "$HECATE_CSS" "$SWAYNC_CSS"
echo "  ✓ $SWAYNC_CSS -> $HECATE_CSS"

mkdir -p "$(dirname "$WLOGOUT_CSS")"
if [ -L "$WLOGOUT_CSS" ] || [ -f "$WLOGOUT_CSS" ]; then
  rm -f "$WLOGOUT_CSS"
fi
ln -sf "$WLOGOUT_CSS" "$WLOGOUT_CSS"
echo "  ✓ $WLOGOUT_CSS -> $HECATE_CSS"

echo "✓ Symlinks created successfully"

# Generate Rofi colors (RASI format, can't use CSS import)
mkdir -p "$(dirname "$ROFI_RASI")"
cat >"$ROFI_RASI" <<EOF
/* Rofi Colors - Generated from Hecate Theme */
/* Generated: $(date '+%Y-%m-%d %H:%M:%S') */

* {
    /* Special colors */
    background:     ${BACKGROUND};
    foreground:     ${SMART_FG};
    cursor:         ${CURSOR};

    /* Base16 color palette */
    color0:         ${COLOR0};
    color1:         ${COLOR1};
    color2:         ${COLOR2};
    color3:         ${COLOR3};
    color4:         ${COLOR4};
    color5:         ${COLOR5};
    color6:         ${COLOR6};
    color7:         ${COLOR7};
    color8:         ${COLOR8};
    color9:         ${COLOR9};
    color10:        ${COLOR10};
    color11:        ${COLOR11};
    color12:        ${COLOR12};
    color13:        ${COLOR13};
    color14:        ${COLOR14};
    color15:        ${COLOR15};

    /* Semantic aliases */
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

echo "✓ Generated Rofi colors (RASI format)"

# Update Starship prompt colors
echo "Updating Starship prompt..."
STARSHIP_SCRIPT="$HOME/.config/hecate/scripts/update_starship-colors.sh"
if [ -f "$STARSHIP_SCRIPT" ]; then
  if bash "$STARSHIP_SCRIPT"; then
    echo "✓ Starship colors updated"
  else
    echo "⚠ Starship update failed"
  fi
else
  echo "⚠ Starship color script not found, skipping..."
fi

# Generate blurred wallpaper for Wlogout
WALLPAPER_OUTPUT="$HOME/.cache/wlogout/blurred_wallpaper.png"
CONFIG="$HOME/.config/waypaper/config.ini"
if [ -f "$CONFIG" ]; then
  WP_PATH=$(grep '^wallpaper' "$CONFIG" | cut -d '=' -f2 | tr -d ' ')
  WP_PATH="${WP_PATH/#\~/$HOME}"

  if [ -f "$WP_PATH" ] && command -v convert &>/dev/null; then
    mkdir -p "$HOME/.cache/wlogout"
    convert "$WP_PATH" -blur 0x10 -scale 1920x1080^ -gravity center -extent 1920x1080 "$WALLPAPER_OUTPUT" 2>/dev/null
    echo "✓ Generated blurred wallpaper for Wlogout"
  fi
fi

# Reload components
echo ""
echo "Reloading components..."

if pgrep -x waybar >/dev/null; then
  pkill -SIGUSR2 waybar
  echo "✓ Waybar reloaded"
fi

if pgrep -x swaync >/dev/null; then
  swaync-client -rs
  echo "✓ SwayNC reloaded"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Hecate theme updated successfully!"
echo "═══════════════════════════════════════════════════════════"
echo "  Master file: $HECATE_CSS"
echo "  Background:  ${BACKGROUND}"
echo "  Foreground:  ${SMART_FG}"
echo "  Primary:     ${COLOR4}"
echo "  Luminance:   ${BG_LUMINANCE} ($(is_light "$BG_LUMINANCE" && echo "Light" || echo "Dark"))"
echo "═══════════════════════════════════════════════════════════"

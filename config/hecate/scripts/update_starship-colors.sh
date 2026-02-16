#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════
# Starship Color Updater - Hecate Edition
# Reads from dummy template, applies pywal colors, writes to config
# ═══════════════════════════════════════════════════════════════

STARSHIP_DUMMY="$HOME/.config/starship/starship-dummy.toml"
STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
BACKUP_CONFIG="$HOME/.config/starship/starship.toml.backup"
COLOR_FILE="$HOME/.cache/wal/colors.sh"

# ─── VALIDATION ─────────────────────────────────────────────────

# Check if dummy template exists
if [ ! -f "$STARSHIP_DUMMY" ]; then
  echo "✗ Error: Dummy template not found at $STARSHIP_DUMMY"
  echo "  Please create the template file first."
  exit 1
fi

# Source pywal colors
if [ -f "$COLOR_FILE" ]; then
  source "$COLOR_FILE"
else
  echo "✗ Error: Pywal colors not found at $COLOR_FILE"
  echo "  Please run 'wal' to generate colors first."
  exit 1
fi

# Create starship config directory if it doesn't exist
mkdir -p "$(dirname "$STARSHIP_CONFIG")"

# ─── BACKUP ─────────────────────────────────────────────────────

# Backup existing config if it exists
if [ -f "$STARSHIP_CONFIG" ]; then
  cp "$STARSHIP_CONFIG" "$BACKUP_CONFIG"
  echo "◉ Backup created: $BACKUP_CONFIG"
fi

# ─── COLOR REPLACEMENT ──────────────────────────────────────────

# Read the dummy template and replace color placeholders
# Replace color1 through color8, and color7 for dimmed elements
sed -e "s/color1/$color1/g" \
    -e "s/color2/$color2/g" \
    -e "s/color3/$color3/g" \
    -e "s/color4/$color4/g" \
    -e "s/color5/$color5/g" \
    -e "s/color6/$color6/g" \
    -e "s/color7/$color7/g" \
    -e "s/color8/$color8/g" \
    "$STARSHIP_DUMMY" > "$STARSHIP_CONFIG"

# Add generation timestamp comment at the top
sed -i "3i# this file will be replaced when wallpaper is" "$STARSHIP_CONFIG"
sed -i "4i# changed so your changes will be overwritten, if need any changes" "$STARSHIP_CONFIG"
sed -i "5i# edit this file ~/.config/starship/starship-dummt.toml" "$STARSHIP_CONFIG"
sed -i "3i# Generated: $(date '+%Y-%m-%d %H:%M:%S')" "$STARSHIP_CONFIG"

# ─── SUCCESS MESSAGE ────────────────────────────────────────────
hex_to_ansi() {
    local hex="${1#"#"}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf "\e[38;2;%d;%d;%dm" "$r" "$g" "$b"
}

reset="\e[0m"

echo ""
echo "╭─────────────────────────────────────────────────╮"
echo "│ ✓ Starship config updated successfully          │"
echo "╰─────────────────────────────────────────────────╯"
echo ""
echo "  Dummy:  $STARSHIP_DUMMY"
echo "  Config: $STARSHIP_CONFIG"
echo ""
echo "Color mapping:"
echo -e "$(hex_to_ansi "$color1")  ◉ color1 (error, git status, rust, java): $color1${reset}"
echo -e "$(hex_to_ansi "$color2")  ◉ color2 (success symbol, golang):        $color2${reset}"
echo -e "$(hex_to_ansi "$color3")  ◉ color3 (username, python, aws):         $color3${reset}"
echo -e "$(hex_to_ansi "$color4")  ◉ color4 (hostname, package, clouds):     $color4${reset}"
echo -e "$(hex_to_ansi "$color5")  ◉ color5 (git branch):                    $color5${reset}"
echo -e "$(hex_to_ansi "$color6")  ◉ color6 (directory background):          $color6${reset}"
echo -e "$(hex_to_ansi "$color7")  ◉ color7 (OS symbols):                    $color7${reset}"
echo -e "$(hex_to_ansi "$color8")  ◉ color8 (dim text, nodejs, prompt):      $color8${reset}"
echo "Changes will apply on next prompt refresh."
echo ""

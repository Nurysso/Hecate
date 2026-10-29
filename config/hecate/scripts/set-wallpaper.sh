#!/usr/bin/env bash
# Usage: set-wallpaper.sh <image>
# Sets the wallpaper through awww (fading into it) and, when [theme] mode = "dynamic",
# regenerates the M3 palette with matugen into ~/.cache/hecate/theme.json (watched by Quickshell).
set -euo pipefail

wall=$(realpath -e -- "${1:?usage: set-wallpaper.sh <image>}")
cache="$HOME/.cache/hecate"
toml="$HOME/.config/hecate/hecate.toml"
mkdir -p "$cache"

ln -sfn "$wall" "$cache/wallpaper" # Hyprland autostart fades this back in on login
awww img "$wall" -t fade --transition-duration 0.9 --transition-bezier .45,0,.55,1 --transition-fps 60 \
    || echo "set-wallpaper: awww-daemon not running, colors still updated" >&2

mode=$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1],"rb")).get("theme",{}).get("mode","dynamic"))' "$toml" 2>/dev/null || echo dynamic)

if [ "$mode" = dynamic ]; then
    colors=$(matugen image "$wall" -q --source-color-index 0 --json hex | jq '.colors | map_values(.default.color)')
else
    colors=$(jq 'del(.wallpaper)' "$cache/theme.json" 2>/dev/null || echo '{}')
fi

tmp=$(mktemp "$cache/theme.XXXXXX")
jq -n --argjson c "$colors" --arg w "$wall" '$c + {wallpaper: $w}' >"$tmp"
mv "$tmp" "$cache/theme.json"

# Recolor the starship prompt: swap its [palettes.hecate] block (kept last in the file) for these colors
starship="$HOME/.config/starship/starship.toml"
if [ -f "$starship" ] && jq -e .primary "$cache/theme.json" >/dev/null; then
    tmp=$(mktemp "$cache/starship.XXXXXX")
    { sed '/^\[palettes\.hecate\]/,$d' "$starship"
      jq -r '"[palettes.hecate]", "primary = \"\(.primary)\"", "secondary = \"\(.secondary)\"",
             "tertiary = \"\(.tertiary)\"", "error = \"\(.error)\"", "muted = \"\(.outline)\""' "$cache/theme.json"
    } >"$tmp"
    mv "$tmp" "$starship"
fi

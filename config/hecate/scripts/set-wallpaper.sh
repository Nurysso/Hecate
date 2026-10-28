#!/usr/bin/env bash
# Usage: set-wallpaper.sh <image>
# Sets the wallpaper through hyprpaper and, when [theme] mode = "dynamic",
# regenerates the M3 palette with matugen into ~/.cache/hecate/theme.json (watched by Quickshell).
set -euo pipefail

wall=$(realpath -e -- "${1:?usage: set-wallpaper.sh <image>}")
cache="$HOME/.cache/hecate"
toml="$HOME/.config/hecate/hecate.toml"
mkdir -p "$cache"

ln -sfn "$wall" "$cache/wallpaper" # hyprpaper.conf points here
# hyprpaper 0.8's IPC ignores `hyprctl hyprpaper wallpaper`, so restart it to reread the symlink
pkill -x hyprpaper || true
setsid -f hyprpaper >/dev/null 2>&1

mode=$(python3 -c 'import sys,tomllib; print(tomllib.load(open(sys.argv[1],"rb")).get("theme",{}).get("mode","dynamic"))' "$toml" 2>/dev/null || echo dynamic)

if [ "$mode" = dynamic ]; then
    colors=$(matugen image "$wall" -q --source-color-index 0 --json hex | jq '.colors | map_values(.default.color)')
else
    colors=$(jq 'del(.wallpaper)' "$cache/theme.json" 2>/dev/null || echo '{}')
fi

tmp=$(mktemp "$cache/theme.XXXXXX")
jq -n --argjson c "$colors" --arg w "$wall" '$c + {wallpaper: $w}' >"$tmp"
mv "$tmp" "$cache/theme.json"

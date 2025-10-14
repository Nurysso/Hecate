#!/bin/bash
# Scripts for refreshing Hyprland + components (waybar, swaync, ags, wallust, hyprpm)

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

SCRIPTSDIR="$HOME/.config/hypr/scripts"

# --- helpers ---
file_exists() {
  [[ -e "$1" ]]
}

# --- kill processes safely ---
_ps=(waybar swaync ags)
for _prs in "${_ps[@]}"; do
  pkill -x "$_prs" 2>/dev/null || true
done

# --- restart waybar ---
sleep 1
WAYBAR_DISABLE_DBUS=1 waybar >~/.cache/waybar.log 2>&1 &

# --- restart swaync ---
sleep 0.5
swaync >/dev/null 2>&1 &
swaync-client --reload-config >/dev/null 2>&1 || true

# --- optional AGS restart ---
# ags -q && ags >/dev/null 2>&1 &

# --- optional Quickshell restart ---
# pkill -x qs && qs >/dev/null 2>&1 &

# --- refresh Hyprland config ---
hyprctl reload >/dev/null 2>&1 || true

# --- hyprpm reload if requested ---
if [[ "$1" == "hyprpm" ]]; then
  if [[ -n "$2" ]]; then
    echo ":: Reloading hyprpm plugin: $2"
    hyprpm reload "$2"
  else
    echo ":: Reloading all hyprpm plugins"
    hyprpm reload all
  fi
fi

notify-send -u low "System Reloaded Successfully"
exit 0

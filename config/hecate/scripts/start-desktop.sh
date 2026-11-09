#!/usr/bin/env bash
# Run once by Hyprland at login. Starts awww on black (where hecate-sddm's fade ends), then hands over to
# ~/.config/quickshell/reveal, which sets the wallpaper and starts the shell behind a black cover and opens
# a circle to show them. If that can't run, awww draws the circle over the wallpaper alone and the shell
# just starts, so a broken reveal never costs you the desktop.

wall="$HOME/.cache/hecate/wallpaper"
circle() { awww img "$wall" -t center --transition-duration 0.9 --transition-bezier .45,0,.55,1 --transition-fps 60 --transition-step 45; }

awww-daemon --no-cache &
until awww query >/dev/null 2>&1; do sleep 0.05; done
awww clear 000000

if pgrep -x quickshell >/dev/null; then
    circle
    exit
fi

timeout 15 quickshell -p "$HOME/.config/quickshell/reveal" || circle
pgrep -x quickshell >/dev/null || exec quickshell

#!/bin/bash

LOCKFILE="/tmp/waybar-launch.lock"

# If lockfile exists and process still running, exit
if [ -f "$LOCKFILE" ] && pgrep -x "waybar" > /dev/null; then
    echo "Waybar is already running."
    exit 0
fi

# Remove old lock if no waybar process found
if [ -f "$LOCKFILE" ] && ! pgrep -x "waybar" > /dev/null; then
    rm -f "$LOCKFILE"
fi

echo "Starting Waybar..."
waybar &
echo $! > "$LOCKFILE"

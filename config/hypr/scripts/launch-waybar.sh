#!/bin/bash

# Check if Waybar is already running
if pgrep -x "waybar" > /dev/null; then
    echo "Waybar is already running."
else
    echo "Starting Waybar..."
    waybar &
fi

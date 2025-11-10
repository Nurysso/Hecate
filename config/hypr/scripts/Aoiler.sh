#!/bin/bash

PROGRAM="$HOME/.local/bin/Aoiler"
CLASS="Aoiler"

# Check if Aoiler is running
if pgrep -x "Aoiler" > /dev/null; then
  # Aoiler is running, kill it
  pkill -x "Aoiler"
else
  # Aoiler not running, launch it in special workspace
  hyprctl dispatch exec "[workspace special:aoiler silent] $PROGRAM"
fi

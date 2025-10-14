#!/bin/bash

PROGRAM="$HOME/.local/bin/Pulse"
PID=$(pgrep -x "Pulse")

if [ -n "$PID" ]; then
  # Pulse running, kill it
  kill "$PID"
else
  # Pulse not running, start detached
  setsid "$PROGRAM" >/dev/null 2>&1 &
fi

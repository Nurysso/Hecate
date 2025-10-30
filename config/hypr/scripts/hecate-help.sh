#!/bin/bash

PROGRAM="$HOME/.local/bin/Hecate-Settings"
PID=$(pgrep -x "Hecate-Settings")

if [ -n "$PID" ]; then
  kill "$PID"
else
  setsid "$PROGRAM" "$1" > /dev/null 2>&1 &
fi

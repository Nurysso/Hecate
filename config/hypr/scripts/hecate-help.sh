#!/bin/bash

PROGRAM="$HOME/.local/bin/hecate-help "
PID=$(pgrep -x "hecate-help")

if [ -n "$PID" ]; then
  kill "$PID"
else
  setsid "$PROGRAM" > /dev/null 2>&1 &
fi

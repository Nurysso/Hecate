#!/bin/bash

# Check if quickshell is already running
if pgrep -x "quickshell" > /dev/null; then
    echo "quickshell is already running."
else
    echo "Starting quickshell..."
    quickshell &
fi

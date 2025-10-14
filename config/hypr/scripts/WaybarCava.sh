#!/bin/bash

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# ============ Configuration ============
BAR_CHARS="▁▂▃▄▅▆▇█"
FRAMERATE=30
BAR_COUNT=10
MAX_RANGE=7
INPUT_METHOD="pulse"
SOURCE="auto"

# Advanced settings
AUTOSENS=1
SMOOTHING=1
NOISE_REDUCTION=0.77

# File paths
CONFIG_FILE="/tmp/cava_bar_${USER}_$$.conf"
LOCK_FILE="/tmp/cava_bar_${USER}.lock"

# ============ Functions ============

# Cleanup function
cleanup() {
  rm -f "$CONFIG_FILE" "$LOCK_FILE"
  pkill -P $$ 2>/dev/null
  exit 0
}

# Check if already running
check_running() {
  if [[ -f "$LOCK_FILE" ]]; then
    old_pid=$(cat "$LOCK_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "Cava is already running (PID: $old_pid)"
      echo "Kill it? [y/N]"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        kill "$old_pid" 2>/dev/null
        rm -f "$LOCK_FILE"
      else
        exit 0
      fi
    else
      rm -f "$LOCK_FILE"
    fi
  fi
  echo $$ >"$LOCK_FILE"
}

# Build sed replacement dictionary
build_dict() {
  local dict="s/;//g"
  local length=${#BAR_CHARS}

  for ((i = 0; i < length; i++)); do
    dict+=";s/$i/${BAR_CHARS:$i:1}/g"
  done

  echo "$dict"
}

# Create cava configuration file
create_config() {
  cat >"$CONFIG_FILE" <<EOF
[general]
framerate = $FRAMERATE
bars = $BAR_COUNT
autosens = $AUTOSENS

[input]
method = $INPUT_METHOD
source = $SOURCE

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $MAX_RANGE

[smoothing]
mode = $SMOOTHING
noise_reduction = $NOISE_REDUCTION
EOF
}

# Main visualization function
start_visualizer() {
  local sed_dict
  sed_dict=$(build_dict)

  # Start cava and process output
  cava -p "$CONFIG_FILE" 2>/dev/null | sed -u "$sed_dict"
}

# ============ Main Execution ============

# Set up signal handlers
trap cleanup EXIT INT TERM QUIT

# Check for running instances
check_running

# Verify cava is installed
if ! command -v cava &>/dev/null; then
  echo "Error: cava is not installed"
  exit 1
fi

# Create configuration
create_config

# Start the visualizer
start_visualizer

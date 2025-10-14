#!/bin/bash

# Network speed monitor for eww widgets
# Usage: ./network.sh [up|down]

INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
CACHE_DIR="/tmp/eww_network"
CACHE_FILE="$CACHE_DIR/network_stats"

mkdir -p "$CACHE_DIR"

# Get current RX/TX bytes
get_bytes() {
  if [ -z "$INTERFACE" ]; then
    echo "0 0"
    return
  fi

  RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
  TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
  echo "$RX_BYTES $TX_BYTES"
}

# Format bytes to human readable
format_bytes() {
  local bytes=$1
  if [ $bytes -lt 1024 ]; then
    echo "${bytes}B/s"
  elif [ $bytes -lt 1048576 ]; then
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1024}")KB/s"
  else
    echo "$(awk "BEGIN {printf \"%.1f\", $bytes/1048576}")MB/s"
  fi
}

# Read previous values
if [ -f "$CACHE_FILE" ]; then
  read PREV_RX PREV_TX PREV_TIME <"$CACHE_FILE"
else
  PREV_RX=0
  PREV_TX=0
  PREV_TIME=$(date +%s)
fi

# Get current values
CURRENT_TIME=$(date +%s)
read CURRENT_RX CURRENT_TX < <(get_bytes)

# Calculate time difference
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))

if [ $TIME_DIFF -eq 0 ]; then
  TIME_DIFF=1
fi

# Calculate speeds (bytes per second)
RX_SPEED=$(((CURRENT_RX - PREV_RX) / TIME_DIFF))
TX_SPEED=$(((CURRENT_TX - PREV_TX) / TIME_DIFF))

# Handle negative values (interface reset)
if [ $RX_SPEED -lt 0 ]; then
  RX_SPEED=0
fi
if [ $TX_SPEED -lt 0 ]; then
  TX_SPEED=0
fi

# Save current values for next run
echo "$CURRENT_RX $CURRENT_TX $CURRENT_TIME" >"$CACHE_FILE"

# Output based on argument
case "$1" in
up)
  format_bytes $TX_SPEED
  ;;
down)
  format_bytes $RX_SPEED
  ;;
*)
  echo "Usage: $0 [up|down]"
  exit 1
  ;;
esac

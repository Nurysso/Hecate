#!/usr/bin/env bash
# Minimal Hyprland Power Script for Wlogout
# Handles exit, lock, reboot, shutdown, suspend, and hibernate.

TIMEOUT=5

terminate_clients() {
  client_pids=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | .pid')
  [[ -z "$client_pids" ]] && return

  for pid in $client_pids; do
    kill -15 "$pid" 2>/dev/null
  done

  start_time=$(date +%s)
  for pid in $client_pids; do
    while kill -0 "$pid" 2>/dev/null; do
      (($(date +%s) - start_time >= TIMEOUT)) && break
      sleep 0.5
    done
  done
}

case "$1" in
exit)
  terminate_clients
  sleep 0.3
  hyprctl dispatch exit
  ;;
lock)
  hyprlock
  ;;
reboot)
  terminate_clients
  sleep 0.3
  systemctl reboot
  ;;
shutdown)
  terminate_clients
  sleep 0.3
  systemctl poweroff
  ;;
suspend)
  systemctl suspend
  ;;
hibernate)
  systemctl hibernate
  ;;
*)
  exit 1
  ;;
esac

#!/usr/bin/env bash
# Hecate: set up Bluetooth tools and (optionally) hand the wired link to NetworkManager only.
# Usage: ./fix-connectivity.sh            -> Bluetooth setup only
#        ./fix-connectivity.sh --nm-only  -> also stop systemd-networkd from managing your links
set -euo pipefail

echo "==> Installing bluetoothctl (bluez-utils)"
sudo pacman -S --needed bluez-utils

echo "==> Enabling the Bluetooth service"
sudo systemctl enable --now bluetooth.service

if [ -n "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]; then
    echo "==> Bluetooth adapter found:"
    rfkill list bluetooth || true
    if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
        echo "==> Adapter is soft-blocked, unblocking"
        sudo rfkill unblock bluetooth
    fi
    bluetoothctl show | head -5
else
    echo "!! No Bluetooth adapter detected (/sys/class/bluetooth is empty)."
    echo "   This PC has no built-in Bluetooth. Plug in a USB Bluetooth adapter, then run:"
    echo "   sudo systemctl restart bluetooth && bluetoothctl show"
fi

if [ "${1:-}" = "--nm-only" ]; then
    echo "==> Letting NetworkManager manage networking alone"
    echo "   (your network may drop for a few seconds while NetworkManager takes over)"
    sudo systemctl disable --now systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service
    sudo systemctl enable --now NetworkManager.service
    sleep 3
    nmcli device status
    echo "   Your .network files in /etc/systemd/network were left in place; re-enable with:"
    echo "   sudo systemctl enable --now systemd-networkd.service systemd-networkd.socket"
fi

echo "==> Done. Click Refresh on the Connectivity tab in hecate-settings."


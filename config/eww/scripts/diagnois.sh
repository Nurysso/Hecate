#!/bin/bash

echo "=== System Diagnostics ==="
echo ""

echo "1. Temperature Detection:"
echo "   - sensors command:"
sensors 2>/dev/null | head -20
echo ""
echo "   - thermal zones:"
for i in {0..5}; do
  if [ -f "/sys/class/thermal/thermal_zone$i/temp" ]; then
    temp=$(cat /sys/class/thermal/thermal_zone$i/temp 2>/dev/null)
    echo "     thermal_zone$i: $((temp / 1000))°C"
  fi
done
echo ""
echo "   - hwmon:"
find /sys/class/hwmon -name 'temp*_input' -exec sh -c 'echo "     {}: $(($(cat {}) / 1000))°C"' \; 2>/dev/null | head -5
echo ""

echo "2. GPU Detection:"
echo "   - NVIDIA:"
nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu --format=csv,noheader 2>/dev/null || echo "     Not found"
echo ""
echo "   - AMD (sysfs):"
if [ -f "/sys/class/drm/card0/device/gpu_busy_percent" ]; then
  echo "     Usage: $(cat /sys/class/drm/card0/device/gpu_busy_percent)%"
else
  echo "     Not found at /sys/class/drm/card0"
fi
echo ""
echo "   - Intel:"
if [ -f "/sys/class/drm/card0/gt_cur_freq_mhz" ]; then
  echo "     Detected Intel GPU"
else
  echo "     Not found"
fi
echo ""

echo "3. Network Detection:"
echo "   - Active interfaces:"
ls /sys/class/net/ | grep -v 'lo'
echo ""
echo "   - Network script:"
if [ -f "$HOME/.config/eww/scripts/network.sh" ]; then
  echo "     Script exists"
  $HOME/.config/eww/scripts/network.sh down 2>&1 | head -1
  $HOME/.config/eww/scripts/network.sh up 2>&1 | head -1
else
  echo "     Script not found at $HOME/.config/eww/scripts/network.sh"
fi
echo ""
echo "   - Direct interface stats (example for first interface):"
iface=$(ls /sys/class/net/ | grep -v 'lo' | head -1)
if [ -n "$iface" ]; then
  echo "     Interface: $iface"
  echo "     RX bytes: $(cat /sys/class/net/$iface/statistics/rx_bytes)"
  echo "     TX bytes: $(cat /sys/class/net/$iface/statistics/tx_bytes)"
fi

echo ""
echo "=== Diagnostic Complete ==="

#!/bin/bash
bluetoothctl info | grep "Connected" >/dev/null && echo "BT On" || echo "BT Off"

#!/usr/bin/env bash

COLOR_FILE="$HOME/.cache/wal/colors.json"
OUTPUT_FILE="$HOME/.config/waybar/style/default.css"

# Verify colors.json exists and is readable
if [ ! -f "$COLOR_FILE" ]; then
    echo "Error: wal colors.json not found at $COLOR_FILE"
    exit 1
fi

# Verify jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

# Extract colors with error checking
extract_color() {
    local key="$1"
    local value
    value=$(jq -r "$key" "$COLOR_FILE" 2>/dev/null)
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "Error: Failed to extract $key from colors.json"
        exit 1
    fi
    echo "$value"
}

# Extract all colors
COLOR0=$(extract_color '.colors.color0')
COLOR1=$(extract_color '.colors.color1')
COLOR2=$(extract_color '.colors.color2')
COLOR3=$(extract_color '.colors.color3')
COLOR4=$(extract_color '.colors.color4')
COLOR5=$(extract_color '.colors.color5')
COLOR6=$(extract_color '.colors.color6')
COLOR7=$(extract_color '.colors.color7')
COLOR8=$(extract_color '.colors.color8')
COLOR9=$(extract_color '.colors.color9')
COLOR10=$(extract_color '.colors.color10')
COLOR11=$(extract_color '.colors.color11')
COLOR12=$(extract_color '.colors.color12')
COLOR13=$(extract_color '.colors.color13')
COLOR14=$(extract_color '.colors.color14')
COLOR15=$(extract_color '.colors.color15')
BACKGROUND=$(extract_color '.special.background')
FOREGROUND=$(extract_color '.special.foreground')

# Convert hex to rgba function
hex_to_rgba() {
    local hex=$1
    local alpha=$2
    hex=${hex#"#"}

    if [ ${#hex} -ne 6 ]; then
        echo "Error: Invalid hex color: $hex"
        return 1
    fi

    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

# Generate RGBA colors
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.15")
COLOR4_RGBA_HOVER=$(hex_to_rgba "$COLOR4" "0.4")
COLOR4_RGBA_BORDER=$(hex_to_rgba "$COLOR4" "0.6")
COLOR1_RGBA=$(hex_to_rgba "$COLOR1" "0.4")
COLOR1_RGBA_BORDER=$(hex_to_rgba "$COLOR1" "0.6")
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.2")
BG_DARK=$(hex_to_rgba "$BACKGROUND" "0.5")

# Create backup
if [ -f "$OUTPUT_FILE" ]; then
    cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
fi

# Generate the CSS file
cat > "$OUTPUT_FILE" <<EOF
/*
 _   _ _____ ____    _  _____ _____
| | | | ____/ ___|  / \|_   _| ____|     /\_/\
| |_| |  _|| |     / _ \ | | |  _|      ( o.o )
|  _  | |__| |___ / ___ \| | | |___      > ^ <
|_| |_|_____\____/_/   \_\_| |_____|

 Waybar Dynamic Theme - Generated from Pywal
 Generated: $(date '+%d-%m-%y %H:%M:%S') */

/* ==================== FONT & BASE SETTINGS ==================== */
* {
	font-family: "Inter", "Noto Sans", sans-serif;
	font-weight: 500;
	min-height: 0;
	font-size: 13px;
}

/* ==================== WAYBAR WINDOW ==================== */
window#waybar {
	background: #15151c;
	color: #c4c4c6;
	border: none;
	border-bottom: 2px solid rgba(75, 125, 194, 0.15);
	padding: 4px 12px;
}

window#waybar.hidden {
	opacity: 0.2;
}

window#waybar.empty,
window#waybar.empty #window {
	border: none;
	background-color: ${BACKGROUND};
}

/* ==================== WORKSPACES ==================== */
#workspaces {
	background: transparent;
	padding: 0px 4px;
}

#workspaces button {
	color: ${COLOR8};
	border-radius: 10px;
	padding: 4px 12px;
	margin: 0px 3px;
	background: transparent;
	border: 2px solid transparent;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
	font-size: 11px;
}

#workspaces button:hover {
	color: ${COLOR4};
}

#workspaces button.active {
	color: ${FOREGROUND};
	font-weight: 600;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
#workspaces button.active:hover {
	color: ${COLOR4};
	font-weight: 600;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#workspaces button.urgent {
	color: ${COLOR1};
	background: ${COLOR1_RGBA};
	border: 2px solid ${COLOR1};
	animation: urgent-pulse 1s ease-in-out infinite;
}

/* ==================== MODULE STYLES ==================== */
#clock,
#cpu,
#disk,
#memory,
#mode,
#power-profiles-daemon,
#temperature,
#tray,
#window,
#idle_inhibitor,
#custom-swaync,
#bluetooth,
#network {
	padding: 4px 10px;
	margin: 0px 2px;
	border-radius: 8px;
	background: transparent;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#bluetooth:hover,
#cpu:hover,
#disk:hover,
#memory:hover,
#mode:hover,
#temperature:hover,
#tray:hover,
#window:hover,
#idle_inhibitor:hover,
#pulseaudio:hover,
#custom-swaync:hover,
#network:hover {
	color: ${COLOR4};
    background-color: transparent;
}

/* ==================== APP DRAWER ==================== */
#custom-dMenu {
	margin-left: 8px;
	padding: 4px 12px;
	font-size: 18px;
	color: ${FOREGROUND};
	border-radius: 10px;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#custom-dMenu:hover {
	color: ${COLOR4};
}

/* ==================== CLOCK ==================== */
#clock {
	color: ${FOREGROUND};
	font-weight: 600;
	padding: 4px 16px;
	margin: 0px 8px;
}

/* ==================== CPU & MEMORY ==================== */
#cpu {
	color: ${FOREGROUND};
	font-weight: 500;
}

#cpu.warning {
	color: #EDED2D;
}

#cpu.critical {
	color: #B01E1E;
	animation: critical-blink 1s ease-in-out infinite;
}

#memory {
	color: ${FOREGROUND};
	font-weight: 500;
}

#memory.warning {
	color: #EDED2D;
}

#memory.critical {
	color: #B01E1E;
	animation: critical-blink 1s ease-in-out infinite;
}


/* ==================== DISK ==================== */
#disk {
	color: ${FOREGROUND};
}

/* ==================== TEMPERATURE ==================== */
#temperature {
	color: ${FOREGROUND};
}

#temperature.critical {
	color: #B01E1E;
	animation: critical-blink 1s ease-in-out infinite;
}

/* ==================== AUDIO ==================== */
#pulseaudio {
	color: ${FOREGROUND};
	padding: 4px 10px;
	font-size: 16px;
}

#pulseaudio.muted {
	color: ${COLOR8};
	opacity: 0.6;
}

#pulseaudio#microphone {
	color: ${FOREGROUND};
	font-size: 14px;
}

#pulseaudio#microphone.source-muted {
	color: ${COLOR8};
	opacity: 0.6;
}

/* ==================== IDLE INHIBITOR ==================== */
#idle_inhibitor {
	color: ${COLOR8};
}

#idle_inhibitor.activated {
	color: ${COLOR10};
	background: ${COLOR4_RGBA};
}

/* ==================== POWER PROFILES ==================== */
#power-profiles-daemon {
	color: #c3c3c7;
}

#power-profiles-daemon.performance {
	color: #3b9bff;
}

#power-profiles-daemon.power-saver {
	color: #e1992a;
}

/* ==================== WINDOW TITLE ==================== */
#window {
	color: ${COLOR4};
	font-weight: 600;
	padding: 4px 16px;
}

#window.empty {
	padding: 0px;
	margin: 0px;
}

#custom-app_drawer_button {
	padding: 4px 12px;
	margin-left: 3px;
}

/* ==================== NOTIFICATIONS ==================== */
#custom-swaync {
	color: ${FOREGROUND};
	font-size: 16px;
}

/* ==================== POWER BUTTON ==================== */
#custom-power {
	color: ${FOREGROUND};
	padding: 4px 12px;
	margin: 0px 4px;
	font-size: 16px;
	font-weight: 600;
	border-radius: 8px;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#custom-power:hover {
	color: ${COLOR1};
}

/* ==================== TRAY ==================== */
#tray {
	padding: 4px 8px;
}

#tray > .passive {
	-gtk-icon-effect: dim;
}

#tray > .needs-attention {
	-gtk-icon-effect: highlight;
	background: ${COLOR1_RGBA};
	border-radius: 6px;
}

#tray menu {
	background: ${COLOR0};
	color: ${FOREGROUND};
	border: 1px solid ${COLOR4_RGBA};
	border-radius: 8px;
	padding: 4px;
}

/* ==================== NETWORK ==================== */
#network {
	color: ${FOREGROUND};
	font-size: 16px;
	padding: 4px 10px;
}

#network.connected {
	color: ${COLOR10};
}

#network.disconnected {
	color: ${COLOR1};
	opacity: 0.6;
}

#network.disabled {
	color: ${COLOR8};
	opacity: 0.5;
}

/* ==================== BLUETOOTH ==================== */
#bluetooth {
	color: ${FOREGROUND};
	font-size: 16px;
	padding: 4px 10px;
}

#bluetooth.connected {
	color: ${COLOR12};
}

#bluetooth.disabled {
	color: ${COLOR8};
	opacity: 0.5;
}

/* ==================== TASKBAR (DOCK) ==================== */
#taskbar {
	padding: 2px 8px;
	border-radius: 10px;
	margin: 2px 4px;
	box-shadow: 0 2px 8px ${BG_RGBA};
}

#taskbar button {
	padding: 4px 10px;
	margin: 0px 2px;
	border-radius: 6px;
	background: transparent;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#taskbar button.urgent {
	background: ${COLOR1_RGBA};
	border: 2px solid ${COLOR1};
	animation: urgent-pulse 1s ease-in-out infinite;
}

#taskbar button.minimized {
	opacity: 0.5;
	background: ${BG_RGBA};
}

#taskbar.empty {
	background: transparent;
	box-shadow: none;
	border: none;
}

/* ==================== DRAWER GROUPS ==================== */
.drawer-child {
	opacity: 0.8;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.drawer-child:hover {
	opacity: 1;
}

/* ==================== TOOLTIPS ==================== */
tooltip {
	background: ${COLOR0};
	color: ${FOREGROUND};
	border: 1px solid ${COLOR4_RGBA_HOVER};
	border-radius: 8px;
	padding: 8px 12px;
	font-size: 12px;
}

tooltip label {
	color: ${FOREGROUND};
}
EOF

# Verify file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create CSS file"
    exit 1
fi

echo "✓ Waybar theme updated (BG: $BACKGROUND, Hover: $COLOR4)"

# Reload Waybar
if pgrep -x waybar > /dev/null; then
    pkill -SIGUSR2 waybar
    echo "✓ Waybar reloaded"
else
    echo "! Waybar is not running"
fi

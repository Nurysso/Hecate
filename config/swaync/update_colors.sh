#!/usr/bin/env bash

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

COLOR_FILE="$HOME/.cache/wal/colors.json"
OUTPUT_FILE="$HOME/.config/swaync/style.css"

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

    # Validate hex format
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
BG_RGBA=$(hex_to_rgba "$BACKGROUND" "0.85")
BG_RGBA_LIGHT=$(hex_to_rgba "$BACKGROUND" "0.7")
BG_RGBA_LIGHTER=$(hex_to_rgba "$BACKGROUND" "0.5")
COLOR1_RGBA=$(hex_to_rgba "$COLOR1" "0.4")
COLOR1_RGBA_LIGHT=$(hex_to_rgba "$COLOR1" "0.3")
COLOR1_RGBA_DIM=$(hex_to_rgba "$COLOR1" "0.1")
COLOR4_RGBA=$(hex_to_rgba "$COLOR4" "0.5")
COLOR4_RGBA_LIGHT=$(hex_to_rgba "$COLOR4" "0.4")
COLOR4_RGBA_DIM=$(hex_to_rgba "$COLOR4" "0.3")
COLOR4_RGBA_BORDER=$(hex_to_rgba "$COLOR4" "0.2")

# Create backup of existing CSS
if [ -f "$OUTPUT_FILE" ]; then
    cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
fi

# Create the CSS file
cat > "$OUTPUT_FILE" <<EOF
/*
  _   _ _____ ____    _  _____ _____
 | | | | ____/ ___|  / \|_   _| ____|     /\_/\
 | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
 |  _  | |__| |___ / ___ \| | | |___      > ^ <
 |_| |_|_____\____/_/   \_\_| |_____|

SwayNC Dynamic Theme - Generated from Pywal
Generated: 2025-10-05 22:04:09 */

@define-color cc-bg ${BG_RGBA};

* {
  all: unset;
  font-family: "FiraCode Nerd Font", monospace;
  font-size: 14px;
  transition: 200ms;
}

/* Main notification window */
.notification-row {
  outline: none;
  margin: 8px;
}

.notification-row:focus,
.notification-row:hover {
  background: ${COLOR1_RGBA_DIM};
}

.notification {
  background: ${BG_RGBA_LIGHT};
  border-radius: 16px;
  margin: 0px;
  padding: 0;
  border: 2px solid ${COLOR4_RGBA};
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.notification-content {
  background: transparent;
  padding: 12px;
  border-radius: 16px;
}

.close-button {
  background: ${COLOR1_RGBA_LIGHT};
  color: ${FOREGROUND};
  text-shadow: none;
  padding: 0;
  border-radius: 50%;
  margin-top: 8px;
  margin-right: 8px;
  min-width: 24px;
  min-height: 24px;
}

.close-button:hover {
  background: ${COLOR9};
  color: ${BACKGROUND};
}

.notification-default-action {
  margin: 0;
  padding: 0;
  border-radius: 16px;
}

/* Notification content */
.summary {
  font-size: 15px;
  font-weight: bold;
  color: ${COLOR4};
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
}

.time {
  font-size: 12px;
  font-weight: normal;
  color: ${COLOR8};
}

.body {
  font-size: 13px;
  font-weight: normal;
  color: ${FOREGROUND};
  margin-top: 6px;
}

/* Notification icon */
.notification-default-action .notification-content .image {
  margin-right: 10px;
}

.notification-default-action .notification-content .app-icon {
  margin-right: 10px;
}

/* Control Center */
.control-center {
  background: @cc-bg;
  border-radius: 20px;
  margin: 8px;
  border: 2px solid ${COLOR4_RGBA_LIGHT};
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
}

.control-center-list {
  background: transparent;
}

.control-center-list-placeholder {
  opacity: 0.5;
  color: ${FOREGROUND};
  font-size: 16px;
  margin: 20px;
}

/* Widgets */
.widget-title {
  background: transparent;
  color: ${COLOR4};
  font-size: 18px;
  font-weight: bold;
  padding: 16px;
  margin: 8px 8px 4px 8px;
  border-radius: 12px;
}

.widget-title > button {
  background: ${COLOR1_RGBA_LIGHT};
  color: ${FOREGROUND};
  border-radius: 8px;
  padding: 6px 12px;
  border: 1px solid ${COLOR4_RGBA_DIM};
}

.widget-title > button:hover {
  background: ${COLOR4_RGBA_LIGHT};
  border: 1px solid ${COLOR4};
}

/* DND Widget */
.widget-dnd {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px;
  padding: 12px;
  margin: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
  color: ${COLOR4};
  font-size: 14px;
  font-weight: bold;
}

.widget-dnd > switch {
  background: ${COLOR1_RGBA};
  border-radius: 20px;
  border: none;
  min-width: 50px;
  min-height: 26px;
}

.widget-dnd > switch:checked {
  background: ${COLOR4};
}

.widget-dnd > switch slider {
  background: ${FOREGROUND};
  border-radius: 50%;
  min-width: 20px;
  min-height: 20px;
}

/* Label Widget */
.widget-label {
  background: transparent;
  color: ${COLOR8};
  font-size: 13px;
  margin: 8px;
  padding: 8px;
}

/* Buttons Grid */
.widget-buttons-grid {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px;
  padding: 12px;
  margin: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
}

.widget-buttons-grid > flowbox > flowboxchild > button {
  background: ${COLOR1_RGBA};
  border-radius: 10px;
  color: ${FOREGROUND};
  font-size: 40px;
  padding: 2px;
  margin: 4px;
  border: 1px solid ${COLOR4_RGBA_BORDER};
  min-width: 60px;
  min-height: 60px;
}

.widget-buttons-grid > flowbox > flowboxchild > button:hover {
  background: ${COLOR4_RGBA_LIGHT};
  border: 1px solid ${COLOR4};
  color: ${COLOR4};
}

.widget-buttons-grid > flowbox > flowboxchild > button:active {
  background: ${COLOR4};
  color: ${BACKGROUND};
}

/* MPRIS Widget */
.widget-mpris {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px;
  padding: 12px;
  margin: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
}

.widget-mpris-player {
  background: transparent;
  padding: 8px;
}

.widget-mpris-title {
  color: ${COLOR4};
  font-weight: bold;
  font-size: 14px;
}

.widget-mpris-subtitle {
  color: ${COLOR8};
  font-size: 12px;
}

.widget-mpris > box > button {
  background: ${COLOR1_RGBA};
  color: ${FOREGROUND};
  border-radius: 8px;
  border: 1px solid ${COLOR4_RGBA_BORDER};
  padding: 8px;
  margin: 2px;
}

.widget-mpris > box > button:hover {
  background: ${COLOR4_RGBA_LIGHT};
  color: ${COLOR4};
}

.widget-mpris-album-art {
  border-radius: 8px;
}

/* Volume Widget */
.widget-volume {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px;
  padding: 12px;
  margin: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
  color: ${FOREGROUND};
}

.widget-volume > box > label {
  color: ${COLOR4};
  font-size: 18px;
  margin-right: 12px;
  min-width: 24px;
}

.widget-volume > box > scale {
  background: transparent;
}

.widget-volume > box > scale trough {
  background: ${COLOR1_RGBA};
  border-radius: 8px;
  min-height: 8px;
  min-width: 200px;
}

.widget-volume > box > scale trough highlight {
  background: ${COLOR4};
  border-radius: 8px;
}

.widget-volume > box > scale trough slider {
  background: ${FOREGROUND};
  border-radius: 50%;
  min-height: 18px;
  min-width: 18px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
  border: 2px solid ${COLOR4};
}

/* Backlight Widget */
.widget-backlight {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px;
  padding: 12px;
  margin: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
  color: ${FOREGROUND};
}

.widget-backlight > box > label {
  color: ${COLOR4};
  font-size: 18px;
  margin-right: 12px;
  min-width: 24px;
}

.widget-backlight > box > scale trough {
  background: ${COLOR1_RGBA};
  border-radius: 8px;
  min-height: 8px;
  min-width: 200px;
}

.widget-backlight > box > scale trough highlight {
  background: ${COLOR11};
  border-radius: 8px;
}

.widget-backlight > box > scale trough slider {
  background: ${FOREGROUND};
  border-radius: 50%;
  min-height: 18px;
  min-width: 18px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
  border: 2px solid ${COLOR11};
}

/* Notification actions */
.notification-action {
  background: ${COLOR1_RGBA};
  color: ${FOREGROUND};
  border-radius: 8px;
  margin: 4px;
  padding: 8px 16px;
  border: 1px solid ${COLOR4_RGBA_BORDER};
}

.notification-action:hover {
  background: ${COLOR4_RGBA_LIGHT};
  border: 1px solid ${COLOR4};
}

.notification-action:active {
  background: ${COLOR4};
  color: ${BACKGROUND};
}

/* Inline reply */
.inline-reply {
  background: ${COLOR1_RGBA};
  color: ${FOREGROUND};
  border-radius: 8px;
  padding: 8px;
  margin: 4px;
  border: 1px solid ${COLOR4_RGBA_BORDER};
}

.inline-reply:focus {
  border: 1px solid ${COLOR4};
}

.inline-reply-button {
  background: ${COLOR4};
  color: ${BACKGROUND};
  border-radius: 8px;
  padding: 6px 12px;
  margin-left: 4px;
}

.inline-reply-button:hover {
  background: ${COLOR12};
}

/* Scrollbar */
scrollbar {
  background: transparent;
  min-width: 8px;
}

scrollbar trough {
  background: ${COLOR1_RGBA_DIM};
  border-radius: 8px;
}

scrollbar slider {
  background: ${COLOR4_RGBA};
  border-radius: 8px;
  min-height: 40px;
}

scrollbar slider:hover {
  background: ${COLOR4};
}

/* Critical notifications */
.critical {
  border: 2px solid ${COLOR9};
}

.critical .notification-action {
  border: 1px solid ${COLOR9};
}

/* Low priority */
.low {
  border: 2px solid ${COLOR8};
}

/* Notification groups */
.notification-group {
  margin: 8px;
}

.notification-group-headers {
  background: ${BG_RGBA_LIGHTER};
  border-radius: 12px 12px 0 0;
  padding: 8px;
  border: 1px solid ${COLOR4_RGBA_DIM};
  border-bottom: none;
  color: ${COLOR4};
  font-weight: bold;
}

.notification-group-icon {
  color: ${COLOR4};
}

.notification-group-collapse-button {
  background: ${COLOR1_RGBA};
  color: ${FOREGROUND};
  border-radius: 6px;
  padding: 4px 8px;
}

.notification-group-collapse-button:hover {
  background: ${COLOR4_RGBA_LIGHT};
}

.notification-group-close-all-button {
  background: ${COLOR1_RGBA};
  color: ${FOREGROUND};
  border-radius: 6px;
  padding: 4px 8px;
  margin-left: 4px;
}

.notification-group-close-all-button:hover {
  background: ${COLOR9};
  color: ${BACKGROUND};
}
EOF

# Verify CSS file was created successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Failed to create CSS file"
    exit 1
fi

# Wait a moment for file to be fully written
sleep 0.2

# Reload SwayNC with retry logic
reload_swaync() {
    if pgrep -x swaync > /dev/null; then
        # Try to reload up to 3 times
        for i in {1..3}; do
            if swaync-client -rs 2>/dev/null; then
                return 0
            fi
            sleep 0.3
        done
        echo "Warning: SwayNC reload may have failed, trying restart..."
        pkill swaync
        sleep 0.5
        swaync &
        disown
        return 0
    else
        swaync &
        disown
        return 0
    fi
}
reload_swaync

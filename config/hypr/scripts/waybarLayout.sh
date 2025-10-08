#!/bin/bash
# Script for waybar layout or configs

#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

set -euo pipefail
IFS=$'\n\t'

# Define directories
WAYBAR_LAYOUTS="$HOME/.config/waybar/configs"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
ROFI_CONFIG="$HOME/.config/rofi/config-waybar-layout.rasi"
MSG='🎌 NOTE: Some waybar LAYOUTS NOT fully compatible with some STYLES'
MARKER="✓"

# Check required directories
if [[ ! -d "$WAYBAR_LAYOUTS" ]]; then
	notify-send -u critical "Waybar Layout" "Layouts directory not found: $WAYBAR_LAYOUTS"
	exit 1
fi

# Apply selected configuration
apply_config() {
	local config="$1"

	if [[ ! -f "$WAYBAR_LAYOUTS/$config" ]]; then
		notify-send -u critical "Waybar Layout" "Configuration not found: $config"
		exit 1
	fi

	ln -sf "$WAYBAR_LAYOUTS/$config" "$WAYBAR_CONFIG"

	if [[ -x "$SCRIPTSDIR/Refresh.sh" ]]; then
		"$SCRIPTSDIR/Refresh.sh" &
	else
		# Fallback: restart waybar manually
		pkill waybar || true
		waybar &
	fi
}

main() {
	# Resolve current symlink target and basename
	local current_target current_name
	current_target=$(readlink -f "$WAYBAR_CONFIG" 2>/dev/null || echo "")
	current_name=$(basename "$current_target" 2>/dev/null || echo "")

	# Build sorted list of available layouts
	local options=()
	mapfile -t options < <(
		find -L "$WAYBAR_LAYOUTS" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | sort
	)

	if [[ ${#options[@]} -eq 0 ]]; then
		notify-send -u critical "Waybar Layout" "No layouts found in $WAYBAR_LAYOUTS"
		exit 1
	fi

	# Add "no panel" option
	options=("no panel (Hides waybar)" "${options[@]}")

	# Mark and locate the active layout
	local default_row=0
	for i in "${!options[@]}"; do
		if [[ "${options[i]}" == "$current_name" ]]; then
			options[i]="$MARKER ${options[i]}"
			default_row=$i
			break
		fi
	done

	# Launch rofi with the annotated list, pre-selecting the active row
	local choice
	choice=$(
		printf '%s\n' "${options[@]}" |
			rofi -i -dmenu \
				-config "$ROFI_CONFIG" \
				-mesg "$MSG" \
				-selected-row "$default_row" \
				-p "Waybar Layout"
	) || {
		echo "No option selected. Exiting."
		exit 0
	}

	# Exit if nothing chosen
	[[ -z "$choice" ]] && {
		echo "No option selected. Exiting."
		exit 0
	}

	# Strip marker before applying
	choice="${choice#$MARKER }"

	case "$choice" in
	"no panel")
		if pgrep -x waybar >/dev/null; then
			pkill waybar
			notify-send "Waybar" "Panel hidden"
		fi
		;;
	*)
		apply_config "$choice"
		notify-send "Waybar Layout" "Applied: $choice"
		;;
	esac
}

# Kill Rofi if already running before execution
if pgrep -x rofi >/dev/null; then
	pkill rofi
	sleep 0.1
fi

main

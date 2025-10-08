#!/bin/bash

# Hyprland Plugin Installer
# Run this script after logging into Hyprland

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FLAG_FILE="$HOME/.config/hypr/.plugins_installed"

# Check if plugins were already installed
if [ -f "$FLAG_FILE" ]; then
	exit 0
fi

# Check if running in Hyprland
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
	echo -e "${RED}Error: This script must be run inside a Hyprland session!${NC}"
	exit 1
fi

# Check if gum is installed
if ! command -v gum &>/dev/null; then
	echo -e "${RED}Error: gum is not installed!${NC}"
	exit 1
fi

# Check if hyprpm is available
if ! command -v hyprpm &>/dev/null; then
	gum style --foreground 196 "Error: hyprpm not found!"
	touch "$FLAG_FILE"
	exit 1
fi

gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Installer"
gum style --foreground 220 "First-time Hyprland setup detected!"
echo ""

if ! gum confirm "Would you like to install Hyprland plugins now?"; then
	gum style --foreground 220 "You can run this script later manually: install-hyprland-plugins.sh"
	touch "$FLAG_FILE"
	exit 0
fi

# Update hyprpm headers
gum style --foreground 220 "Updating hyprpm headers..."
if hyprpm update; then
	gum style --foreground 82 "✓ Headers updated successfully!"
else
	gum style --foreground 196 "✗ Failed to update headers!"
	touch "$FLAG_FILE"
	exit 1
fi

# Ask which plugins to install
plugins=(hyprexpo border-plus-plus hyprfocus)

# Install selected plugins
echo "$plugins" | while IFS= read -r plugin; do
	[ -z "$plugin" ] && continue

	gum style --foreground 220 "Installing: $plugin"

	case "$plugin" in
	hyprexpo | border-plus-plus)
		if hyprpm add https://github.com/hyprwm/hyprland-plugins; then
			if hyprpm enable "$plugin"; then
				gum style --foreground 82 "✓ $plugin installed and enabled!"
			else
				gum style --foreground 196 "✗ Failed to enable $plugin"
			fi
		else
			gum style --foreground 196 "✗ Failed to add hyprland-plugins repository"
		fi
		;;
	hyprfocus)
		if hyprpm add https://github.com/pyt0xic/hyprfocus; then
			if hyprpm enable hyprfocus; then
				gum style --foreground 82 "✓ hyprfocus installed and enabled!"
			else
				gum style --foreground 196 "✗ Failed to enable hyprfocus"
			fi
		else
			gum style --foreground 196 "✗ Failed to add hyprfocus repository"
		fi
		;;
	esac

	sleep 1
done

echo ""
gum style --foreground 82 "✓ Plugin installation complete!"
gum style --foreground 220 "Reloading Hyprland configuration..."

# Mark as installed
touch "$FLAG_FILE"

# Reload Hyprland
hyprctl reload

gum style --foreground 82 "✓ All done! This script will not run automatically again."
sleep 3

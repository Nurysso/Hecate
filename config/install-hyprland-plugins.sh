#!/bin/bash

# Hyprland Plugin Installer
# Run this script after logging into Hyprland

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
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

# Check if hyprpm is available
if ! command -v hyprpm &> /dev/null; then
    echo -e "${RED}Error: hyprpm not found!${NC}"
    touch "$FLAG_FILE"
    exit 1
fi

echo -e "${BLUE}${BOLD}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║  Hyprland Plugin Installer        ║${NC}"
echo -e "${BLUE}${BOLD}╚════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}First-time Hyprland setup detected!${NC}"
echo ""

# Ask for confirmation
read -p "Would you like to install Hyprland plugins now? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}You can run this script later manually: install-hyprland-plugins.sh${NC}"
    touch "$FLAG_FILE"
    exit 0
fi

# Update hyprpm headers
echo -e "${YELLOW}Updating hyprpm headers...${NC}"
if hyprpm update; then
    echo -e "${GREEN}✓ Headers updated successfully!${NC}"
else
    echo -e "${RED}✗ Failed to update headers!${NC}"
    touch "$FLAG_FILE"
    exit 1
fi

# Define plugins to install
plugins=("hyprexpo" "border-plus-plus" "hyprfocus")

# Install plugins
for plugin in "${plugins[@]}"; do
    echo ""
    echo -e "${YELLOW}Installing: $plugin${NC}"

    case "$plugin" in
        hyprexpo|border-plus-plus)
            if hyprpm add https://github.com/hyprwm/hyprland-plugins 2>/dev/null || true; then
                if hyprpm enable "$plugin"; then
                    echo -e "${GREEN}✓ $plugin installed and enabled!${NC}"
                else
                    echo -e "${RED}✗ Failed to enable $plugin${NC}"
                fi
            else
                echo -e "${RED}✗ Failed to add hyprland-plugins repository${NC}"
            fi
            ;;
        hyprfocus)
            if hyprpm add https://github.com/pyt0xic/hyprfocus; then
                if hyprpm enable hyprfocus; then
                    echo -e "${GREEN}✓ hyprfocus installed and enabled!${NC}"
                else
                    echo -e "${RED}✗ Failed to enable hyprfocus${NC}"
                fi
            else
                echo -e "${RED}✗ Failed to add hyprfocus repository${NC}"
            fi
            ;;
    esac

    sleep 1
done

echo ""
echo -e "${GREEN}✓ Plugin installation complete!${NC}"
echo -e "${YELLOW}Reloading Hyprland configuration...${NC}"

# Mark as installed
touch "$FLAG_FILE"

# Reload Hyprland
if hyprctl reload; then
    echo -e "${GREEN}✓ All done! This script will not run automatically again.${NC}"
else
    echo -e "${YELLOW}⚠ Hyprland reload had issues, but plugins are installed.${NC}"
fi

sleep 2

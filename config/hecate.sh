#!/bin/bash

# Hecate Dotfiles Manager
# Manages updates, configuration, and theme settings

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="$HOME/.config/hecate/hecate.toml"
HECATE_DIR="$HOME/Hecate"
REPO_URL="https://github.com/Aelune/Hecate.git"
UPDATE_SCRIPT_URL="https://raw.githubusercontent.com/Aelune/Hecate/main/update.sh"

# Ensure config directory exists
mkdir -p "$HOME/.config/hecate"

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Hecate config not found!${NC}"
    echo "Please run the Hecate installer first."
    exit 1
fi

# Parse TOML value
get_config_value() {
    local key="$1"
    grep "^$key" "$CONFIG_FILE" | cut -d '=' -f2 | tr -d ' "' || echo ""
}

# Update TOML value
set_config_value() {
    local key="$1"
    local value="$2"
    sed -i "s|^$key.*|$key = \"$value\"|" "$CONFIG_FILE"
}

# Rewrite hecate.toml with current values
rewrite_config() {
    local version="${1:-$(get_config_value "version")}"
    local install_date="${2:-$(get_config_value "install_date")}"
    local last_update="$(date +%Y-%m-%d)"
    local terminal="${3:-$(get_config_value "terminal")}"
    local shell="${4:-$(get_config_value "shell")}"
    local browser="${5:-$(get_config_value "browser")}"
    local profile="${6:-$(get_config_value "profile")}"
    local theme_mode="${7:-$(get_config_value "mode")}"

    cat > "$CONFIG_FILE" << EOF
# Hecate Dotfiles Configuration
# This file manages your Hecate installation settings

[metadata]
version = "$version"
install_date = "$install_date"
last_update = "$last_update"
repo_url = "$REPO_URL"

[preferences]
terminal = "$terminal"
shell = "$shell"
browser = "$browser"
profile = "$profile"

[theme]
# Theme mode: "dynamic" or "static"
# dynamic: Automatically updates system colors when wallpaper changes
# static: Keeps colors unchanged regardless of wallpaper
mode = "$theme_mode"

[autostart]
# Enable/disable components on startup
waypaper = true
waybar = true
swaync = true

[updates]
# Check for updates on startup
check_on_startup = true
# Auto-download updates (requires confirmation to install)
auto_download = false
EOF

    echo -e "${GREEN}✓ Configuration rewritten${NC}"
}

# Get current version
get_current_version() {
    get_config_value "version"
}

# Get remote version
get_remote_version() {
    local remote_version=$(curl -s "https://raw.githubusercontent.com/Aelune/Hecate/main/version.txt" 2>/dev/null || echo "")
    echo "$remote_version"
}

# Check network connectivity
check_network() {
    local silent="${1:-false}"

    if [ "$silent" = "false" ]; then
        echo -e "${BLUE}Checking network connection...${NC}"
    fi

    # Try multiple methods to check connectivity
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null || \
       ping -c 1 -W 2 1.1.1.1 &> /dev/null || \
       curl -s --max-time 3 https://www.google.com &> /dev/null; then

        if [ "$silent" = "false" ]; then
            echo -e "${GREEN}✓ Network connected${NC}"
        fi

        # Send notification if in graphical environment
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            notify-send "Network Status" "✓ Connected to network" -u low -t 3000
        fi
        return 0
    else
        if [ "$silent" = "false" ]; then
            echo -e "${RED}✗ No network connection${NC}"
        fi

        # Send notification if in graphical environment
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            notify-send "Network Status" "✗ No network connection" -u critical -t 5000
        fi
        return 1
    fi
}

# Startup check (network + updates)
startup_check() {
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo -e "${CYAN}   Hecate Startup Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════${NC}"
    echo ""

    # Check network
    if check_network "false"; then
        echo ""
        # If network available, check for updates
        check_updates "silent"
    else
        echo ""
        echo -e "${YELLOW}Skipping update check (no network)${NC}"
    fi
}

# Check for updates
check_updates() {
    local mode="${1:-normal}"

    if [ "$mode" = "normal" ]; then
        echo -e "${BLUE}═══════════════════════════════════${NC}"
        echo -e "${CYAN}    Checking for Hecate Updates${NC}"
        echo -e "${BLUE}═══════════════════════════════════${NC}"
        echo ""
    fi

    local current_version=$(get_current_version)
    local remote_version=$(get_remote_version)

    if [ -z "$remote_version" ]; then
        echo -e "${YELLOW}⚠ Unable to check for updates.${NC}"
        echo -e "${YELLOW}  Network error or repository unavailable.${NC}"
        return 1
    fi

    if [ "$mode" = "normal" ]; then
        echo -e "${BLUE}Current version:${NC} ${GREEN}$current_version${NC}"
        echo -e "${BLUE}Latest version:${NC}  ${GREEN}$remote_version${NC}"
        echo ""
    fi

    if [ "$current_version" != "$remote_version" ]; then
        if [ "$mode" = "normal" ]; then
            echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║  🎉 New version available!            ║${NC}"
            echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${YELLOW}Run:${NC} ${CYAN}hecate update${NC} ${YELLOW}to upgrade${NC}"
        fi

        # Send notification if in graphical environment
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            notify-send "Hecate Update Available" \
                "New version $remote_version is available!\n\nCurrent: $current_version\nRun: hecate update" \
                -u normal -t 10000
        fi
        return 0
    else
        if [ "$mode" = "normal" ]; then
            echo -e "${GREEN}✓ You are on the latest version!${NC}"
        fi
        return 1
    fi
}

# Update Hecate using update.sh from GitHub
update_hecate() {
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${CYAN}    Updating Hecate Dotfiles${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo ""

    # Check network first
    if ! check_network "true"; then
        echo -e "${RED}✗ Cannot update: No network connection${NC}"
        notify-send "Hecate Update Failed" "No network connection available" -u critical -t 5000
        exit 1
    fi

    # Download update.sh
    local update_script="/tmp/hecate-update.sh"
    echo -e "${YELLOW}Downloading update script...${NC}"

    if curl -fsSL "$UPDATE_SCRIPT_URL" -o "$update_script"; then
        chmod +x "$update_script"
        echo -e "${GREEN}✓ Update script downloaded${NC}"
        echo ""

        # Run update script
        bash "$update_script"

        # Clean up
        rm -f "$update_script"

        # Rewrite config with new version
        local new_version=$(get_remote_version)
        rewrite_config "$new_version"

        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ Update complete!                   ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"

    else
        echo -e "${RED}✗ Failed to download update script${NC}"
        notify-send "Hecate Update Failed" "Could not download update script" -u critical -t 5000
        exit 1
    fi
}

# Toggle theme mode
toggle_theme() {
    local current_mode=$(get_config_value "mode")

    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${CYAN}      Theme Mode Settings${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Current mode:${NC} ${YELLOW}$current_mode${NC}"
    echo ""

    if [ "$current_mode" = "dynamic" ]; then
        set_config_value "mode" "static"
        echo -e "${GREEN}✓ Theme mode set to:${NC} ${MAGENTA}static${NC}"
        echo ""
        echo -e "${YELLOW}Colors will NOT auto-update from wallpaper${NC}"

        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            notify-send "Hecate Theme" \
                "Theme mode: Static\n\nColors won't auto-update from wallpaper" \
                -u normal -t 5000
        fi
    else
        set_config_value "mode" "dynamic"
        echo -e "${GREEN}✓ Theme mode set to:${NC} ${MAGENTA}dynamic${NC}"
        echo ""
        echo -e "${YELLOW}Colors WILL auto-update from wallpaper${NC}"

        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            notify-send "Hecate Theme" \
                "Theme mode: Dynamic\n\nColors will auto-update from wallpaper" \
                -u normal -t 5000
        fi
    fi
}

# Show info
show_info() {
    local version=$(get_config_value "version")
    local install_date=$(get_config_value "install_date")
    local last_update=$(get_config_value "last_update")
    local theme_mode=$(get_config_value "mode")
    local terminal=$(get_config_value "terminal")
    local shell=$(get_config_value "shell")
    local browser=$(get_config_value "browser")
    local profile=$(get_config_value "profile")

    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}        ${GREEN}Hecate Dotfiles Info${NC}          ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}System Information:${NC}"
    echo -e "  ${BLUE}Version:${NC}        ${GREEN}$version${NC}"
    echo -e "  ${BLUE}Installed:${NC}      ${YELLOW}$install_date${NC}"
    echo -e "  ${BLUE}Last Update:${NC}    ${YELLOW}$last_update${NC}"
    echo -e "  ${BLUE}Theme Mode:${NC}     ${MAGENTA}$theme_mode${NC}"
    echo ""
    echo -e "${CYAN}User Preferences:${NC}"
    echo -e "  ${BLUE}Terminal:${NC}       $terminal"
    echo -e "  ${BLUE}Shell:${NC}          $shell"
    echo -e "  ${BLUE}Browser:${NC}        $browser"
    echo -e "  ${BLUE}Profile:${NC}        $profile"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${GREEN}hecate check${NC}     - Check for updates"
    echo -e "  ${GREEN}hecate update${NC}    - Update dotfiles"
    echo -e "  ${GREEN}hecate theme${NC}     - Toggle theme mode"
    echo -e "  ${GREEN}hecate network${NC}   - Check network status"
    echo ""
}

# Show help
show_help() {
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}     ${GREEN}Hecate Dotfiles Manager${NC}         ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC} hecate ${YELLOW}[command]${NC}"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${GREEN}startup${NC}       Run startup checks (network + updates)"
    echo -e "  ${GREEN}network${NC}       Check network connectivity"
    echo -e "  ${GREEN}check${NC}         Check for updates"
    echo -e "  ${GREEN}update${NC}        Update Hecate dotfiles"
    echo -e "  ${GREEN}theme${NC}         Toggle theme mode (dynamic/static)"
    echo -e "  ${GREEN}info${NC}          Show installation info"
    echo -e "  ${GREEN}help${NC}          Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  ${YELLOW}hecate startup${NC}    # Check network and updates on startup"
    echo -e "  ${YELLOW}hecate network${NC}    # Check if network is connected"
    echo -e "  ${YELLOW}hecate check${NC}      # Check if updates are available"
    echo -e "  ${YELLOW}hecate update${NC}     # Update to latest version"
    echo -e "  ${YELLOW}hecate theme${NC}      # Switch between dynamic/static theme"
    echo ""
    echo -e "${CYAN}Theme Modes:${NC}"
    echo -e "  ${MAGENTA}dynamic${NC}       - Colors auto-update from wallpaper"
    echo -e "  ${MAGENTA}static${NC}        - Colors stay unchanged"
    echo ""
}

# Main command handler
case "${1:-help}" in
    startup)
        startup_check
        ;;
    network)
        check_network "false"
        ;;
    check)
        check_updates
        ;;
    update)
        if check_updates; then
            echo ""
            read -p "$(echo -e ${YELLOW}Do you want to update? [y/N]: ${NC})" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                update_hecate
            else
                echo -e "${YELLOW}Update cancelled.${NC}"
            fi
        fi
        ;;
    theme)
        toggle_theme
        ;;
    info)
        show_info
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esactoggle_theme
        ;;
    info)
        show_info
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

#!/bin/bash

# Hyprland Dotfiles Installer with Gum
# Description: Interactive installer for Hyprland configuration

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

SCRIPT_BASE_URL="https://raw.githubusercontent.com/Aelune/Hecate/refs/heads/dev/scripts/install"
OS=""
PACKAGE_MANAGER=""

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    arch | manjaro | endeavouros | cachyos)
      OS="arch"
      ;;
    fedora)
      OS="fedora"
      ;;
    ubuntu | debian | pop | linuxmint)
      OS="ubuntu"
      ;;
    *)
      echo -e "${RED}Error: OS '$ID' is not supported!${NC}"
      exit 1
      ;;
    esac
  else
    echo -e "${RED}Error: Cannot detect OS!${NC}"
    exit 1
  fi
}

# Install gum based on detected OS
install_gum() {
  echo -e "${YELLOW}Installing gum...${NC}"
  echo ""

  case "$OS" in
  arch)
    if command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm gum
    else
      echo -e "${RED}pacman not found!${NC}"
      return 1
    fi
    ;;
  fedora)
    if command -v dnf &>/dev/null; then
      sudo dnf install -y gum
    else
      echo -e "${RED}dnf not found!${NC}"
      return 1
    fi
    ;;
  ubuntu)
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
    ;;
  *)
    echo -e "${RED}Unsupported OS for automatic gum installation${NC}"
    return 1
    ;;
  esac

  if command -v gum &>/dev/null; then
    echo -e "${GREEN}✓ Gum installed successfully!${NC}"
    return 0
  else
    echo -e "${RED}✗ Gum installation failed!${NC}"
    return 1
  fi
}

# Check if gum is installed, offer to install if not
check_gum() {
  if ! command -v gum &>/dev/null; then
    echo -e "${RED}Gum is not installed!${NC}"
    echo -e "${YELLOW}Gum is required for this installer to work.${NC}"
    echo ""

    # Prompt user to install
    read -p "Would you like to install gum now? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if install_gum; then
        echo ""
        echo -e "${GREEN}Continuing with installation...${NC}"
        echo ""
        sleep 1
      else
        echo -e "${RED}Failed to install gum. Exiting.${NC}"
        exit 1
      fi
    else
      echo ""
      echo -e "${YELLOW}Installation cancelled.${NC}"
      echo -e "${BLUE}Install gum manually and run this script again.${NC}"
      echo ""
      echo "Manual installation instructions:"
      case "$OS" in
      arch)
        echo -e "${GREEN}  sudo pacman -S gum${NC}"
        ;;
      fedora)
        echo -e "${GREEN}  sudo dnf install gum${NC}"
        ;;
      ubuntu)
        echo -e "${GREEN}  sudo mkdir -p /etc/apt/keyrings${NC}"
        echo -e "${GREEN}  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg${NC}"
        echo -e "${GREEN}  echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list${NC}"
        echo -e "${GREEN}  sudo apt update && sudo apt install gum${NC}"
        ;;
      *)
        echo "  Visit: https://github.com/charmbracelet/gum"
        ;;
      esac
      echo ""
      exit 1
    fi
  fi
}

# Check OS and display appropriate messages
check_OS() {
  case "$OS" in
  arch)
    gum style --foreground 82 "✓ Detected OS: Arch Linux"
    ;;
  fedora)
    gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
    gum style --foreground 220 "Proceed at your own risk or follow the Fedora guide if available at:"
    gum style --foreground 220 "https://github.com/Aelune/Hecate/tree/main/documentation/install-fedora.md"
    if ! gum confirm "Continue with Fedora installation?"; then
      exit 1
    fi
    ;;
  ubuntu)
    gum style --foreground 220 --bold "⚠️ Warning: Ubuntu/Debian-based OS detected!"
    gum style --foreground 220 "Hecate installer support for Ubuntu is experimental."
    gum style --foreground 220 "Manual installation instructions:"
    gum style --foreground 220 "https://github.com/Aelune/Hecate/tree/main/documentation/install-ubuntu.md"
    if ! gum confirm "Continue with Ubuntu installation?"; then
      exit 1
    fi
    ;;
  esac
}

# Download and execute OS-specific installation script
run_os_script() {
  local script_name="${OS}.sh"
  local script_url="${SCRIPT_BASE_URL}/${script_name}"
  local temp_script="/tmp/hecate_install_${OS}.sh"

  gum style --foreground 82 "Downloading ${OS} installation script..."
  echo ""

  if curl -fsSL "$script_url" -o "$temp_script"; then
    gum style --foreground 82 "✓ Script downloaded successfully"
    chmod +x "$temp_script"

    echo ""
    gum style --foreground 220 "Executing ${OS} installation script..."
    echo ""

    # Execute the script
    if bash "$temp_script"; then
      gum style --foreground 82 "✓ Installation script completed successfully"
    else
      gum style --foreground 196 "✗ Installation script failed"
      rm -f "$temp_script"
      exit 1
    fi

    # Clean up
    rm -f "$temp_script"
  else
    gum style --foreground 196 "✗ Failed to download installation script from:"
    gum style --foreground 196 "  $script_url"
    echo ""
    gum style --foreground 220 "Please check:"
    gum style --foreground 220 "  1. Your internet connection"
    gum style --foreground 220 "  2. The script exists in the repository"
    gum style --foreground 220 "  3. The URL is correct"
    exit 1
  fi
}

# Main function
main() {
  # Parse arguments
  case "${1:-}" in
  --help | -h)
    clear
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  • gum - Interactive CLI tool"
    echo "    (Will be installed automatically if missing)"
    echo ""
    echo "  • paru (recommended) - AUR helper (Arch only)"
    echo "    Install: https://github.com/Morganamilo/paru#installation"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./install.sh          Run the installer"
    echo "  ./install.sh --help   Show this message"
    echo "  ./install.sh --dry-run   ...why though?"
    echo ""
    echo "Supported distributions: Arch, Fedora, Ubuntu/Debian"
    exit 0
    ;;
  --dry-run)
    echo -e "${BLUE}The \"I want to feel productive without doing anything mode\"${NC}"
    echo -e "${YELLOW}Simulating installation...${NC}"
    sleep 1
    echo ""
    echo -e "${GREEN}✓ System check: Passed (probably)${NC}"
    echo -e "${GREEN}✓ Packages: Would install ~47 packages${NC}"
    echo -e "${GREEN}✓ Configs: Would copy lots of dotfiles${NC}"
    echo ""
    echo -e "${YELLOW}Congratulations! You've successfully done... nothing.${NC}"
    echo -e "${ORANGE}Run without --dry-run when you're ready to actually install.${NC}"
    echo ""
    echo -e "${RED}Pro tip: Dry runs don't make your setup any cooler.${NC}"
    exit 0
    ;;
  -*)
    echo -e "${RED}Unknown option: $1${NC}"
    echo -e "${BLUE}Try: ./install.sh --help${NC}"
    exit 1
    ;;
  esac

  # Detect OS first (needed before gum check)
  detect_os

  # Check and install gum if needed
  check_gum

  # Now we can use gum for pretty output
  clear
  gum style \
    --foreground 82 \
    --border-foreground 82 \
    --border double \
    --align center \
    --width 70 \
    --margin "1 2" \
    --padding "2 4" \
    'Hecate Dotfiles Installer' \
    '' \
    'Preparing to install Hyprland configuration...'

  echo ""
  check_OS
  echo ""

  # Run OS-specific installation script
  run_os_script

  echo ""
  gum style \
    --foreground 82 \
    --border-foreground 82 \
    --border double \
    --align left \
    --width 70 \
    --margin "1 2" \
    --padding "2 4" \
    '✓ Installation Complete!'

  echo ""
  gum style --foreground 85 '(surprisingly, nothing exploded)'
  echo ""

  gum style --foreground 82 \
    'Post-Install TODO:' \
    '1. Reboot (or live dangerously and just re-login)' \
    '2. Log into Hyprland' \
    '3. Take screenshot' \
    '4. Post to r/unixporn'
  echo ""
  gum style --foreground 92 "May your wallpapers be dynamic and your RAM usage low."
  echo ""
  sleep 3

  if gum confirm "Reboot now?"; then
    gum style --foreground 82 "Rebooting..."
    sleep 2
    sudo reboot
  else
    gum style --foreground 220 "Remember to reboot to apply all changes!"
  fi
}

# Run main function with arguments
main "$@"

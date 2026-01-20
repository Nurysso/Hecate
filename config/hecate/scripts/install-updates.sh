#!/bin/bash
# Hecate System Updater - Multi-distro Linux Update Script
# Supports: Arch Linux, Fedora, Ubuntu/Debian

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
CONFIG_DIR="$HOME/.config/hecate"
CONFIG_FILE="$CONFIG_DIR/sys-updater.conf"

# Default values
AUR_HELPER=""
AUTO_SNAPSHOT=false
UPDATE_FLATPAK=true
DISTRO=""
DISTRO_FAMILY=""

# Check if command exists
_commandExists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
_isInstalled() {
  case "$DISTRO_FAMILY" in
    "arch")
      pacman -Qi "$1" &>/dev/null
      ;;
    "fedora")
      rpm -q "$1" &>/dev/null
      ;;
    "debian")
      dpkg -l "$1" 2>/dev/null | grep -q "^ii"
      ;;
  esac
}

# Detect Linux distribution
_detectDistro() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    DISTRO="$ID"

    case "$ID" in
      arch|manjaro|endeavouros|garuda)
        DISTRO_FAMILY="arch"
        ;;
      fedora|nobara|ultramarine)
        DISTRO_FAMILY="fedora"
        ;;
      ubuntu|debian|pop|linuxmint|elementary)
        DISTRO_FAMILY="debian"
        ;;
      *)
        echo -e "${RED}✗${NC} Unsupported distribution: $ID"
        echo -e "${CYAN}ℹ${NC} Supported: Arch, Fedora, Ubuntu/Debian"
        exit 1
        ;;
    esac

    echo -e "${GREEN}✓${NC} Detected: ${BOLD}$NAME${NC} (${DISTRO_FAMILY})"
  else
    echo -e "${RED}✗${NC} Cannot detect distribution"
    exit 1
  fi
}

# Load configuration
_loadConfig() {
  if [[ -f "$CONFIG_FILE" ]]; then
    if source "$CONFIG_FILE" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} Configuration loaded"
    else
      echo -e "${RED}✗${NC} Failed to read configuration file"
      _commandExists "notify-send" && notify-send -u critical "Hecate Updater" "Failed to read config file: $CONFIG_FILE" --icon=dialog-error
      return 1
    fi
  else
    echo -e "${YELLOW}⚠${NC} No configuration found, creating defaults..."
    _saveConfig
  fi
}

# Save configuration
_saveConfig() {
  if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
    echo -e "${RED}✗${NC} Failed to create config directory"
    return 1
  fi

  cat >"$CONFIG_FILE" <<EOF
# Hecate System Updater Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Distribution: $DISTRO ($DISTRO_FAMILY)

AUR_HELPER="${AUR_HELPER:-}"
AUTO_SNAPSHOT=${AUTO_SNAPSHOT:-false}
UPDATE_FLATPAK=${UPDATE_FLATPAK:-true}
DISTRO="$DISTRO"
DISTRO_FAMILY="$DISTRO_FAMILY"
EOF

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} Configuration saved to ${CYAN}$CONFIG_FILE${NC}"
  else
    echo -e "${RED}✗${NC} Failed to save configuration"
  fi
}

# Detect AUR helper (Arch only)
_selectAURHelper() {
  if [[ "$DISTRO_FAMILY" != "arch" ]]; then
    return 0
  fi

  if [[ -n "$AUR_HELPER" ]] && _commandExists "$AUR_HELPER"; then
    echo -e "${BLUE}➜${NC} Using configured AUR helper: ${BOLD}$AUR_HELPER${NC}"
    return 0
  fi

  local available=()
  for helper in yay paru; do
    _commandExists "$helper" && available+=("$helper")
  done

  if [[ ${#available[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠${NC} No AUR helper found"
    if _commandExists "gum"; then
      if gum confirm "Install yay (recommended)?"; then
        echo -e "${BLUE}➜${NC} Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        rm -rf /tmp/yay
        AUR_HELPER="yay"
        echo -e "${GREEN}✓${NC} yay installed successfully"
        return 0
      fi
    fi
    echo -e "${CYAN}ℹ${NC} Using pacman only"
    AUR_HELPER="pacman"
    return 0
  fi

  if [[ ${#available[@]} -eq 1 ]]; then
    AUR_HELPER="${available[0]}"
  elif _commandExists "gum"; then
    AUR_HELPER=$(printf '%s\n' "${available[@]}" "pacman-only" | gum choose --header "Select AUR helper:")
    [[ "$AUR_HELPER" == "pacman-only" ]] && AUR_HELPER="pacman"
  else
    AUR_HELPER="${available[0]}"
  fi

  echo -e "${BLUE}➜${NC} Using AUR helper: ${BOLD}$AUR_HELPER${NC}"
}

# Create snapshot
_createSnapshot() {
  if ! _isInstalled "timeshift"; then
    echo -e "${YELLOW}⚠${NC} Timeshift not installed"
    if _commandExists "gum"; then
      if gum confirm "Install timeshift for system snapshots?"; then
        case "$DISTRO_FAMILY" in
          "arch")
            sudo pacman -S --noconfirm timeshift
            ;;
          "fedora")
            sudo dnf install -y timeshift
            ;;
          "debian")
            sudo apt install -y timeshift
            ;;
        esac
        echo -e "${GREEN}✓${NC} Timeshift installed"
      else
        echo -e "${CYAN}ℹ${NC} Skipping snapshot"
        return 0
      fi
    else
      echo -e "${CYAN}ℹ${NC} Skipping snapshot"
      return 0
    fi
  fi

  local create_snapshot=false

  if [[ "$AUTO_SNAPSHOT" == "true" ]]; then
    create_snapshot=true
    echo -e "${BLUE}➜${NC} Auto-snapshot enabled"
  else
    if _commandExists "gum"; then
      gum confirm "Create system snapshot before updating?" && create_snapshot=true
    else
      read -p "Create snapshot? (y/N): " confirm
      [[ "$confirm" =~ ^[Yy]$ ]] && create_snapshot=true
    fi
  fi

  if [[ "$create_snapshot" == "true" ]]; then
    local comment="Pre-update snapshot $(date '+%Y-%m-%d %H:%M')"

    if _commandExists "gum" && [[ "$AUTO_SNAPSHOT" != "true" ]]; then
      local user_comment
      user_comment=$(gum input --placeholder "Snapshot comment (optional)..." --value "$comment")
      [[ -n "$user_comment" ]] && comment="$user_comment"
    fi

    echo -e "${BLUE}➜${NC} Creating snapshot: ${CYAN}'$comment'${NC}"

    if _commandExists "gum"; then
      gum spin --spinner dot --title "Creating snapshot..." -- sudo timeshift --create --comments "$comment" --scripted
    else
      sudo timeshift --create --comments "$comment" --scripted
    fi

    if [[ $? -eq 0 ]]; then
      echo -e "${GREEN}✓${NC} Snapshot created successfully"
    else
      echo -e "${RED}✗${NC} Snapshot creation failed"
      if _commandExists "gum"; then
        gum confirm "Continue update without snapshot?" || exit 1
      else
        read -p "Continue anyway? (y/N): " confirm
        [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 1
      fi
    fi
  else
    echo -e "${CYAN}ℹ${NC} Snapshot creation skipped"
  fi
}

# Get package count
_getPackageCount() {
  case "$DISTRO_FAMILY" in
    "arch")
      pacman -Q | wc -l
      ;;
    "fedora")
      rpm -qa | wc -l
      ;;
    "debian")
      dpkg -l | grep "^ii" | wc -l
      ;;
  esac
}

# Check for updates
_checkUpdates() {
  case "$DISTRO_FAMILY" in
    "arch")
      pacman -Qu 2>/dev/null | wc -l
      ;;
    "fedora")
      dnf check-update -q 2>/dev/null | grep -v "^Last metadata" | grep -v "^$" | wc -l || echo "0"
      ;;
    "debian")
      apt list --upgradable 2>/dev/null | grep -v "^Listing" | wc -l
      ;;
  esac
}

# Show packages to update
_showPackages() {
  case "$DISTRO_FAMILY" in
    "arch")
      pacman -Qu
      ;;
    "fedora")
      dnf check-update -q 2>/dev/null | grep -v "^Last metadata" | grep -v "^$"
      ;;
    "debian")
      apt list --upgradable 2>/dev/null | grep -v "^Listing"
      ;;
  esac
}

# Perform update
_performUpdate() {
  echo
  echo -e "${BOLD}${MAGENTA}╔════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${MAGENTA}║       STARTING SYSTEM UPDATE          ║${NC}"
  echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════╝${NC}"
  echo

  case "$DISTRO_FAMILY" in
    "arch")
      echo -e "${BLUE}➜${NC} Syncing package databases..."
      sudo pacman -Sy

      local updates=$(_checkUpdates)
      if [[ "$updates" -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} System is already up to date"
        return 0
      fi

      echo -e "${CYAN}📦${NC} Found ${BOLD}$updates${NC} package(s) to update"
      echo

      if _commandExists "gum"; then
        if gum confirm "Show packages to be updated?"; then
          echo -e "${CYAN}╭─ Packages to be updated:${NC}"
          _showPackages | sed 's/^/│ /'
          echo -e "${CYAN}╰────────────────────────────${NC}"
          echo
        fi
      fi

      case "$AUR_HELPER" in
        "pacman")
          echo -e "${BLUE}➜${NC} Updating official packages..."
          sudo pacman -Syu --noconfirm
          ;;
        *)
          echo -e "${BLUE}➜${NC} Updating system with ${BOLD}$AUR_HELPER${NC}..."
          $AUR_HELPER -Syu --noconfirm
          ;;
      esac
      ;;

    "fedora")
      echo -e "${BLUE}➜${NC} Checking for updates..."
      local updates=$(_checkUpdates)

      if [[ "$updates" -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} System is already up to date"
        return 0
      fi

      echo -e "${CYAN}📦${NC} Found ${BOLD}$updates${NC} package(s) to update"
      echo

      if _commandExists "gum"; then
        if gum confirm "Show packages to be updated?"; then
          echo -e "${CYAN}╭─ Packages to be updated:${NC}"
          _showPackages | sed 's/^/│ /'
          echo -e "${CYAN}╰────────────────────────────${NC}"
          echo
        fi
      fi

      echo -e "${BLUE}➜${NC} Updating system packages..."
      sudo dnf upgrade -y
      ;;

    "debian")
      echo -e "${BLUE}➜${NC} Updating package lists..."
      sudo apt update

      local updates=$(_checkUpdates)
      if [[ "$updates" -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} System is already up to date"
        return 0
      fi

      echo -e "${CYAN}📦${NC} Found ${BOLD}$updates${NC} package(s) to update"
      echo

      if _commandExists "gum"; then
        if gum confirm "Show packages to be updated?"; then
          echo -e "${CYAN}╭─ Packages to be updated:${NC}"
          _showPackages | sed 's/^/│ /'
          echo -e "${CYAN}╰────────────────────────────${NC}"
          echo
        fi
      fi

      echo -e "${BLUE}➜${NC} Upgrading system packages..."
      sudo apt upgrade -y

      echo -e "${BLUE}➜${NC} Performing full upgrade..."
      sudo apt full-upgrade -y

      echo -e "${BLUE}➜${NC} Cleaning up..."
      sudo apt autoremove -y
      sudo apt autoclean
      ;;
  esac

  local result=$?

  # Update Flatpak
  if [[ "$UPDATE_FLATPAK" == "true" ]] && _commandExists "flatpak"; then
    echo
    echo -e "${BLUE}➜${NC} Updating Flatpak applications..."
    flatpak update -y
  fi

  return $result
}

# Show system info
_showSystemInfo() {
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║        SYSTEM INFORMATION             ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}  Distribution:${NC} $DISTRO ($DISTRO_FAMILY)"
  echo -e "${BLUE}  Kernel:${NC}       $(uname -r)"
  echo -e "${BLUE}  Uptime:${NC}       $(uptime -p)"
  echo -e "${BLUE}  Packages:${NC}     $(_getPackageCount) installed"

  if _commandExists "neofetch"; then
    echo
    neofetch --stdout --config none --disable title underline
  fi
  echo
}

# Display final summary
_displaySummary() {
  local result=$1

  echo
  if [[ $result -eq 0 ]]; then
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   ✓ UPDATE COMPLETED SUCCESSFULLY     ║${NC}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${NC}"

    _commandExists "notify-send" && notify-send "Hecate Updater" "System update completed successfully" --icon=software-update-available

    if [[ -f /var/run/reboot-required ]]; then
      echo
      echo -e "${YELLOW}⚠  System reboot is recommended${NC}"
    fi
  else
    echo -e "${BOLD}${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║   ✗ UPDATE COMPLETED WITH ERRORS      ║${NC}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════╝${NC}"

    _commandExists "notify-send" && notify-send -u critical "Hecate Updater" "System update completed with errors" --icon=dialog-error
  fi

  echo
  echo -e "${CYAN}Press ${BOLD}[ENTER]${NC}${CYAN} to exit...${NC}"

  if _commandExists "gum"; then
    gum input --placeholder "" --value "" >/dev/null 2>&1 || true
  else
    read -r </dev/tty
  fi
}

# Main execution
main() {
  # Detect distribution first
  _detectDistro

  # Don't run as root
  if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}✗${NC} Don't run this script as root"
    exit 1
  fi

  # Clear screen and show header
  clear

  if _commandExists "figlet"; then
    echo -e "${BOLD}${MAGENTA}"
    figlet -f slant "Hecate"
    echo -e "${NC}"
  else
    echo -e "${BOLD}${MAGENTA}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║                                           ║"
    echo "║          HECATE SYSTEM UPDATER            ║"
    echo "║                                           ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}\n"
  fi

  # Load config
  _loadConfig || true
  echo

  # Show system info
  _showSystemInfo

  # Confirm start
  if _commandExists "gum"; then
    if ! gum confirm "Start system update?"; then
      echo -e "${YELLOW}⚠${NC} Update cancelled"
      exit 0
    fi
  else
    read -p "Start system update? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo -e "${YELLOW}⚠${NC} Update cancelled"
      exit 0
    fi
  fi

  echo
  echo -e "${GREEN}✓${NC} Update process started"
  echo

  # Select AUR helper (Arch only)
  _selectAURHelper
  [[ "$DISTRO_FAMILY" == "arch" ]] && echo

  # Create snapshot
  _createSnapshot

  # Perform update
  if _performUpdate; then
    result=0
  else
    result=1
  fi

  # Save config
  echo
  _saveConfig

  # Check for reboot
  if [[ $result -eq 0 ]] && [[ -f /var/run/reboot-required ]]; then
    echo
    if _commandExists "gum"; then
      if gum confirm "Reboot now?"; then
        sudo reboot
      fi
    else
      read -p "Reboot now? (y/N): " reboot_confirm
      [[ "$reboot_confirm" =~ ^[Yy]$ ]] && sudo reboot
    fi
  fi

  # Display final summary
  _displaySummary $result
}

main "$@"

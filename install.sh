#!/bin/bash

# Hecate dotfiles installer
# Detects your distro, makes sure gum (used for prompts) is present, then runs
# scripts/install/<distro>.sh from this checkout, or downloads it when run via curl.
# Usage: ./install.sh [--check | --no-deps | --dry-run | --help]

set -e

SCRIPT_BASE_URL="https://raw.githubusercontent.com/Nurysso/Hecate/main/scripts/install"
OS=""

detect_os() {
  if [ ! -f /etc/os-release ]; then
    echo "Error: Cannot detect OS!" >&2
    exit 1
  fi
  . /etc/os-release
  case "$ID" in
  arch | manjaro | endeavouros | cachyos) OS="arch" ;;
  fedora) OS="fedora" ;;
  ubuntu | debian | pop | linuxmint) OS="ubuntu" ;;
  *)
    echo "Error: OS '$ID' is not supported!" >&2
    exit 1
    ;;
  esac
}

install_gum() {
  echo "Installing gum..."
  case "$OS" in
  arch) sudo pacman -S --needed --noconfirm gum ;;
  fedora) sudo dnf install -y gum ;;
  ubuntu)
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
    ;;
  esac
  command -v gum &>/dev/null
}

# Use the script next to this one when run from a checkout, otherwise download it
find_os_script() {
  local here
  here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  if [ -f "$here/scripts/install/$OS.sh" ] && [ -d "$here/config" ]; then
    OS_SCRIPT="$here/scripts/install/$OS.sh"
    export HECATE_LOCAL=true HECATEDIR="$here"
    return
  fi
  OS_SCRIPT=$(mktemp "/tmp/hecate_install_${OS}.XXXXXX")
  trap 'rm -f "$OS_SCRIPT"' EXIT
  if ! curl -fsSL "$SCRIPT_BASE_URL/$OS.sh" -o "$OS_SCRIPT"; then
    echo "✗ Failed to download $SCRIPT_BASE_URL/$OS.sh, check your internet connection" >&2
    exit 1
  fi
}

install_code_extensions() {
  command -v code &>/dev/null || return 0
  gum confirm "Install the VS Code extensions?" || return 0
  local ext
  for ext in golang.go rust-lang.rust-analyzer esbenp.prettier-vscode bradlc.vscode-tailwindcss \
    dsznajder.es7-react-js-snippets usernamehm.errorlens eamodio.gitlens dbaeumer.vscode-eslint \
    formulahendry.auto-rename-tag catppuccin.catppuccin-vsc catppuccin.catppuccin-vsc-icons; do
    code --install-extension "$ext" || echo "⚠ Could not install $ext"
  done
}

main() {
  detect_os

  # every other flag only prints or reads (or is rejected), so it works without gum
  local quick=false
  case "${1:-}" in --no-deps | "") ;; -*) quick=true ;; esac

  if [ "$quick" = false ] && ! command -v gum &>/dev/null; then
    install_gum || {
      echo "✗ gum is required for the prompts. Install it and run this again: https://github.com/charmbracelet/gum" >&2
      exit 1
    }
  fi

  case "$OS" in
  fedora | ubuntu)
    echo "⚠ $OS support is experimental and untested."
    if [ "$quick" = false ] && ! gum confirm "Continue with the $OS installation?"; then
      exit 1
    fi
    ;;
  esac

  find_os_script
  bash "$OS_SCRIPT" "$@"
  [ "$quick" = true ] || install_code_extensions
}

main "$@"

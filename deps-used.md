# Hecate Dotfiles - Complete Dependencies List (outdated need to update)

## Core Requirements

### Installer Essential Tool
- **gum** - Interactive TUI framework *(REQUIRED for installer to work)*

## Base Dependencies (All Profiles)

### Build Tools & Utilities
- base-devel
- git
- wget
- curl
- unzip
- go
- wails (go package)

### Hyprland & Desktop Environment
- hyprland
- waybar
- rofi-wayland / rofi
- dunst
- kitty
- swaync
- wallust
- waypaper
- inotify-tools

### System Monitoring & Info
- fastfetch
- btop

## Shell-Specific Dependencies

### Zsh Setup
- zsh
- fzf
- bat
- exa
- fd / fd-find
- thefuck
- oh-my-zsh (installed via script)
- powerlevel10k (installed via script)
- zsh-autosuggestions (installed via script)
- zsh-syntax-highlighting (installed via script)

### Bash Setup
- bash
- curl
- wget
- git
- unzip
- fzf
- fd / fd-find
- bat
- exa
- kitty
- fastfetch
- thefuck
- net-tools

### Fish Setup
- fish
- fzf
- bat
- exa
- thefuck
- net-tools
- fd / fd-find
- fisher (installed via script)
- procps-ng / procps
- coreutils
- jorgebucaran/fisher
- jethrokuan/z       # directory jumping
- jethrokuan/fzf     # FZF integration
- jorgebucaran/nvm.fish  # NVM support
- oh-my-fish/plugin-thefuck
- PatrickF1/fzf.fish
- decors/fish-colored-man

## Optional Dependencies (Profile-Based)

### Developer Profile - AI/ML
- python
- python-pip
- python-tensorflow
- python-numpy
- jupyter-notebook

### Developer Profile - Web Development
- nodejs
- npm
- pnpm

### Developer Profile - Server/Backend
- docker
- docker-compose
- postgresql
- mysql

### Developer Profile - Database
- postgresql
- mysql
- sqlite
- redis
- mongodb

### Developer Profile - Mobile Development
- android-tools

### Developer Profile - DevOps
- docker
- docker-compose
- kubectl
- terraform
- ansible

### Developer Profile - Game Development
- godot
- blender

### Gamer Profile
- steam
- lutris
- wine-staging / wine
- gamemode
- lib32-gamemode (Arch only)
- mangohud
- lib32-mangohud (Arch only)
- discord

### Gamer Profile - Emulators (Optional)
- retroarch (RetroArch)
- pcsx2 (PS2)
- dolphin-emu (GameCube/Wii)
- rpcs3 (PS3)
- yuzu (Switch)
- cemu (Wii U)

## Display Manager

### SDDM
- sddm
- sddm-astronaut-theme (optional, installed via script)

## Hyprland Plugins (Optional)
- hyprpm (plugin manager)
- hyprexpo
- border-plus-plus
- hyprfocus

## Package Manager Specific

### Arch Linux
- paru (AUR helper, installed if needed)
- yay (alternative AUR helper)
- pacman (default)

### Fedora
- dnf

### Ubuntu/Debian
- apt
- nala


---

## Installation Notes

### Minimum Install (Minimal Profile)
- Core requirements only
- Base dependencies
- Shell setup (your choice)
- Hyprland environment

### Developer Install
- Minimum install +
- Selected development tools based on your needs

### Gamer Install
- Minimum install +
- Gaming platform clients
- Performance tools
- Optional emulators

### Madlad Install
- Developer install +
- Gamer install

---

## Platform-Specific Package Names

| Package | Arch | Fedora | Ubuntu/Debian |
|---------|------|--------|---------------|
| fd | fd | fd-find | fd-find |
| rofi | rofi-wayland | rofi | rofi |
| build tools | base-devel | - | build-essential |
| process tools | procps-ng | procps-ng | procps |

---

**Last Updated:** Based on install.sh script analysis
**Script Version:** Hecate Dotfiles Installer with Gum

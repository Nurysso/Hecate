#!/bin/bash

# Hyprland Dotfiles Installer with Gum
# Author: Hecate Dotfiles
# Description: Interactive installer for Hyprland configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global Variables
HECATEDIR="$HOME/Hecate"
CONFIGDIR="$HOME/.config"
REPO_URL="https://github.com/Aelune/Hecate.git"
OS=""
PACKAGE_MANAGER=""

# User preferences
USER_TERMINAL=""
USER_SHELL=""
USER_BROWSER=""
USER_PROFILE=""
INSTALL_PACKAGES=()

# Check if gum is installed
check_gum() {
    if ! command -v gum &> /dev/null; then
        echo -e "${RED}Gum is not installed!${NC}"
        echo -e "${YELLOW}Gum is required for this installer to work.${NC}"
        echo ""
        echo "Please install Gum using one of the following methods:"
        echo ""
        echo "Arch Linux:"
        echo "  sudo pacman -S gum"
        echo ""
        echo "Fedora:"
        echo "  sudo dnf install gum"
        echo ""
        echo "Ubuntu/Debian:"
        echo "  sudo mkdir -p /etc/apt/keyrings"
        echo "  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg"
        echo "  echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *\" | sudo tee /etc/apt/sources.list.d/charm.list"
        echo "  sudo apt update && sudo apt install gum"
        echo ""
        echo "Or visit: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

# Check OS
check_OS() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros)
                OS="arch"
                ;;
            fedora)
                OS="fedora"
                ;;
            ubuntu|debian|pop|linuxmint)
                OS="ubuntu"
                ;;
            *)
                gum style --foreground 196 --bold "Error: OS '$ID' is not supported!"
                gum style --foreground 220 "Supported: Arch Linux, Fedora, Ubuntu/Debian"
                exit 1
                ;;
        esac
    else
        gum style --foreground 196 --bold "Error: Cannot detect OS!"
        exit 1
    fi
    gum style --foreground 82 "✓ Detected OS: $OS"
}

# Get package manager
get_packageManager() {
    case "$OS" in
        arch)
            if command -v paru &> /dev/null; then
                PACKAGE_MANAGER="paru"
            elif command -v yay &> /dev/null; then
                PACKAGE_MANAGER="yay"
            elif command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            fi
            ;;
        fedora)
            PACKAGE_MANAGER="dnf"
            ;;
        ubuntu)
            if command -v nala &> /dev/null; then
                PACKAGE_MANAGER="nala"
            elif command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
            fi
            ;;
    esac

    if [ -z "$PACKAGE_MANAGER" ]; then
        gum style --foreground 196 "Error: No supported package manager found!"
        exit 1
    fi

    gum style --foreground 82 "✓ Package Manager: $PACKAGE_MANAGER"
}

# Clone dotfiles
clone_dotfiles() {
    gum style --border double --padding "1 2" --border-foreground 212 "Cloning Hecate Dotfiles"

    if [ -d "$HECATEDIR" ]; then
        if gum confirm "Hecate directory already exists. Remove and re-clone?"; then
            rm -rf "$HECATEDIR"
        else
            gum style --foreground 220 "Using existing directory..."
            return
        fi
    fi

    gum style --foreground 220 "Cloning repository..."
    git clone "$REPO_URL" "$HECATEDIR"

    if [ $? -eq 0 ]; then
        gum style --foreground 82 "✓ Dotfiles cloned successfully!"
    else
        gum style --foreground 196 "✗ Error cloning repository!"
        exit 1
    fi
}

# Backup config based on Hecate/config contents
backup_config() {
    gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$CONFIGDIR/Hecate-backup-$timestamp"

    if [ -d "$HECATEDIR/config" ]; then
        local backed_up=false

        for folder in "$HECATEDIR/config"/*; do
            if [ -d "$folder" ]; then
                local folder_name=$(basename "$folder")

                # Check if config exists in user's .config
                if [ -d "$CONFIGDIR/$folder_name" ]; then
                    if [ "$backed_up" = false ]; then
                        mkdir -p "$backup_dir"
                        backed_up=true
                    fi
                    gum style --foreground 220 "Backing up: $folder_name"
                    cp -r "$CONFIGDIR/$folder_name" "$backup_dir/"
                fi

                # Backup shell rc files
                case "$folder_name" in
                    zsh)
                        if [ -f "$HOME/.zshrc" ]; then
                            [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
                            gum style --foreground 220 "Backing up: .zshrc"
                            cp "$HOME/.zshrc" "$backup_dir/.zshrc"
                        fi
                        ;;
                    bash)
                        if [ -f "$HOME/.bashrc" ]; then
                            [ "$backed_up" = false ] && mkdir -p "$backup_dir" && backed_up=true
                            gum style --foreground 220 "Backing up: .bashrc"
                            cp "$HOME/.bashrc" "$backup_dir/.bashrc"
                        fi
                        ;;
                esac
            fi
        done

        if [ "$backed_up" = true ]; then
            gum style --foreground 82 "✓ Backup created at: $backup_dir"
        else
            gum style --foreground 220 "No existing configs found to backup"
        fi
    fi
}

# Ask user preferences
ask_preferences() {
    gum style --border double --padding "1 2" --border-foreground 212 "User Preferences"

    # Terminal preference
    USER_TERMINAL=$(gum choose --header "Select your preferred terminal:" \
        "kitty" \
        "alacritty" \
        "foot" \
        "ghostty")
    gum style --foreground 82 "✓ Terminal: $USER_TERMINAL"
    echo ""

    # Shell preference
    USER_SHELL=$(gum choose --header "Select your preferred shell:" \
        "zsh" \
        "bash" \
        "fish")
    gum style --foreground 82 "✓ Shell: $USER_SHELL"
    echo ""

    # Browser preference
    USER_BROWSER=$(gum choose --header "Select your preferred browser:" \
        "firefox" \
        "brave" \
        "chromium" \
        "skip")
    if [ "$USER_BROWSER" != "skip" ]; then
        gum style --foreground 82 "✓ Browser: $USER_BROWSER"
    else
        gum style --foreground 220 "Skipping browser installation"
        USER_BROWSER=""
    fi
    echo ""

    # User profile
    USER_PROFILE=$(gum choose --header "Select your profile:" \
        "minimal" \
        "developer" \
        "gamer" \
        "madlad")
    gum style --foreground 82 "✓ Profile: $USER_PROFILE"
    echo ""

    # Summary
    gum style --border double --padding "1 2" --border-foreground 212 "Installation Summary"
    gum style --foreground 220 "Terminal: $USER_TERMINAL"
    gum style --foreground 220 "Shell: $USER_SHELL"
    [ -n "$USER_BROWSER" ] && gum style --foreground 220 "Browser: $USER_BROWSER"
    gum style --foreground 220 "Profile: $USER_PROFILE"
    echo ""

    if ! gum confirm "Proceed with these settings?"; then
        gum style --foreground 196 "Installation cancelled"
        exit 0
    fi
}

# Build package list based on preferences
build_package_list() {
    gum style --border double --padding "1 2" --border-foreground 212 "Building Package List"

    # Base packages
    INSTALL_PACKAGES+=(git wget curl unzip hyprland wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch python-pywal btop app2unit )

    # Terminal
    INSTALL_PACKAGES+=("$USER_TERMINAL")

    # Shell packages
    case "$USER_SHELL" in
        zsh)
            INSTALL_PACKAGES+=(zsh fzf bat exa fd thefuck)
            ;;
        bash)
            INSTALL_PACKAGES+=(bash fzf bat exa fd thefuck)
            ;;
        fish)
            INSTALL_PACKAGES+=(fish fzf bat exa thefuck fisher)
            ;;
    esac

    # Browser
    [ -n "$USER_BROWSER" ] && INSTALL_PACKAGES+=("$USER_BROWSER")

    # Profile-based packages
    case "$USER_PROFILE" in
        developer)
            add_developer_packages
            ;;
        gamer)
            add_gamer_packages
            ;;
        madlad)
            add_developer_packages
            add_gamer_packages
            ;;
    esac

    # Show package list
    gum style --foreground 220 "Packages to install:"
    printf '%s\n' "${INSTALL_PACKAGES[@]}" | gum format
}

# Add developer packages
add_developer_packages() {
    local dev_types=$(gum choose --no-limit --header "Select development areas:" \
        "AI/ML" \
        "Web Development" \
        "Server/Backend" \
        "Database" \
        "Mobile Development" \
        "DevOps" \
        "Game Development" \
        "Skip")

    if echo "$dev_types" | grep -q "Skip"; then
        return
    fi

    echo "$dev_types" | grep -q "AI/ML" && INSTALL_PACKAGES+=(python python-pip python-numpy jupyter-notebook)
    echo "$dev_types" | grep -q "Web Development" && INSTALL_PACKAGES+=(nodejs npm)
    echo "$dev_types" | grep -q "Server/Backend" && INSTALL_PACKAGES+=(docker docker-compose postgresql)
    echo "$dev_types" | grep -q "Database" && INSTALL_PACKAGES+=(postgresql mysql sqlite redis)
    echo "$dev_types" | grep -q "Mobile Development" && INSTALL_PACKAGES+=(android-tools)
    echo "$dev_types" | grep -q "DevOps" && INSTALL_PACKAGES+=(docker kubectl terraform ansible)
    echo "$dev_types" | grep -q "Game Development" && INSTALL_PACKAGES+=(godot blender)
}

# Add gamer packages
add_gamer_packages() {
    INSTALL_PACKAGES+=(steam lutris wine-staging gamemode mangohud)

    if gum confirm "Install Discord?"; then
        INSTALL_PACKAGES+=(discord)
    fi

    if gum confirm "Install emulators?"; then
        local emulators=$(gum choose --no-limit --header "Select emulators:" \
            "RetroArch" \
            "PCSX2" \
            "Dolphin" \
            "Skip")

        if ! echo "$emulators" | grep -q "Skip"; then
            echo "$emulators" | grep -q "RetroArch" && INSTALL_PACKAGES+=(retroarch)
            echo "$emulators" | grep -q "PCSX2" && INSTALL_PACKAGES+=(pcsx2)
            echo "$emulators" | grep -q "Dolphin" && INSTALL_PACKAGES+=(dolphin-emu)
        fi
    fi
}

# Install all packages
install_packages() {
    gum style --border double --padding "1 2" --border-foreground 212 "Installing Packages"

    local packages_str="${INSTALL_PACKAGES[*]}"

    gum style --foreground 220 "Installing ${#INSTALL_PACKAGES[@]} packages..."
    echo ""

    case "$PACKAGE_MANAGER" in
        paru|yay)
            $PACKAGE_MANAGER -S --needed $packages_str
            ;;
        pacman)
            # Install paru first if needed
            if ! command -v paru &> /dev/null; then
                gum style --foreground 220 "Installing paru AUR helper..."
                cd /tmp
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si --noconfirm
                cd "$HOME"
                PACKAGE_MANAGER="paru"
            fi
            paru -S --needed $packages_str
            ;;
        dnf)
            sudo dnf install -y $packages_str
            ;;
        apt)
            # Install nala if not present
            if ! command -v nala &> /dev/null; then
                gum style --foreground 220 "Installing nala..."
                sudo apt update
                sudo apt install -y nala
                PACKAGE_MANAGER="nala"
            fi
            sudo nala update
            sudo nala install -y $packages_str
            ;;
        nala)
            sudo nala update
            sudo nala install -y $packages_str
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo ""
        gum style --foreground 82 "✓ All packages installed successfully!"
    else
        echo ""
        gum style --foreground 196 "✗ Error installing packages!"
        exit 1
    fi
}

# Setup shell plugins
setup_shell_plugins() {
    gum style --border double --padding "1 2" --border-foreground 212 "Setting Up Shell Plugins"

    case "$USER_SHELL" in
        zsh)
            setup_zsh_plugins
            ;;
        fish)
            setup_fish_plugins
            ;;
        bash)
            gum style --foreground 220 "Bash uses built-in configuration, no plugins needed"
            ;;
    esac
}

# Setup Zsh plugins
setup_zsh_plugins() {
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        gum style --foreground 220 "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install Powerlevel10k
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        gum style --foreground 220 "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi

    # Install plugins
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        gum style --foreground 220 "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        gum style --foreground 220 "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    gum style --foreground 82 "✓ Zsh plugins installed!"
}

# Setup Fish plugins
setup_fish_plugins() {
    # Install fisher
    if ! fish -c "type -q fisher" 2>/dev/null; then
        gum style --foreground 220 "Installing Fisher..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    fi

    gum style --foreground 82 "✓ Fish plugins installed!"
}

# Move config files
move_config() {
    gum style --border double --padding "1 2" --border-foreground 212 "Installing Configuration Files"

    if [ ! -d "$HECATEDIR/config" ]; then
        gum style --foreground 196 "Error: Config directory not found!"
        exit 1
    fi

    mkdir -p "$CONFIGDIR"

    for folder in "$HECATEDIR/config"/*; do
        if [ -d "$folder" ]; then
            local folder_name=$(basename "$folder")

            # Only install selected terminal config
            case "$folder_name" in
                alacritty|foot|ghostty|kitty)
                    if [ "$folder_name" = "$USER_TERMINAL" ]; then
                        gum style --foreground 82 "Installing $folder_name config..."
                        rm -rf "$CONFIGDIR/$folder_name"
                        cp -r "$folder" "$CONFIGDIR/"
                    fi
                    ;;
                zsh)
                    if [ "$USER_SHELL" = "zsh" ] && [ -f "$folder/.zshrc" ]; then
                        gum style --foreground 82 "Installing .zshrc..."
                        cp "$folder/.zshrc" "$HOME/.zshrc"
                    fi
                    ;;
                bash)
                    if [ "$USER_SHELL" = "bash" ] && [ -f "$folder/.bashrc" ]; then
                        gum style --foreground 82 "Installing .bashrc..."
                        cp "$folder/.bashrc" "$HOME/.bashrc"
                    fi
                    ;;
                fish)
                    if [ "$USER_SHELL" = "fish" ]; then
                        gum style --foreground 82 "Installing fish config..."
                        mkdir -p "$CONFIGDIR/fish"
                        cp -r "$folder/"* "$CONFIGDIR/fish/"
                    fi
                    ;;
                *)
                    # Install other configs (hyprland, waybar, etc.)
                    gum style --foreground 82 "Installing $folder_name..."
                    rm -rf "$CONFIGDIR/$folder_name"
                    cp -r "$folder" "$CONFIGDIR/"
                    ;;
            esac
        fi
    done

    gum style --foreground 82 "✓ Configuration files installed successfully!"
}

build_preferd_app_keybind(){
mkdir -p ~/.config/hypr/configs && cat <<EOF > ~/.config/hypr/configs/app-names.conf
# Set your default editor here uncomment and reboot to take effect.
$term = $USER_TERMINAL
$browser = $USER_BROWSER
EOF
}
# Setup Waybar
setup_Waybar(){
    gum style --foreground 220 "Configuring waybar..."
    ln -sf $HOME/.config/waybar/configs/top $HOME/.config/waybar/config
    ln -sf $HOME/.config/waybar/style/default.css $HOME/.config/waybar/style.css
    gum style --foreground 82 "✓ Waybar configured!"
}

# Set default shell
set_default_shell() {
    if gum confirm "Set $USER_SHELL as default shell?"; then
        chsh -s $(which $USER_SHELL)
        gum style --foreground 82 "✓ $USER_SHELL set as default shell!"
    fi
}

# Install Hyprland plugins
install_hyprland_plugins() {
    if ! gum confirm "Install Hyprland plugins?"; then
        return
    fi

    gum style --border double --padding "1 2" --border-foreground 212 "Installing Hyprland Plugins"

    if ! command -v hyprpm &> /dev/null; then
        gum style --foreground 220 "hyprpm not available, skipping plugins..."
        return
    fi

    local plugins=$(gum choose --no-limit --header "Select Hyprland plugins:" \
        "hyprexpo" \
        "border-plus-plus" \
        "hyprfocus" \
        "Skip")

    if echo "$plugins" | grep -q "Skip"; then
        return
    fi

    echo "$plugins" | while read -r plugin; do
        [ -z "$plugin" ] && continue

        case "$plugin" in
            hyprexpo|border-plus-plus)
                gum spin --spinner dot --title "Installing $plugin..." -- \
                    hyprpm add https://github.com/hyprwm/hyprland-plugins
                ;;
            hyprfocus)
                gum spin --spinner dot --title "Installing $plugin..." -- \
                    hyprpm add https://github.com/pyt0xic/hyprfocus
                ;;
        esac
    done

    gum style --foreground 82 "✓ Hyprland plugins installed!"
}

# Set SDDM
set_Sddm() {
    if ! gum confirm "Install SDDM login manager?"; then
        return
    fi

    gum style --border double --padding "1 2" --border-foreground 212 "Installing SDDM"

    case "$PACKAGE_MANAGER" in
        paru|yay|pacman)
            sudo pacman -S --noconfirm sddm
            ;;
        dnf)
            sudo dnf install -y sddm
            ;;
        nala|apt)
            sudo $PACKAGE_MANAGER install -y sddm
            ;;
    esac

    sudo systemctl enable sddm
    sudo systemctl set-default graphical.target
    gum style --foreground 82 "✓ SDDM installed and enabled!"

    # SDDM theme
    if gum confirm "Install SDDM Astronaut theme?"; then
        gum spin --spinner dot --title "Installing SDDM theme..." -- sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
        gum style --foreground 82 "✓ SDDM theme installed!"
    fi
}

# Set GRUB theme
setGrub_Theme() {
    if [ ! -d "/boot/grub" ] && [ ! -d "/boot/grub2" ]; then
        return
    fi

    if ! gum confirm "Install a GRUB theme?"; then
        return
    fi

    gum style --border double --padding "1 2" --border-foreground 212 "GRUB Themes"

    local theme=$(gum choose --header "Select GRUB theme:" \
        "Catppuccin" \
        "Dracula" \
        "Nordic" \
        "Cyberpunk" \
        "Skip")

    case "$theme" in
        "Catppuccin")
            git clone https://github.com/catppuccin/grub.git /tmp/grub-theme
            sudo cp -r /tmp/grub-theme/src/* /boot/grub/themes/
            ;;
        "Dracula")
            git clone https://github.com/dracula/grub.git /tmp/grub-theme
            sudo mkdir -p /boot/grub/themes/dracula
            sudo cp -r /tmp/grub-theme/* /boot/grub/themes/dracula/
            ;;
        "Nordic")
            git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/grub-theme
            cd /tmp/grub-theme
            sudo ./install.sh
            ;;
        "Cyberpunk")
            git clone https://github.com/VandalByte/grub2-cyberpunk.git /tmp/grub-theme
            cd /tmp/grub-theme
            sudo ./install.sh
            ;;
        *)
            return
            ;;
    esac

    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    gum style --foreground 82 "✓ GRUB theme installed!"
}

# Main function
main() {
    clear

    # Check for gum first
    check_gum

    # Welcome banner
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'HECATE DOTFILES' 'Hyprland Configuration Installer' ''

    # Confirm installation
    if ! gum confirm "Do you want to proceed with Hecate installation?"; then
        gum style --foreground 220 "Installation cancelled"
        exit 0
    fi

    gum style --foreground 220 "Starting installation process..."
    sleep 1

    # System checks
    check_OS
    get_packageManager

    # Clone repo early to check configs
    clone_dotfiles

    # Backup existing configs based on Hecate/config
    backup_config

    # Ask all user preferences first
    ask_preferences

    # Build complete package list
    build_package_list

    # Install everything at once
    install_packages

    # Setup shell plugins
    setup_shell_plugins

    # Install configuration files
    move_config
    setup_Waybar
    build_preferd_app_keybind

    # Set default shell
    set_default_shell

    # Optional components
    install_hyprland_plugins
    set_Sddm
    setGrub_Theme

    # Completion message
    gum style \
        --foreground 82 --border-foreground 82 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        '✓ Installation Complete!' '' 'Please reboot your system to apply all changes.'

    if gum confirm "Reboot now?"; then
        sudo reboot
    fi
}

# Run main function
main

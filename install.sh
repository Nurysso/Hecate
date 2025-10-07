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
HYPRLAND_NEWLY_INSTALLED=false

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
        echo "Or visit: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

# Checks user OS runs only in arch shows warning in fedora and quits in ubuntu or other any other OS
check_OS() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros)
                OS="arch"
                gum style --foreground 82 "✓ Detected OS: $OS"
                ;;
            fedora)
                gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
                gum style --foreground 220 "Proceed at your own risk or follow the Fedora guide if available at https://github.com/Aelune/Hecate/tree/main/documentation/install-fedora.md"
                OS="fedora"
                ;;
            ubuntu|debian|pop|linuxmint)
                gum style --foreground 196 --bold "Error: Ubuntu/Debian-based OS detected!"
                gum style --foreground 220 "Hecate installer does not support Ubuntu automatically."
                gum style --foreground 220 "Please follow manual installation instructions:"
                gum style --foreground 220 "https://github.com/Aelune/Hecate/tree/main/documentation/install-ubuntu.md"
                exit 1
                ;;
            *)
                gum style --foreground 196 --bold "Error: OS '$ID' is not supported!"
                gum style --foreground 220 "Supported: Arch Linux, Manjaro, EndeavourOS"
                exit 1
                ;;
        esac
    else
        gum style --foreground 196 --bold "Error: Cannot detect OS!"
        exit 1
    fi
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
            gum style --foreground 220 --bold "⚠️ Warning: Script has not been tested on Fedora!"
            gum style --foreground 220 "Proceed at your own risk."

            if ! gum confirm "Do you want to continue on Fedora?"; then
                gum style --foreground 196 "Aborting installation on Fedora."
                exit 1
            fi

    PACKAGE_MANAGER="dnf"
    ;;

        *)
            gum style --foreground 196 --bold "Error: No supported OS detected for package management!"
            exit 1
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

# Ask user preferences to customize installation
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

    # Browser preference with display names
    local browser_choice=$(gum choose --header "Select your preferred browser:" \
        "Firefox" \
        "Brave" \
        "Chromium" \
        "Google Chrome" \
        "Skip")

    # Map display names to actual package names
    case "$browser_choice" in
        "Firefox")
            USER_BROWSER="firefox"
            USER_BROWSER_DISPLAY="Firefox"
            ;;
        "Brave")
            USER_BROWSER="brave-bin"
            USER_BROWSER_DISPLAY="Brave"
            ;;
        "Chromium")
            USER_BROWSER="chromium"
            USER_BROWSER_DISPLAY="Chromium"
            ;;
        "Google Chrome")
            USER_BROWSER="google-chrome"
            USER_BROWSER_DISPLAY="Google Chrome"
            ;;
        "Skip")
            USER_BROWSER=""
            USER_BROWSER_DISPLAY=""
            ;;
    esac

    if [ -n "$USER_BROWSER" ]; then
        gum style --foreground 82 "✓ Browser: $USER_BROWSER_DISPLAY"
    else
        gum style --foreground 220 "Skipping browser installation"
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
    [ -n "$USER_BROWSER" ] && gum style --foreground 220 "Browser: $USER_BROWSER_DISPLAY"
    gum style --foreground 220 "Profile: $USER_PROFILE"
    echo ""

    if ! gum confirm "Proceed with these settings?"; then
        gum style --foreground 196 "Installation cancelled"
        exit 0
    fi
}

# Also update build_preferd_app_keybind function to use the display name
build_preferd_app_keybind(){
    mkdir -p ~/.config/hypr/configs && cat <<EOF > ~/.config/hypr/configs/app-names.conf
# Set your default applications here
\$term = $USER_TERMINAL
\$browser = ${USER_BROWSER_DISPLAY:-$USER_BROWSER}
EOF

    gum style --foreground 82 "✓ App keybinds configured!"
}

# Build package list based on preferences
build_package_list() {
    gum style --border double --padding "1 2" --border-foreground 212 "Building Package List"

    # Check if Hyprland is already installed
    if command -v Hyprland &> /dev/null; then
        gum style --foreground 82 "✓ Hyprland is already installed"
         # Base packages
        INSTALL_PACKAGES+=(git wget curl unzip wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar python-pywal btop base-devel)
    else
        gum style --foreground 220 "Hyprland not found - will be installed"
        # Base packages
        INSTALL_PACKAGES+=(git wget curl unzip hyprland wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar python-pywal btop base-devel)
        HYPRLAND_NEWLY_INSTALLED=true
    fi


    # Hyprland plugin dependencies
    INSTALL_PACKAGES+=(cmake meson cpio pkg-config)

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
            gum style --foreground 220 "Its dummy function right now..."
            # add_developer_packages
            # add_gamer_packages
            ;;
    esac

    # Show package list
    gum style --foreground 220 "Packages to install:"
    printf '%s\n' "${INSTALL_PACKAGES[@]}" | gum format
}

# Add developer packages
add_developer_packages() {
    local dev_types=$(gum choose --no-limit --header "Select development areas (Space to select, Enter to confirm):" \
        "AI/ML" \
        "Web Development" \
        "Server/Backend" \
        "Database" \
        "Mobile Development" \
        "DevOps" \
        "Game Development" \
        "Skip")

    if echo "$dev_types" | grep -q "Skip"; then
        gum style --foreground 220 "Skipping developer packages"
        return
    fi

    # AI/ML packages
    if echo "$dev_types" | grep -q "AI/ML"; then
        gum style --foreground 220 "Adding AI/ML packages..."
        INSTALL_PACKAGES+=(python python-pip python-numpy python-pandas python-matplotlib python-scikit-learn)
    fi

    # Web Development packages
    if echo "$dev_types" | grep -q "Web Development"; then
        gum style --foreground 220 "Adding Web Development packages..."
        INSTALL_PACKAGES+=(nodejs npm yarn)
    fi

    # Server/Backend packages
    if echo "$dev_types" | grep -q "Server/Backend"; then
        gum style --foreground 220 "Adding Server/Backend packages..."
        INSTALL_PACKAGES+=(docker docker-compose)
    fi

    # Database packages
    if echo "$dev_types" | grep -q "Database"; then
        gum style --foreground 220 "Adding Database packages..."
        INSTALL_PACKAGES+=(postgresql sqlite)

        # Ask about MySQL separately as it's larger
        if gum confirm "Install MySQL/MariaDB?"; then
            INSTALL_PACKAGES+=(mariadb)
        fi

        if gum confirm "Install Redis?"; then
            INSTALL_PACKAGES+=(redis)
        fi
    fi

    # Mobile Development packages
    if echo "$dev_types" | grep -q "Mobile Development"; then
        gum style --foreground 220 "Adding Mobile Development packages..."
        INSTALL_PACKAGES+=(android-tools)
    fi

    # DevOps packages
    if echo "$dev_types" | grep -q "DevOps"; then
        gum style --foreground 220 "Adding DevOps packages..."
        INSTALL_PACKAGES+=(docker kubectl terraform ansible)
    fi

    # Game Development packages
    if echo "$dev_types" | grep -q "Game Development"; then
        gum style --foreground 220 "Adding Game Development packages..."
        INSTALL_PACKAGES+=(godot blender)
    fi
}

# Add gamer packages
add_gamer_packages() {
    gum style --foreground 220 "Adding gaming packages..."

    # Core gaming packages
    INSTALL_PACKAGES+=(steam lutris wine-staging winetricks gamemode lib32-gamemode mangohud lib32-mangohud)

    # Discord
    if gum confirm "Install Discord?"; then
        INSTALL_PACKAGES+=(discord)
    fi

    # Emulators
    if gum confirm "Install emulators?"; then
        local emulators=$(gum choose --no-limit --header "Select emulators (Space to select, Enter to confirm):" \
            "RetroArch" \
            "PCSX2" \
            "Dolphin" \
            "RPCS3" \
            "Skip")

        if ! echo "$emulators" | grep -q "Skip"; then
            echo "$emulators" | grep -q "RetroArch" && INSTALL_PACKAGES+=(retroarch retroarch-assets-xmb retroarch-assets-ozone)
            echo "$emulators" | grep -q "PCSX2" && INSTALL_PACKAGES+=(pcsx2)
            echo "$emulators" | grep -q "Dolphin" && INSTALL_PACKAGES+=(dolphin-emu)
            echo "$emulators" | grep -q "RPCS3" && INSTALL_PACKAGES+=(rpcs3-git)
        fi
    fi

    # Proton-GE
    if gum confirm "Install ProtonUp-Qt (for managing Proton-GE)?"; then
        INSTALL_PACKAGES+=(protonup-qt)
    fi
}

# Install all packages
install_packages() {
    gum style --border double --padding "1 2" --border-foreground 212 "Installing Packages"

    gum style --foreground 220 "Installing ${#INSTALL_PACKAGES[@]} packages..."
    echo ""

    case "$PACKAGE_MANAGER" in
        paru|yay)
            # Separate official repo packages from AUR packages
            local official_pkgs=()
            local aur_pkgs=()

            for pkg in "${INSTALL_PACKAGES[@]}"; do
                if pacman -Si "$pkg" &>/dev/null; then
                    official_pkgs+=("$pkg")
                else
                    aur_pkgs+=("$pkg")
                fi
            done

            # Install official packages first
            if [ ${#official_pkgs[@]} -gt 0 ]; then
                gum style --foreground 220 "Installing official repository packages..."
                sudo pacman -S --needed --noconfirm "${official_pkgs[@]}" || true
            fi

            # Install AUR packages one by one with retry logic
            if [ ${#aur_pkgs[@]} -gt 0 ]; then
                gum style --foreground 220 "Installing AUR packages..."
                for pkg in "${aur_pkgs[@]}"; do
                    local retries=3
                    local success=false

                    for ((i=1; i<=retries; i++)); do
                        gum style --foreground 220 "Installing $pkg (attempt $i/$retries)..."
                        if $PACKAGE_MANAGER -S --needed --noconfirm "$pkg"; then
                            success=true
                            break
                        else
                            if [ $i -lt $retries ]; then
                                gum style --foreground 220 "Retrying in 3 seconds..."
                                sleep 3
                            fi
                        fi
                    done

                    if [ "$success" = false ]; then
                        gum style --foreground 196 "⚠ Failed to install: $pkg (skipping)"
                    fi
                done
            fi
            ;;
        pacman)
            # Install paru first if needed
            if ! command -v paru &> /dev/null; then
                gum style --foreground 220 "Installing paru AUR helper..."
                cd /tmp
                sudo pacman -S --needed base-devel git
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si --noconfirm
                cd "$HOME"
                PACKAGE_MANAGER="paru"
            fi

            # Recursively call with paru
            install_packages
            return
            ;;
        dnf)
            sudo dnf install -y "${INSTALL_PACKAGES[@]}"
            ;;
    esac

    echo ""
    gum style --foreground 82 "✓ Package installation complete!"
    gum style --foreground 220 "Note: Some packages may have been skipped due to errors"
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
            setup_bash_plugins            ;;
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

    # Install Starship prompt (required by config.fish)
    if ! command -v starship &> /dev/null; then
        gum style --foreground 220 "Installing Starship prompt..."
        case "$PACKAGE_MANAGER" in
            paru|yay)
                $PACKAGE_MANAGER -S --noconfirm starship
                ;;
            pacman)
                sudo pacman -S --noconfirm starship
                ;;
            dnf)
                sudo dnf install -y starship
                ;;
        esac
    fi

    # Install useful Fish plugins
    gum style --foreground 220 "Installing Fish plugins..."
    fish -c "
        fisher install jethrokuan/z 2>/dev/null
        fisher install PatrickF1/fzf.fish 2>/dev/null
        fisher install jorgebucaran/nvm.fish 2>/dev/null
    " || true

    gum style --foreground 82 "✓ Fish plugins and Starship installed!"
}

setup_bash_plugins() {
    # Install Oh My Bash
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        gum style --foreground 220 "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
    fi

    # Install FZF for Bash
    if [ ! -f "$HOME/.fzf.bash" ]; then
        gum style --foreground 220 "Setting up FZF for Bash..."
        if [ -d "$HOME/.fzf" ]; then
            "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
        fi
    fi

    gum style --foreground 82 "✓ Bash plugins installed!"
}
# Move config files
move_config() {
    gum style --border double --padding "1 2" --border-foreground 212 "Installing Configuration Files"

    if [ ! -d "$HECATEDIR/config" ]; then
        gum style --foreground 196 "Error: Config directory not found!"
        exit 1
    fi

    mkdir -p "$CONFIGDIR"
    mkdir -p "$HOME/.local/bin"

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

    # Install hecate CLI tool
    if [ -f "$HECATEDIR/config/hecate.sh" ]; then
        gum style --foreground 82 "Installing hecate CLI tool..."
        cp "$HECATEDIR/config/hecate.sh" "$HOME/.local/bin/hecate"
        chmod +x "$HOME/.local/bin/hecate"
        gum style --foreground 82 "✓ hecate command installed to ~/.local/bin/hecate"
    fi

    # Install Hyprland plugin installer
    if [ -f "$HECATEDIR/config/install-hyprland-plugins.sh" ]; then
        gum style --foreground 82 "Installing Hyprland plugin installer..."
        cp "$HECATEDIR/config/install-hyprland-plugins.sh" "$HOME/.local/bin/install-hyprland-plugins"
        chmod +x "$HOME/.local/bin/install-hyprland-plugins"
        gum style --foreground 82 "✓ Plugin installer available: install-hyprland-plugins"
    fi

    gum style --foreground 220 "  Run 'hecate' or 'install-hyprland-plugins' from anywhere!"
    gum style --foreground 82 "✓ Configuration files installed successfully!"
}


# Build preferred app keybind
build_preferd_app_keybind(){
    mkdir -p ~/.config/hypr/configs && cat <<EOF > ~/.config/hypr/configs/app-names.conf
# Set your default editor here uncomment and reboot to take effect.
\$term = $USER_TERMINAL
\$browser = $USER_BROWSER
EOF
}

# Create Hecate configuration file
create_hecate_config() {
    gum style --border double --padding "1 2" --border-foreground 212 "Creating Hecate Configuration"

    local config_dir="$HOME/.config/hecate"
    local config_file="$config_dir/hecate.toml"
    local version="0.3.1 blind owl"
    local install_date=$(date +%Y-%m-%d)

    # Create config directory
    mkdir -p "$config_dir"

    # Ask about theme mode
    local theme_mode=$(gum choose --header "Select theme mode:" \
        "dynamic - Auto-update colors from wallpaper" \
        "static - Keep colors unchanged")

    if echo "$theme_mode" | grep -q "dynamic"; then
        theme_mode="dynamic"
    else
        theme_mode="static"
    fi

    # Create hecate.toml
    cat > "$config_file" << EOF
# Hecate Dotfiles Configuration
# This file manages your Hecate installation settings

[metadata]
version = "$version"
install_date = "$install_date"
last_update = "$install_date"
repo_url = "$REPO_URL"

[theme]
# Theme mode: "dynamic" or "static"
# dynamic: Automatically updates system colors when wallpaper changes
# static: Keeps colors unchanged regardless of wallpaper
mode = "$theme_mode"
EOF

    gum style --foreground 82 "✓ Hecate config created at: $config_file"
    gum style --foreground 220 "Theme mode: $theme_mode"
}


# Setup Waybar
setup_Waybar(){
    gum style --foreground 220 "Configuring waybar..."
    ln -sf $HOME/.config/waybar/configs/top $HOME/.config/waybar/config
    ln -sf $HOME/.config/waybar/style/default.css $HOME/.config/waybar/style.css
    gum style --foreground 82 "✓ Waybar configured!"
}

# Set default shell
# Fixed set_default_shell function
set_default_shell() {
    local current_shell=$(basename "$SHELL")

    if [ "$current_shell" = "$USER_SHELL" ]; then
        gum style --foreground 82 "✓ $USER_SHELL is already your default shell"
        return
    fi

    if gum confirm "Set $USER_SHELL as default shell?"; then
        local shell_path=$(which "$USER_SHELL")

        if [ -z "$shell_path" ]; then
            gum style --foreground 196 "Error: $USER_SHELL not found in PATH"
            return
        fi

        # Check if shell is in /etc/shells
        if ! grep -q "^${shell_path}$" /etc/shells; then
            gum style --foreground 220 "Adding $shell_path to /etc/shells..."
            echo "$shell_path" | sudo tee -a /etc/shells > /dev/null
        fi

        gum style --foreground 220 "Changing default shell to $USER_SHELL..."
        gum style --foreground 220 "You may be prompted for your password..."

        if sudo chsh -s "$shell_path" "$USER"; then
            gum style --foreground 82 "✓ $USER_SHELL set as default shell!"
            gum style --foreground 220 "Note: You need to log out and log back in for this to take effect"
        else
            gum style --foreground 196 "✗ Failed to change shell. Try manually: chsh -s $shell_path"
        fi
    fi
}

run_plugin_installer_if_in_hyprland() {
    # Only run if user is currently in Hyprland session
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"

        if gum confirm "You're currently in Hyprland. Install plugins now?"; then
            if [ -x "$HOME/.local/bin/install-hyprland-plugins" ]; then
                gum style --foreground 220 "Running plugin installer..."
                "$HOME/.local/bin/install-hyprland-plugins"
            else
                gum style --foreground 196 "Error: Plugin installer not found!"
            fi
        else
            gum style --foreground 220 "You can run 'install-hyprland-plugins' later"
        fi
    elif [ "$HYPRLAND_NEWLY_INSTALLED" = true ]; then
        gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"
        gum style --foreground 220 "Hyprland was just installed."
        gum style --foreground 220 "After reboot, log into Hyprland and run:"
        gum style --foreground 82 "  install-hyprland-plugins"
    else
        gum style --border double --padding "1 2" --border-foreground 212 "Hyprland Plugin Setup"
        gum style --foreground 220 "When you're in Hyprland, run: install-hyprland-plugins"
    fi
}
# Set SDDM
set_Sddm() {
    # Check if SDDM is already installed and enabled
    local sddm_installed=false
    local sddm_enabled=false

    if command -v sddm &> /dev/null; then
        sddm_installed=true
        gum style --foreground 82 "✓ SDDM is already installed"
    fi

    if systemctl is-enabled sddm &> /dev/null; then
        sddm_enabled=true
        gum style --foreground 82 "✓ SDDM is already enabled"
    fi

    # Only prompt if not already set up
    if [ "$sddm_installed" = true ] && [ "$sddm_enabled" = true ]; then
        if ! gum confirm "SDDM is already installed and enabled. Reconfigure theme?"; then
            return
        fi
        # Skip installation, go straight to theme
        setup_sddm_theme
        return
    fi

    if ! gum confirm "Install SDDM login manager?"; then
        return
    fi

    gum style --border double --padding "1 2" --border-foreground 212 "Installing SDDM"

    # Install SDDM if not already installed
    if [ "$sddm_installed" = false ]; then
        case "$PACKAGE_MANAGER" in
            paru|yay|pacman)
                sudo pacman -S --noconfirm sddm
                ;;
            dnf)
                sudo dnf install -y sddm
                ;;
        esac
    fi

    # Enable SDDM if not already enabled
    if [ "$sddm_enabled" = false ]; then
        sudo systemctl enable sddm
        sudo systemctl set-default graphical.target
        gum style --foreground 82 "✓ SDDM installed and enabled!"
    fi

    # Install theme
    setup_sddm_theme
}

# Helper function for SDDM theme installation
setup_sddm_theme() {
    if gum confirm "Install SDDM Astronaut theme?"; then
        gum style --foreground 220 "Installing SDDM theme..."

        local theme_script="/tmp/sddm-astronaut-setup.sh"
        if curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh -o "$theme_script"; then
            chmod +x "$theme_script"
            bash "$theme_script"
            rm -f "$theme_script"
            gum style --foreground 82 "✓ SDDM theme installed!"
        else
            gum style --foreground 196 "✗ Failed to download SDDM theme installer"
        fi
    fi
}

# Set GRUB theme
# setGrub_Theme() {
#     if [ ! -d "/boot/grub" ] && [ ! -d "/boot/grub2" ]; then
#         return
#     fi

#     if ! gum confirm "Install a GRUB theme?"; then
#         return
#     fi

#     gum style --border double --padding "1 2" --border-foreground 212 "GRUB Themes"

#     local theme=$(gum choose --header "Select GRUB theme:" \
#         "Catppuccin" \
#         "Dracula" \
#         "Nordic" \
#         "Cyberpunk" \
#         "Skip")

#     case "$theme" in
#         "Catppuccin")
#             git clone https://github.com/catppuccin/grub.git /tmp/grub-theme
#             sudo cp -r /tmp/grub-theme/src/* /boot/grub/themes/
#             ;;
#         "Dracula")
#             git clone https://github.com/dracula/grub.git /tmp/grub-theme
#             sudo mkdir -p /boot/grub/themes/dracula
#             sudo cp -r /tmp/grub-theme/* /boot/grub/themes/dracula/
#             ;;
#         "Nordic")
#             git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/grub-theme
#             cd /tmp/grub-theme
#             sudo ./install.sh
#             ;;
#         "Cyberpunk")
#             git clone https://github.com/VandalByte/grub2-cyberpunk.git /tmp/grub-theme
#             cd /tmp/grub-theme
#             sudo ./install.sh
#             ;;
#         *)
#             return
#             ;;
#     esac

#     sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#     gum style --foreground 82 "✓ GRUB theme installed!"
# }

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
    create_hecate_config

    # Set default shell
    set_default_shell

    # Optional components
    set_Sddm
    # setGrub_Theme
# Runs hyperland plugin install script if user is already in hyperland and skips if hyperland is newly installed or not loged in
    run_plugin_installer_if_in_hyprland

    # Completion message
#!/bin/bash

gum style \
  --foreground 82 \
  --border-foreground 82 \
  --border double \
  --align center \
  --width 70 \
  --margin "1 2" \
  --padding "2 4" \
  '✓ Installation Complete!' \
  '(surprisingly, nothing exploded)' '' \
  'Your Hyprland rice is now 99% complete!' \
  'The remaining 1% is tweaking it at 3 AM for the next 6 months' '' \
  'Post-Install TODO:' \
  '1. Reboot (or live dangerously and just re-login)' \
  '2. Log into Hyprland' \
  '3. Run: install-hyprland-plugins' \
  '4. Take screenshot' \
  '5. Post to r/unixporn' \
  '6. Profit???'

# Optional extra hints (commented out)
# 'hecate --help    (for mere mortals)' \
# 'hecate update    (for the brave)' \
# 'hecate theme     (for the indecisive)'

echo ""
echo "May your wallpapers be dynamic and your RAM usage low."
echo ""
gum style --foreground 220 "Fun fact: You're now legally required to mention 'I use Arch Hyprland btw' in conversations"
echo ""

if gum confirm "Reboot now? (Recommended unless you enjoy living on the edge)"; then
  gum style --foreground 82 "See you on the other side..."
  sleep 2
  sudo reboot
else
  gum style --foreground 220 "Bold choice. Remember to reboot eventually!"
  gum style --foreground 220 "Your computer will judge you silently until you do."
fi

}

# Run main function
main

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
    INSTALL_PACKAGES+=(git wget curl unzip hyprland wallust waybar swaync rofi-wayland rofi rofi-emoji waypaper wlogout dunst fastfetch thunar python-pywal btop base-devel)

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
        apt)
            # Install nala if not present
            if ! command -v nala &> /dev/null; then
                gum style --foreground 220 "Installing nala..."
                sudo apt update
                sudo apt install -y nala
                PACKAGE_MANAGER="nala"
            fi
            sudo nala update
            sudo nala install -y "${INSTALL_PACKAGES[@]}"
            ;;
        nala)
            sudo nala update
            sudo nala install -y "${INSTALL_PACKAGES[@]}"
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

        # Ensure ~/.local/bin is in PATH for the current shell session
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
        fi

        gum style --foreground 82 "✓ hecate command installed to ~/.local/bin/hecate"
        gum style --foreground 220 "  You can now run 'hecate' from anywhere!"
    fi

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
    local version="0.3.0"
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

    # Create hecate management script
    create_hecate_script
}

# Create hecate management script
create_hecate_script() {
    local script_path="$HOME/.local/bin/hecate"
    mkdir -p "$HOME/.local/bin"

    cat > "$script_path" << 'HECATE_SCRIPT'
#!/bin/bash

# Hecate Dotfiles Manager
# Manages updates, configuration, and theme settings

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="$HOME/.config/hecate.toml"
HECATE_DIR="$HOME/Hecate"
REPO_URL="https://github.com/Aelune/Hecate.git"

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

# Get current version
get_current_version() {
    get_config_value "version"
}

# Get remote version
get_remote_version() {
    local remote_version=$(curl -s "https://raw.githubusercontent.com/Aelune/Hecate/main/version.txt" 2>/dev/null || echo "")
    echo "$remote_version"
}

# Check for updates
check_updates() {
    echo -e "${BLUE}Checking for updates...${NC}"

    local current_version=$(get_current_version)
    local remote_version=$(get_remote_version)

    if [ -z "$remote_version" ]; then
        echo -e "${YELLOW}Unable to check for updates. Network error.${NC}"
        return 1
    fi

    echo "Current version: $current_version"
    echo "Latest version: $remote_version"

    if [ "$current_version" != "$remote_version" ]; then
        echo -e "${GREEN}New version available!${NC}"

        # Send notification if in Hyprland
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            notify-send "Hecate Update Available" "New version $remote_version is available!\nRun: hecate update" -u normal
        fi
        return 0
    else
        echo -e "${GREEN}You are on the latest version.${NC}"
        return 1
    fi
}

# Update Hecate
update_hecate() {
    echo -e "${BLUE}Updating Hecate dotfiles...${NC}"

    # Backup current config
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.config/Hecate-backup-$timestamp"

    echo "Creating backup at: $backup_dir"
    mkdir -p "$backup_dir"

    # Backup important configs
    [ -d "$HOME/.config/hypr" ] && cp -r "$HOME/.config/hypr" "$backup_dir/"
    [ -d "$HOME/.config/waybar" ] && cp -r "$HOME/.config/waybar" "$backup_dir/"
    [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "$backup_dir/"

    # Update repository
    if [ -d "$HECATE_DIR" ]; then
        cd "$HECATE_DIR"
        echo "Pulling latest changes..."
        git pull origin main
    else
        echo "Cloning repository..."
        git clone "$REPO_URL" "$HECATE_DIR"
    fi

    # Copy new configs (preserving user settings)
    echo "Updating configuration files..."

    # Update only specific configs, not everything
    [ -d "$HECATE_DIR/config/waybar" ] && cp -r "$HECATE_DIR/config/waybar/"* "$HOME/.config/waybar/"
    [ -d "$HECATE_DIR/config/rofi" ] && cp -r "$HECATE_DIR/config/rofi/"* "$HOME/.config/rofi/"
    [ -d "$HECATE_DIR/config/swaync" ] && cp -r "$HECATE_DIR/config/swaync/"* "$HOME/.config/swaync/"

    # Update version and date in config
    local new_version=$(get_remote_version)
    local current_date=$(date +%Y-%m-%d)

    set_config_value "version" "$new_version"
    set_config_value "last_update" "$current_date"

    echo -e "${GREEN}✓ Update complete!${NC}"
    echo "Backup saved at: $backup_dir"

    # Send notification
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        notify-send "Hecate Updated" "Successfully updated to version $new_version" -u normal
    fi
}

# Toggle theme mode
toggle_theme() {
    local current_mode=$(get_config_value "mode")

    echo "Current theme mode: $current_mode"

    if [ "$current_mode" = "dynamic" ]; then
        set_config_value "mode" "static"
        echo -e "${GREEN}✓ Theme mode set to: static${NC}"
        notify-send "Hecate Theme" "Theme mode: Static\nColors won't auto-update" -u normal
    else
        set_config_value "mode" "dynamic"
        echo -e "${GREEN}✓ Theme mode set to: dynamic${NC}"
        notify-send "Hecate Theme" "Theme mode: Dynamic\nColors will auto-update from wallpaper" -u normal
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

    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}        ${GREEN}Hecate Dotfiles Info${NC}          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Version:${NC}        $version"
    echo -e "${YELLOW}Installed:${NC}      $install_date"
    echo -e "${YELLOW}Last Update:${NC}    $last_update"
    echo -e "${YELLOW}Theme Mode:${NC}     $theme_mode"
    echo ""
    echo -e "${BLUE}Preferences:${NC}"
    echo -e "  Terminal:     $terminal"
    echo -e "  Shell:        $shell"
    echo -e "  Browser:      $browser"
    echo ""
}

# Show help
show_help() {
    echo -e "${GREEN}Hecate Dotfiles Manager${NC}"
    echo ""
    echo "Usage: hecate [command]"
    echo ""
    echo "Commands:"
    echo "  check         Check for updates"
    echo "  update        Update Hecate dotfiles"
    echo "  theme         Toggle theme mode (dynamic/static)"
    echo "  info          Show installation info"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  hecate check      # Check if updates are available"
    echo "  hecate update     # Update to latest version"
    echo "  hecate theme      # Switch between dynamic/static theme"
    echo ""
}

# Main command handler
case "${1:-help}" in
    check)
        check_updates
        ;;
    update)
        check_updates
        echo ""
        read -p "Do you want to update? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_hecate
        else
            echo "Update cancelled."
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
esac
HECATE_SCRIPT

    chmod +x "$script_path"

    # Add update checker to Hyprland autostart if enabled
    local autostart_file="$HOME/.config/hypr/configs/AutoStart.conf"
    if [ -f "$autostart_file" ]; then
        if ! grep -q "hecate startup" "$autostart_file"; then
            echo "" >> "$autostart_file"
            echo "# Hecate startup checker (network + updates)" >> "$autostart_file"
            echo "exec-once = bash -c 'sleep 5 && hecate startup'" >> "$autostart_file"
        fi
    fi

    gum style --foreground 82 "✓ Hecate manager installed at: $script_path"
    gum style --foreground 220 "Usage: hecate [check|update|theme|info|help]"
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

# Create post-install script for Hyprland plugins
create_plugin_installer() {
    gum style --border double --padding "1 2" --border-foreground 212 "Creating Plugin Installer Script"

    local script_path="$HOME/.local/bin/install-hyprland-plugins.sh"
    local flag_file="$HOME/.config/hypr/.plugins_installed"
    mkdir -p "$HOME/.local/bin"

    cat > "$script_path" << 'PLUGIN_SCRIPT'
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
if ! command -v gum &> /dev/null; then
    echo -e "${RED}Error: gum is not installed!${NC}"
    exit 1
fi

# Check if hyprpm is available
if ! command -v hyprpm &> /dev/null; then
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
plugins=$(gum choose --no-limit --header "Select plugins to install:" \
    "hyprexpo" \
    "border-plus-plus" \
    "hyprfocus" \
    "Skip")

if echo "$plugins" | grep -q "Skip" || [ -z "$plugins" ]; then
    gum style --foreground 220 "No plugins selected."
    touch "$FLAG_FILE"
    exit 0
fi

# Install selected plugins
echo "$plugins" | while IFS= read -r plugin; do
    [ -z "$plugin" ] && continue

    gum style --foreground 220 "Installing: $plugin"

    case "$plugin" in
        hyprexpo|border-plus-plus)
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
PLUGIN_SCRIPT

    chmod +x "$script_path"

    # Add to Hyprland autostart
    local autostart_file="$HOME/.config/hypr/configs/AutoStart.conf"
    if [ -f "$autostart_file" ]; then
        # Check if it's not already added
        if ! grep -q "install-hyprland-plugins.sh" "$autostart_file"; then
            echo "" >> "$autostart_file"
            echo "# First-time plugin installer (auto-runs once)" >> "$autostart_file"
            echo "exec-once = $USER_TERMINAL -e bash -c 'install-hyprland-plugins.sh; exec bash'" >> "$autostart_file"
            gum style --foreground 82 "✓ Added to Hyprland autostart"
        fi
    else
        # Create AutoStart.conf if it doesn't exist
        mkdir -p "$HOME/.config/hypr/configs"
        cat > "$autostart_file" << EOF
# Hyprland AutoStart Configuration

# First-time plugin installer (auto-runs once)
exec-once = $USER_TERMINAL -e bash -c 'install-hyprland-plugins.sh; exec bash'
EOF
        gum style --foreground 82 "✓ Created AutoStart.conf with plugin installer"
    fi

    gum style --foreground 82 "✓ Plugin installer configured!"
    gum style --foreground 220 "Will run automatically on first Hyprland login"
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
        gum style --foreground 220 "Installing SDDM theme..."

        # Download and run the script directly without gum spin
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

    # Create post-install plugin installer script
    create_plugin_installer

    # Optional components
    set_Sddm
    # setGrub_Theme

    # Completion message
    gum style \
        --foreground 82 --border-foreground 82 --border double \
        --align center --width 60 --margin "1 2" --padding "2 4" \
        '✓ Installation Complete!' '' \
        'IMPORTANT: After reboot and logging into Hyprland,' \
        'run: install-hyprland-plugins.sh' \
        'to install Hyprland plugins' '' \
        'Please reboot your system now.'

    if gum confirm "Reboot now?"; then
        sudo reboot
    fi
}

# Run main function
main

#!/bin/bash

# Hecate Update Script
# Description: Updates Hecate dotfiles with backup and configuration preservation

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Global Variables
WORKDIR=""   # temp folder for the clone; ~/Hecate may be the user's own checkout
HECATEDIR=""
CONFIGDIR="$HOME/.config"
REPO_URL="https://github.com/Nurysso/Hecate.git"
CONFIG_FILE="$HOME/.config/hecate/hecate.toml"
SDDM_ROOT="${SDDM_ROOT:-}"   # tests point this at a throwaway tree instead of /
SETTINGS_LOG="/tmp/hecate-settings-build.log"

# Yours once installed: an update never replaces these. Our new version goes next to the backup instead.
PERSONAL_FILES=(
  "hecate/hecate.toml"   # merged, see merge_hecate_toml
  "hecate/quickapps.conf"
  "hecate/user.png"
  "hypr/configs/keybinds.lua"
  "hypr/configs/monitors.lua"
)

# What a shell can't run without: command|Arch package|Fedora package (empty: the installer builds it)
REQUIRED_TOOLS=(
  "Hyprland|hyprland|hyprland"
  "hyprctl|hyprland|hyprland"
  "qs|quickshell|quickshell"
  "matugen|matugen|"
  "awww|awww|"
  "hypridle|hypridle|hypridle"
  "hyprlock|hyprlock|hyprlock"
  "jq|jq|jq"
  "python3|python|python3"
  "wpctl|wireplumber|wireplumber"
  "cliphist|cliphist|cliphist"
  "wl-copy|wl-clipboard|wl-clipboard"
  "grim|grim|grim"
  "slurp|slurp|slurp"
  "starship|starship|starship"
)
MIN_HYPRLAND="0.55.0"
MIN_QUICKSHELL="0.3.0"

# Set along the way, reported by show_completion_message
APPLYING=false
BACKUP_DIR=""
SDDM_ACTION="none"          # none, update or switch
SDDM_THEME_DIR=""
SDDM_REMEMBER_DECLINE=false
SDDM_RESULT=""
SETTINGS_REBUILD=false
SETTINGS_RESULT=""
WALLPAPER_ACTION="skip"     # skip, full or defaults
WALLPAPER_DIR=""
TOML_ADDED=""
KEPT_CHANGED=()
CONFIG_ERRORS=""

# Leaves nothing behind, and says how to get back if the update stopped with configs half replaced
on_exit() {
  local status=$?
  [ -n "$WORKDIR" ] && rm -rf "$WORKDIR"
  if [ "$status" -ne 0 ] && [ "$APPLYING" = true ]; then
    echo -e "${RED}The update stopped partway, so your configs may be half replaced.${NC}"
    echo -e "${YELLOW}To go back to how they were:${NC}"
    echo "  cp -r \"$BACKUP_DIR/config/.\" \"$CONFIGDIR/\""
  fi
}

# Use tte if available, otherwise fallback to echo
fancy_echo() {
  local text="$1"
  local effect="${2:-slide}"

  if command -v tte &>/dev/null; then
    echo "$text" | tte "$effect" --movement-speed 2 2>/dev/null || echo "$text"
  else
    echo "$text"
  fi
}
# gum draws this whole script, so it's the one thing it can't run without. tte is decoration: see fancy_echo.
install_gum() {
  case "$OS" in
    arch) sudo pacman -S --needed --noconfirm gum ;;
    fedora) sudo dnf install -y gum ;;
    *) return 1 ;; # Ubuntu needs Charm's apt repo, which is yours to add
  esac
}

check_dependencies() {
  if command -v gum &>/dev/null; then
    return 0
  fi

  echo -e "${RED}Missing dependency: gum${NC}"
  read -p "Would you like to install it now? (y/n): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]] && install_gum && command -v gum &>/dev/null; then
    return 0
  fi

  echo -e "${RED}Update needs gum and it isn't installed: https://github.com/charmbracelet/gum#installation${NC}"
  exit 1
}

# Check if Hecate is installed
check_hecate_installed() {
  if [ ! -f "$CONFIG_FILE" ]; then
    gum style --foreground 196 --bold "❌ Error: Hecate is not installed!"
    gum style --foreground 220 "Please run the installer first."
    exit 1
  fi
}

# Parse TOML value - Enhanced to handle sections
get_config_value() {
  local key="$1"
  local section="${2:-}"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    return
  fi

  if [ -n "$section" ]; then
    # Extract value from specific section
    awk -v section="$section" -v key="$key" '
      /^\[.*\]/ {
        current_section = $0
        gsub(/^\[|\]$/, "", current_section)
      }
      current_section == section && $0 ~ "^" key " *= *" {
        sub("^" key " *= *\"?", "")
        sub("\"? *(#.*)?$", "")
        print
        exit
      }
    ' "$CONFIG_FILE"
  else
    # Original behavior for backwards compatibility
    grep -E "^\s*$key\s*=" "$CONFIG_FILE" 2>/dev/null |
      head -n1 |
      sed -E "s/^\s*$key\s*=\s*\"?([^\"]*)\"?/\1/" || echo ""
  fi
}

# Set TOML value in specific section, adding the key when it isn't there yet
set_config_value() {
  local key="$1"
  local value="$2"
  local section="${3:-metadata}"

  awk -v section="$section" -v key="$key" -v value="$value" '
    /^\[.*\]/ {
      current_section = $0
      gsub(/^\[|\]$/, "", current_section)
    }
    current_section == section && $0 ~ "^" key " *= *" {
      print key " = \"" value "\""
      next
    }
    { print }
  ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

  if ! grep -qE "^$key *= *" <(awk -v section="$section" '
    /^\[.*\]/ { current_section = $0; gsub(/^\[|\]$/, "", current_section); next }
    current_section == section { print }' "$CONFIG_FILE"); then
    awk -v header="[$section]" -v line="$key = \"$value\"" '
      { print }
      $0 == header && !done { print line; done = 1 }
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  fi
}

# Read configuration values
read_user_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Reading Configuration"

  # Read from [metadata] section
  current_version=$(get_config_value "version" "metadata")

  # Read from [preferences] section
  USER_TERMINAL=$(get_config_value "term" "preferences")
  USER_BROWSER=$(get_config_value "browser" "preferences")
  USER_SHELL=$(get_config_value "shell" "preferences")
  USER_PROFILE=$(get_config_value "profile" "preferences")

  # Read from [theme] section
  THEME_MODE=$(get_config_value "mode" "theme")

  gum style --foreground 82 "✓ Configuration loaded:"
  gum style --foreground 82 "  Version: ${current_version}"
  gum style --foreground 82 "  Terminal: ${USER_TERMINAL}"
  gum style --foreground 82 "  Browser: ${USER_BROWSER}"
  gum style --foreground 82 "  Shell: ${USER_SHELL}"
  gum style --foreground 82 "  Profile: ${USER_PROFILE}"
  gum style --foreground 82 "  Theme: ${THEME_MODE}"

  # Validate required values
  if [ -z "$USER_TERMINAL" ] || [ -z "$USER_SHELL" ]; then
    gum style --foreground 196 "❌ Error: Missing required configuration values!"
    exit 1
  fi
}

# Get current and remote versions
check_versions() {
  remote_version=$(curl -fsS "https://raw.githubusercontent.com/Nurysso/Hecate/main/version.txt" 2>/dev/null || echo "")
  if [ -z "$remote_version" ]; then
    gum style --foreground 196 "❌ Failed to fetch remote version"
    gum style --foreground 220 "Check your internet connection"
    exit 1
  fi

  # Extract numeric versions (remove any suffix like "shy eagle")
  local_numeric=$(echo "$current_version" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)
  remote_numeric=$(echo "$remote_version" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' || true)

  gum style --foreground 62 "Current version: ${current_version}"
  gum style --foreground 82 "Latest version:  $remote_version"

  # Compare versions using sort -V (version sort)
  if [ "$local_numeric" = "$remote_numeric" ]; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi

  # Check if local is newer than remote (shouldn't happen, but handle it)
  if printf '%s\n' "$remote_numeric" "$local_numeric" | sort -V -C; then
    gum style --foreground 82 "✓ You're already on the latest version!"
    exit 0
  fi

  # If we get here, update is available
  gum style --foreground 220 "Update available!"
}

# True when version $1 is at least $2
version_at_least() {
  [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# The first x.y.z a command prints about itself
tool_version() {
  "$@" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

install_packages() {
  case "$OS" in
    arch)
      sudo pacman -S --needed --noconfirm "$@" && return 0
      local helper
      for helper in paru yay; do
        if command -v "$helper" &>/dev/null; then
          "$helper" -S --needed --noconfirm "$@" && return 0
        fi
      done
      return 1
      ;;
    fedora) sudo dnf install -y "$@" ;;
    *) return 1 ;;
  esac
}

missing_tools() {
  local entry command arch_pkg fedora_pkg
  for entry in "${REQUIRED_TOOLS[@]}" "$USER_TERMINAL|$USER_TERMINAL|$USER_TERMINAL"; do
    IFS='|' read -r command arch_pkg fedora_pkg <<<"$entry"
    if ! command -v "$command" &>/dev/null; then
      case "$OS" in
        arch) echo "$command|$arch_pkg" ;;
        fedora) echo "$command|$fedora_pkg" ;;
        *) echo "$command|" ;;
      esac
    fi
  done
}

# New configs on a system that can't run them leave you without a desktop, so this runs before anything changes
check_system() {
  local missing packages=() command package
  missing=$(missing_tools)

  if [ -n "$missing" ]; then
    gum style --foreground 220 --bold "This version needs tools you don't have:"
    while IFS='|' read -r command package; do
      gum style --foreground 220 "  • $command"
      if [ -n "$package" ]; then packages+=("$package"); fi
    done <<<"$missing"
    echo ""

    if [ ${#packages[@]} -gt 0 ] && gum confirm "Install them now? (needs sudo)"; then
      mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)
      install_packages "${packages[@]}" || true
    fi

    missing=$(missing_tools)
    if [ -n "$missing" ]; then
      gum style --foreground 196 "✗ Still missing: $(cut -d'|' -f1 <<<"$missing" | tr '\n' ' ')"
      gum style --foreground 220 "Nothing has been changed. Install them, or run ./install.sh from a clone, then update again."
      exit 1
    fi
  fi

  local version
  version=$(tool_version Hyprland --version)
  if [ -n "$version" ] && ! version_at_least "$version" "$MIN_HYPRLAND"; then
    gum style --foreground 196 "✗ This version needs Hyprland $MIN_HYPRLAND or newer, and you have $version."
    gum style --foreground 220 "Nothing has been changed. Update your system, then update Hecate again."
    exit 1
  fi
  version=$(tool_version qs --version)
  if [ -n "$version" ] && ! version_at_least "$version" "$MIN_QUICKSHELL"; then
    gum style --foreground 196 "✗ This version needs Quickshell $MIN_QUICKSHELL or newer, and you have $version."
    gum style --foreground 220 "Nothing has been changed. Update your system, then update Hecate again."
    exit 1
  fi
  if ! python3 -c 'import tomllib' 2>/dev/null; then
    gum style --foreground 196 "✗ This version needs Python 3.11 or newer."
    gum style --foreground 220 "Nothing has been changed. Update your system, then update Hecate again."
    exit 1
  fi
}

# Show update warning and get confirmation
show_update_warning() {
  gum style --border double --padding "1 2" --border-foreground 45 "What's New in v0.6.1"
  echo ""
  gum style --foreground 255 "  • A circle reveals your desktop at login, and new wallpapers when you change them"
  gum style --foreground 255 "  • The login screen only fades once your password is accepted"
  gum style --foreground 255 "  • Updates keep your hecate.toml, keybinds, monitors, quick apps and profile picture"
  echo ""
  gum style --foreground 45 --bold "New in v0.6.0, if you're coming from an older version:"
  gum style --foreground 255 "  • A new Quickshell desktop: glass bar, control center, launcher, notifications and desktop cards"
  gum style --foreground 255 "  • Hecate Settings: decoration, animation, keybinds, monitors, connectivity and every Hyprland option"
  gum style --foreground 255 "  • hecate.toml: the bar, widgets and look in one file, applied when you save"
  gum style --foreground 255 "  • Colors from your wallpaper for the shell, GTK and Qt apps, and the prompt"
  echo ""
  gum style --foreground 220 "Your other configs in ~/.config will be replaced. They're backed up first."
  echo ""
  gum style --foreground 82 "Ideas and help welcome: https://github.com/Nurysso/Hecate/issues/3"
  echo ""

  if ! gum confirm "Do you understand and want to proceed with the update?"; then
    gum style --foreground 220 "Update cancelled. Your configuration remains unchanged."
    exit 0
  fi

  echo ""
  gum style --foreground 196 --bold "Final confirmation:"
  if ! gum confirm "Are you absolutely sure you want to continue?"; then
    gum style --foreground 220 "Update cancelled."
    exit 0
  fi
}

# Checks user OS
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

# Clone dotfiles
clone_dotfiles() {
  gum style --border double --padding "1 2" --border-foreground 212 "Cloning Hecate Dotfiles"

  WORKDIR=$(mktemp -d)
  HECATEDIR="$WORKDIR/Hecate"

  gum style --foreground 220 "Cloning repository..."
  if ! git clone --depth 1 "$REPO_URL" "$HECATEDIR"; then
    gum style --foreground 196 "✗ Error cloning repository!"
    gum style --foreground 196 "Check your internet connection and try again."
    exit 1
  fi

  # Verify critical directories exist
  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "✗ Error: Config directory not found in cloned repo!"
    exit 1
  fi

  fancy_echo "✓ Dotfiles cloned successfully!" "beams"
}

# Writes a new file and renames it into place: `hecate update` is still running from the old one,
# and copying over a script bash is reading makes it run garbage
install_script() {
  local tmp="$2.new.$$"
  cp "$1" "$tmp"
  chmod +x "$tmp"
  mv -f "$tmp" "$2"
}

# Install shell scripts to ~/.local/bin
install_shell_scripts() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Shell Scripts"

  mkdir -p "$HOME/.local/bin"

  local scripts_dir="$HECATEDIR/config/local-bin"

  if [ ! -d "$scripts_dir" ]; then
    gum style --foreground 220 "⚠ Scripts directory not found at $scripts_dir"
    return
  fi

  # Install hecate.sh
  if [ -f "$scripts_dir/hecate.sh" ]; then
    echo "Installing hecate script..."
    install_script "$scripts_dir/hecate.sh" "$HOME/.local/bin/hecate"
    echo "✓ hecate installed to ~/.local/bin/hecate"
  else
    gum style --foreground 220 "⚠ hecate.sh not found at $scripts_dir/hecate.sh"
  fi

  if [ -f "$scripts_dir/termkeys.sh" ]; then
    install_script "$scripts_dir/termkeys.sh" "$HOME/.local/bin/termkeys"
    echo "✓ termkeys installed to ~/.local/bin/termkeys"
  fi

  echo ""
  gum style --foreground 82 "✓ Shell scripts installed successfully!"
}

# Takes our copy of each personal file out of the clone so the copy below can't touch yours
hold_back_personal_files() {
  local rel incoming mine kept
  for rel in "${PERSONAL_FILES[@]}"; do
    incoming="$HECATEDIR/config/$rel"
    mine="$CONFIGDIR/$rel"
    if [ -f "$incoming" ] && [ -f "$mine" ]; then
      kept="$BACKUP_DIR/new-defaults/$rel"
      mkdir -p "$(dirname "$kept")"
      mv "$incoming" "$kept"
      if ! cmp -s "$mine" "$kept"; then KEPT_CHANGED+=("$rel"); fi
    fi
  done
}

# Move configs from cloned repo to ~/.config
move_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Installing Configuration Files"

  if [ ! -d "$HECATEDIR/config" ]; then
    gum style --foreground 196 "Error: Config directory not found at $HECATEDIR/config"
    exit 1
  fi

  mkdir -p "$CONFIGDIR"
  mkdir -p "$HOME/.local/bin"

  hold_back_personal_files

  # Copy all config directories except shell rc files
  for item in "$HECATEDIR/config"/*; do
    if [ -d "$item" ]; then
      local item_name=$(basename "$item")

      # Skip local-bin directory (handled separately)
      if [ "$item_name" = "local-bin" ]; then
        continue
      fi

      # Handle terminal configs - only install selected terminal
      case "$item_name" in
        alacritty|foot|ghostty|kitty)
          if [ "$item_name" = "$USER_TERMINAL" ]; then
            fancy_echo "Installing $item_name config..." "slide"
            cp -rT "$item" "$CONFIGDIR/$item_name"
          fi
          ;;
        *)
          # Install all other configs
          fancy_echo "Installing $item_name..." "slide"
          cp -rT "$item" "$CONFIGDIR/$item_name"
          ;;
      esac
    fi
  done


  install_shell_scripts

  echo ""
  fancy_echo "✓ Configuration files installed successfully!" "beams"
}

backup_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Backing Up Existing Configs"

  BACKUP_DIR="$HOME/.cache/hecate-backup/hecate-$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR/config"

  # Everything the update is about to write over
  local item dir
  for item in "$HECATEDIR/config"/*/; do
    dir=$(basename "$item")
    if [ "$dir" != "local-bin" ] && [ -d "$CONFIGDIR/$dir" ]; then
      fancy_echo "Backing up: $dir" "slide"
      cp -r "$CONFIGDIR/$dir" "$BACKUP_DIR/config/"
    fi
  done

  echo ""
  fancy_echo "✓ Backup created at: $BACKUP_DIR" "beams"
  echo "$BACKUP_DIR" > "$HOME/.cache/hecate_last_backup.txt"
}

# Adds the sections and settings your hecate.toml doesn't have yet, with their comments. Nothing you set
# changes. Prints what it added; on any problem it prints why, leaves your file alone and fails.
merge_hecate_toml() {
  python3 - "$CONFIG_FILE" "$1" <<'PYTHON'
import os, re, sys, tempfile, tomllib

mine_path, new_path = sys.argv[1:3]
mine_text = open(mine_path, encoding="utf-8").read()
new_text = open(new_path, encoding="utf-8").read()
mine, new = tomllib.loads(mine_text), tomllib.loads(new_text)

HEADER = re.compile(r"^\s*\[\s*([A-Za-z0-9_.-]+)\s*\]\s*(#.*)?$")
KEY = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=")


def is_comment(line):
    return line.lstrip().startswith("#")


def find(table, path):
    for part in path.split("."):
        table = table.get(part) if isinstance(table, dict) else None
        if table is None:
            return None
    return table if isinstance(table, dict) else None


def trailing_comments(lines):
    """Splits off the comment block at the end of lines: it describes whatever comes next."""
    end = len(lines)
    while end and not lines[end - 1].strip():
        end -= 1
    start = end
    while start and is_comment(lines[start - 1]):
        start -= 1
    return lines[:start], lines[start:end]


def sections(lines):
    """Yields (path, comments above it, header line, body lines) for each [section] of the template."""
    path, header, comments, body = None, None, [], []
    for line in lines:
        match = HEADER.match(line)
        if not match:
            body.append(line)
            continue
        rest, above = trailing_comments(body)
        if path:
            yield path, comments, header, rest
        path, header, comments, body = match.group(1), line, above, []
    if path:
        yield path, comments, header, body


def settings(body):
    """Yields (key, lines) for each setting, with the comments right above it and any lines its value spans."""
    i, pending = 0, []
    while i < len(body):
        line = body[i]
        if is_comment(line):
            pending.append(line)
        elif not line.strip():
            pending = []
        elif KEY.match(line):
            value = [line]
            while True:
                try:
                    tomllib.loads("\n".join(value))
                    break
                except tomllib.TOMLDecodeError:
                    i += 1
                    value.append(body[i])
            yield KEY.match(line).group(1), pending + value
            pending = []
        i += 1


def still_has(merged, original):
    return all(
        key in merged and (still_has(merged[key], value) if isinstance(value, dict) else merged[key] == value)
        for key, value in original.items()
    )


lines = mine_text.splitlines()
added = []
for path, comments, header, body in sections(new_text.splitlines()):
    existing = find(mine, path)
    if existing is None:
        lines += ["", *comments, header, *body]
        while lines and not lines[-1].strip():
            lines.pop()
        added.append(f"[{path}]")
        continue
    missing = [(key, text) for key, text in settings(body) if key not in existing]
    if not missing:
        continue
    new_lines = [line for _, text in missing for line in text]
    added += [f"{path}.{key}" for key, _ in missing]
    start = next((i for i, l in enumerate(lines) if (m := HEADER.match(l)) and m.group(1) == path), None)
    if start is None:  # only implied by a [path.child] so far
        lines += ["", header, *new_lines]
        continue
    end = start + 1
    while end < len(lines) and not HEADER.match(lines[end]):
        end += 1
    while end > start + 1 and (not lines[end - 1].strip() or is_comment(lines[end - 1])):
        end -= 1
    lines[end:end] = new_lines

if added:
    merged_text = "\n".join(lines) + "\n"
    if not still_has(tomllib.loads(merged_text), mine):
        raise SystemExit("merging would have changed one of your settings")
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(mine_path))
    with os.fdopen(fd, "w", encoding="utf-8") as out:
        out.write(merged_text)
    os.chmod(tmp, os.stat(mine_path).st_mode)
    os.replace(tmp, mine_path)
print(" ".join(added))
PYTHON
}

# Update Hecate config file with new version
update_hecate_config() {
  gum style --border double --padding "1 2" --border-foreground 212 "Updating Hecate Configuration"

  local update_date=$(date +%Y-%m-%d)
  local template="$BACKUP_DIR/new-defaults/hecate/hecate.toml"

  if [ -f "$template" ]; then
    if TOML_ADDED=$(merge_hecate_toml "$template" 2>&1); then
      if [ -n "$TOML_ADDED" ]; then
        gum style --foreground 82 "✓ Added to hecate.toml: $TOML_ADDED"
      fi
    else
      gum style --foreground 220 "⚠ Couldn't add new settings to hecate.toml, so it stays as it was: $TOML_ADDED"
      TOML_ADDED=""
    fi
  fi

  # Update metadata section
  set_config_value "version" "$remote_version" "metadata"
  set_config_value "last_update" "$update_date" "metadata"
  if [ "$SDDM_REMEMBER_DECLINE" = true ]; then
    set_config_value "sddm_switch" "no" "preferences"
  fi

  gum style --foreground 82 "✓ Hecate config updated"
  gum style --foreground 82 "  Version: $remote_version"
  gum style --foreground 82 "  Date: $update_date"
}

# Show update complete message
show_completion_message() {
  echo ""
  gum style --border double --padding "1 2" --border-foreground 82 "✓ Update Complete!"

  gum style --foreground 82 --bold "Hecate has been updated to $remote_version"
  echo ""
  gum style --foreground 220 "📦 Your old configuration was backed up to:"
  gum style --foreground 82 "   $BACKUP_DIR"
  echo ""

  if [ ${#KEPT_CHANGED[@]} -gt 0 ]; then
    gum style --foreground 220 "📝 Kept yours. Our new versions are in $BACKUP_DIR/new-defaults if you want to compare:"
    local rel
    for rel in "${KEPT_CHANGED[@]}"; do
      gum style --foreground 82 "   ~/.config/$rel"
    done
    echo ""
  fi

  if [ -n "$SDDM_RESULT" ]; then
    gum style --foreground 220 "🔐 Login screen:"
    printf '%s\n' "$SDDM_RESULT" | while IFS= read -r line; do
      gum style --foreground 82 "   $line"
    done
    echo ""
  fi

  if [ -n "$SETTINGS_RESULT" ]; then
    gum style --foreground 220 "⚙️  Hecate Settings: $SETTINGS_RESULT"
    echo ""
  fi

  if [ -n "$CONFIG_ERRORS" ]; then
    gum style --foreground 196 "⚠ Hyprland reports problems in your config:"
    printf '%s\n' "$CONFIG_ERRORS" | while IFS= read -r line; do
      gum style --foreground 220 "   $line"
    done
    gum style --foreground 220 "   A keybind or monitor file you kept may need updating. Compare it with new-defaults above."
    echo ""
  fi

  gum style --foreground 220 "🎨 Log out and back in to get everything, including the login reveal."
  echo ""
  gum style --foreground 82 "Thank you for using Hecate! 🌙"
}

# Setup wallpapers
setup_wallpapers() {
  [ "$WALLPAPER_ACTION" != "skip" ] || return 0

  gum style --border double --padding "1 2" --border-foreground 212 "Wallpaper Setup"

  local wallpaper_dir="$WALLPAPER_DIR"

  if [ "$WALLPAPER_ACTION" = "full" ]; then
    # User wants full collection
    gum style --foreground 82 "Downloading wallpaper collection (sparse checkout of images folder)..."

    # Backup existing wallpapers if path exists (could be file, dir, or symlink)
    if [ -e "$wallpaper_dir" ] || [ -L "$wallpaper_dir" ]; then
      local backup_dir="$HOME/Pictures/wallpapers-backup-$(date +%Y%m%d_%H%M%S)"
      gum style --foreground 220 "Backing up existing wallpapers to: $backup_dir"

      if [ -L "$wallpaper_dir" ]; then
        # It's a symlink, just remove it
        rm -f "$wallpaper_dir"
      elif [ -d "$wallpaper_dir" ]; then
        # It's a directory, move it
        mv "$wallpaper_dir" "$backup_dir"
      elif [ -f "$wallpaper_dir" ]; then
        # It's a file, move it
        mv "$wallpaper_dir" "$backup_dir"
      fi
    fi

    # Create temporary directory for sparse checkout
    local temp_dir="$HOME/Pictures/aesthetic-wallpapers-temp"
    mkdir -p "$temp_dir"

    # Perform sparse checkout
    (
      cd "$temp_dir" || exit 1
      git init
      git remote add origin "https://github.com/D3Ext/aesthetic-wallpapers.git"
      git sparse-checkout init --cone
      git sparse-checkout set --no-cone images
      git pull origin main
    )

    if [ -d "$temp_dir/images" ]; then
      # Move the images folder to wallpaper_dir
      mv "$temp_dir/images" "$wallpaper_dir"
      rm -rf "$temp_dir"
      echo "✓ Full wallpaper collection downloaded!"
    else
      gum style --foreground 196 "✗ Images folder not found in repository"
      rm -rf "$temp_dir"
      return 1
    fi
  else
    # User wants only default wallpapers
    gum style --foreground 82 "Downloading default wallpapers..."
    local default_dir="$wallpaper_dir"
    mkdir -p "$default_dir"

    local lock_screen_url="https://raw.githubusercontent.com/D3Ext/aesthetic-wallpapers/refs/heads/main/images/3squares.png"
    local wallpaper_url="https://raw.githubusercontent.com/D3Ext/aesthetic-wallpapers/refs/heads/main/images/falltree.jpg"

    # Download lock screen
    echo "Downloading lock-screen.png..."
    curl -fsSL "$lock_screen_url" -o "$default_dir/lock-screen.png" && \
      echo "✓ lock-screen.png downloaded"

    # Download wallpaper
    echo "Downloading wallpaper.png..."
    curl -fsSL "$wallpaper_url" -o "$default_dir/wallpaper.png" && \
      echo "✓ wallpaper.png downloaded"

    echo ""
    echo "✓ Default wallpapers downloaded!"
  fi

  echo ""
  gum style --foreground 82 "Wallpapers saved to: $wallpaper_dir"
}
setup_Symlinks() {
  gum style --foreground 220 "Configuring Symlinks..."

  # Define symlink paths
  local STARSHIP_SYMLINK="$HOME/.config/starship.toml"
  local HYPRLOCK_SYMLINK="$HOME/.config/hypr/hyprlock.conf"

  # Only where there's nothing usable yet: `hecate lock` may have picked another lock screen
  if [ ! -e "$STARSHIP_SYMLINK" ]; then
    ln -sfn "$HOME/.config/starship/starship.toml" "$STARSHIP_SYMLINK"
  fi
  if [ ! -e "$HYPRLOCK_SYMLINK" ]; then
    ln -sfn "$HOME/.config/hypr/hyprlock/hecate-lock.conf" "$HYPRLOCK_SYMLINK"
  fi
  gum style --foreground 82 "✓ Symlinks configured!"
}
# ---- Login screen ----

sddm_config_files() {
  local file
  for file in "$SDDM_ROOT"/usr/lib/sddm/sddm.conf.d/* "$SDDM_ROOT"/etc/sddm.conf.d/* "$SDDM_ROOT"/etc/sddm.conf; do
    if [ -f "$file" ]; then printf '%s\n' "$file"; fi
  done
}

# Sets SETTING_VALUE and SETTING_FILE for a [Theme] key. SDDM reads the files above in that order and the last one wins.
sddm_theme_setting() {
  local file found
  SETTING_VALUE=""
  SETTING_FILE=""
  while IFS= read -r file; do
    found=$(awk -v key="$1" '
      /^[[:space:]]*\[/ { in_theme = ($0 ~ /^[[:space:]]*\[Theme\]/); next }
      in_theme && index($0, key "=") == 1 { value = "=" substr($0, length(key) + 2) }
      END { print value }
    ' "$file" 2>/dev/null || true)
    if [ -n "$found" ]; then
      SETTING_VALUE="${found#=}"
      SETTING_FILE="$file"
    fi
  done < <(sddm_config_files)
}

sddm_themes_dir() {
  sddm_theme_setting ThemeDir
  printf '%s%s\n' "$SDDM_ROOT" "${SETTING_VALUE:-/usr/share/sddm/themes}"
}

# The folder of the theme SDDM will load, whether Current= is a name or a full path
sddm_active_theme_dir() {
  sddm_theme_setting Current
  local current="$SETTING_VALUE"
  case "$current" in
    "") ;;
    /*) printf '%s%s\n' "$SDDM_ROOT" "$current" ;;
    *) printf '%s/%s\n' "$(sddm_themes_dir)" "$current" ;;
  esac
}

sddm_is_active() {
  [ "$(basename "$(readlink -f "$SDDM_ROOT/etc/systemd/system/display-manager.service" 2>/dev/null)")" = "sddm.service" ]
}

theme_id() {
  [ -f "$1/metadata.desktop" ] && sed -n 's/^Theme-Id=//p' "$1/metadata.desktop" | head -n1
}

ask_about_login_screen() {
  sddm_is_active || return 0

  if ! command -v sddm-greeter-qt6 &>/dev/null; then
    gum style --foreground 220 "⚠ Skipping the login screen: hecate-sddm needs SDDM's Qt6 greeter (sddm-greeter-qt6)."
    return 0
  fi

  SDDM_THEME_DIR=$(sddm_active_theme_dir)
  local id
  id=$(theme_id "$SDDM_THEME_DIR" || true)

  if [ "$id" = "hecate-sddm" ]; then
    if gum confirm "Update the hecate-sddm login screen? Your theme settings are kept. (needs sudo)"; then
      SDDM_ACTION="update"
    fi
  elif [ "$(get_config_value "sddm_switch" "preferences")" != "no" ]; then
    if gum confirm --default=false "Switch your login screen from ${id:-the default theme} to hecate-sddm? (needs sudo)"; then
      SDDM_ACTION="switch"
    else
      SDDM_REMEMBER_DECLINE=true
    fi
  fi
}

# Copies the theme and SDDM's settings next to the other backups. A plain copy makes them yours, so
# sudo is only for files you can't read, and then they're handed over to you.
backup_login_theme() {
  local dest="$BACKUP_DIR/sddm" owner
  owner="$(id -u):$(id -g)"
  mkdir -p "$dest/conf" || return 1

  if [ -d "$SDDM_THEME_DIR" ] && ! cp -r "$SDDM_THEME_DIR" "$dest/theme" 2>/dev/null; then
    rm -rf "$dest/theme"   # what the failed copy got through, or sudo's copy would land inside it
    sudo cp -r "$SDDM_THEME_DIR" "$dest/theme" && sudo chown -R "$owner" "$dest" || return 1
  fi

  local file
  while IFS= read -r file; do
    if ! cp "$file" "$dest/conf/" 2>/dev/null; then
      sudo cp "$file" "$dest/conf/" && sudo chown "$owner" "$dest/conf/$(basename "$file")" || return 1
    fi
  done < <(sddm_config_files)
}

# Our theme.conf with your value for every setting you have, so comments and new settings arrive and nothing resets
merge_theme_conf() {
  awk '
    function key_of(line) { sub(/=.*/, "", line); return line }
    NR == FNR {
      if ($0 ~ /^[^#;\[][^=]*=/) { key = key_of($0); if (!(key in mine)) order[++count] = key; mine[key] = $0 }
      next
    }
    $0 ~ /^[^#;\[][^=]*=/ {
      key = key_of($0)
      if (key in mine) { print mine[key]; used[key] = 1; next }
    }
    { print }
    END { for (i = 1; i <= count; i++) if (!(order[i] in used)) print mine[order[i]] }
  ' "$1" "$2"
}

# Gets the new theme fully ready as you, then swaps it in as one step
install_login_theme() {
  local staged="$WORKDIR/login-theme" dest="$1"

  cp -r "$HECATEDIR/hecate-sddm" "$staged" || return 1

  if [ "$SDDM_ACTION" = "update" ]; then
    if [ -f "$SDDM_THEME_DIR/theme.conf" ]; then
      merge_theme_conf "$SDDM_THEME_DIR/theme.conf" "$HECATEDIR/hecate-sddm/theme.conf" >"$staged/theme.conf" || return 1
    fi
    if [ -f "$SDDM_THEME_DIR/theme.conf.user" ]; then
      cp "$SDDM_THEME_DIR/theme.conf.user" "$staged/" || return 1
    fi
    local image
    for image in "$SDDM_THEME_DIR"/backgrounds/*; do
      if [ -e "$image" ] && [ ! -e "$staged/backgrounds/$(basename "$image")" ]; then
        cp -r "$image" "$staged/backgrounds/" || return 1
      fi
    done
  fi

  sudo mkdir -p "$(dirname "$dest")" || return 1
  sudo rm -rf "$dest.new" "$dest.old" || return 1
  sudo cp -r "$staged" "$dest.new" || return 1
  sudo chown -R root:root "$dest.new" || return 1
  sudo chmod -R u=rwX,go=rX "$dest.new" || return 1

  if [ -e "$dest" ]; then
    sudo mv "$dest" "$dest.old" || return 1
  fi
  if ! sudo mv "$dest.new" "$dest"; then
    if [ -e "$dest.old" ]; then sudo mv "$dest.old" "$dest" || true; fi
    return 1
  fi
  sudo rm -rf "$dest.old" || true

  if command -v restorecon &>/dev/null; then
    sudo restorecon -R "$dest" || true
  fi
}

# The installer's hecate.conf can lose to a file that sorts after it, so this sorts last and then checks it won
switch_to_login_theme() {
  local drop_in="$SDDM_ROOT/etc/sddm.conf.d/zz-hecate.conf"

  sudo mkdir -p "$(dirname "$drop_in")" || return 1
  printf '[Theme]\nCurrent=hecate-sddm\n' | sudo tee "$drop_in" >/dev/null || return 1

  sddm_theme_setting Current
  if [ "$SETTING_VALUE" != "hecate-sddm" ]; then
    SDDM_RESULT+="$SETTING_FILE still sets Current=$SETTING_VALUE and overrides it. Remove that line to finish switching."$'\n'
  fi
}

needs_qt5compat() {
  [ ! -d /usr/lib/qt6/qml/Qt5Compat ] && [ ! -d /usr/lib64/qt6/qml/Qt5Compat ]
}

# Never fails the update, and never restarts SDDM: that would end your session. It applies at your next login.
update_login_theme() {
  [ "$SDDM_ACTION" != "none" ] || return 0

  gum style --border double --padding "1 2" --border-foreground 212 "Login Screen"

  if needs_qt5compat; then
    case "$OS" in
      arch) install_packages qt6-5compat qt6-svg || true ;;
      fedora) install_packages qt6-qt5compat qt6-qtsvg || true ;;
    esac
    if needs_qt5compat; then
      SDDM_RESULT="Not changed: hecate-sddm needs Qt5Compat, which isn't installed."
      return 0
    fi
  fi

  if ! backup_login_theme; then
    SDDM_RESULT="Not changed: the current theme couldn't be backed up."
    return 0
  fi

  local backup="$BACKUP_DIR/sddm" dest
  if [ "$SDDM_ACTION" = "update" ]; then
    dest="$SDDM_THEME_DIR"
  else
    dest="$(sddm_themes_dir)/hecate-sddm"
  fi

  if ! install_login_theme "$dest"; then
    SDDM_RESULT="Not changed: the new theme couldn't be installed. Your current one is untouched or back in place."
    return 0
  fi

  SDDM_RESULT=""
  if [ "$SDDM_ACTION" = "switch" ]; then
    if ! switch_to_login_theme; then
      SDDM_RESULT="hecate-sddm is installed but couldn't be set as the theme. Set Current=hecate-sddm in /etc/sddm.conf.d/."$'\n'
    fi
    SDDM_RESULT+="Switched to hecate-sddm. It shows at your next login."$'\n'
    SDDM_RESULT+="To undo: sudo rm /etc/sddm.conf.d/zz-hecate.conf"$'\n'
  else
    SDDM_RESULT+="hecate-sddm updated, keeping your theme settings. It shows at your next login."$'\n'
    if [ -d "$backup/theme" ]; then
      SDDM_RESULT+="To undo: sudo rm -rf \"$dest\" && sudo cp -r \"$backup/theme\" \"$dest\""$'\n'
    fi
  fi
  SDDM_RESULT+="Your previous theme and SDDM settings were copied to $backup"$'\n'
  SDDM_RESULT+="Those copies are owned by $(id -un), not root, so you can open and edit them without sudo."
  SDDM_RESULT="${SDDM_RESULT%$'\n'}"

  if command -v notify-send &>/dev/null; then
    notify-send "Hecate login theme" "Your previous theme was copied to $backup, owned by you." || true
  fi
}

# ---- Everything else ----

ask_about_settings_app() {
  if ! command -v cargo &>/dev/null || ! command -v qmake6 &>/dev/null; then
    SETTINGS_RESULT="not rebuilt, because that needs cargo and qmake6."
    return 0
  fi
  local default=false
  if [ -x "$HOME/.local/bin/hecate-settings" ]; then default=true; fi
  if gum confirm --default="$default" "Rebuild Hecate Settings? It compiles from source, so it can take a few minutes."; then
    SETTINGS_REBUILD=true
  fi
}

rebuild_settings_app() {
  [ "$SETTINGS_REBUILD" = true ] || return 0

  if gum spin --spinner dot --title "Building Hecate Settings (log: $SETTINGS_LOG)..." -- \
    bash -c 'bash "$1/apps/hecate-settings/install.sh" >"$2" 2>&1' _ "$HECATEDIR" "$SETTINGS_LOG"; then
    SETTINGS_RESULT="rebuilt."
  else
    SETTINGS_RESULT="the build failed, so you still have the old version. See $SETTINGS_LOG"
  fi
}

ask_about_wallpapers() {
  WALLPAPER_DIR=$(get_config_value "dir" "wallpaper")
  WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
  WALLPAPER_DIR="${WALLPAPER_DIR/#\~/$HOME}"

  if [ -d "$WALLPAPER_DIR" ] && [ -n "$(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print -quit)" ]; then
    return 0
  fi

  if gum confirm "You have no wallpapers yet. Download the full collection? (No downloads just two)"; then
    WALLPAPER_ACTION="full"
  else
    WALLPAPER_ACTION="defaults"
  fi
}

# All the questions come before any work, so the rest can run unattended
ask_update_choices() {
  ask_about_login_screen
  ask_about_settings_app
  ask_about_wallpapers

  if [ "$SDDM_ACTION" != "none" ] && ! sudo -v; then
    SDDM_ACTION="none"
    SDDM_RESULT="Not changed, because sudo wasn't available."
  fi
}

# Brings a running session up to date. None of this can fail the update.
refresh_desktop() {
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 0

  gum style --foreground 220 "Refreshing your session..."

  # The update reset the generated colors, like the prompt's palette
  local wallpaper="$HOME/.cache/hecate/wallpaper"
  if [ -e "$wallpaper" ]; then
    "$CONFIGDIR/hecate/scripts/set-wallpaper.sh" "$wallpaper" >/dev/null 2>&1 || \
      gum style --foreground 220 "⚠ Couldn't reapply your wallpaper's colors"
  fi

  hyprctl reload >/dev/null 2>&1 || true
  CONFIG_ERRORS=$(hyprctl configerrors 2>/dev/null | grep -v '^[[:space:]]*$' | grep -vi '^no errors' || true)

  # Its file watcher can miss a bulk copy, so it restarts rather than reloads
  if pkill -x quickshell 2>/dev/null || pkill -x qs 2>/dev/null; then
    sleep 0.3
    setsid -f quickshell >/dev/null 2>&1 </dev/null || true
  fi
}

# Main update flow
main() {
  trap on_exit EXIT

  clear

  # Pre-flight checks: installing gum needs the OS, and everything after this needs gum
  detect_os
  check_dependencies

  gum style \
    --border double \
    --padding "1 2" \
    --border-foreground 212 \
    --bold \
    "🌙 Hecate Update Manager"

  echo ""

  check_hecate_installed

  echo ""

  # Read user configuration
  read_user_config

  echo ""
  # Check versions and get confirmation; nothing changes until all of this has passed
  check_versions
  check_system

  echo ""
  show_update_warning
  echo ""
  ask_update_choices

  # Perform update
  clone_dotfiles
  backup_config

  APPLYING=true
  move_config
  update_hecate_config
  setup_Symlinks
  refresh_desktop
  APPLYING=false

  # Extras: if one of these goes wrong, the update itself has still worked
  update_login_theme
  rebuild_settings_app
  setup_wallpapers || gum style --foreground 220 "⚠ Wallpapers couldn't be downloaded. You can add your own to $WALLPAPER_DIR"

  # Show completion
  show_completion_message
}

# Run main function
main

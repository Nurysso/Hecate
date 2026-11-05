#!/usr/bin/env bash
# Builds hecate-settings from source and installs it for the current user:
#   binary        -> ~/.local/bin/hecate-settings
#   icon          -> ~/.local/share/icons/hicolor/scalable/apps/hecate-settings.svg
#   desktop entry -> ~/.local/share/applications/hecate-settings.desktop
# The desktop entry is what gives the app its icon in the Quickshell bar.
#
# Usage: ./install.sh [--uninstall]
# Override the destinations with BIN_DIR and DATA_DIR.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BIN_DIR=${BIN_DIR:-$HOME/.local/bin}
DATA_DIR=${DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}}
bin=$BIN_DIR/hecate-settings
icon=$DATA_DIR/icons/hicolor/scalable/apps/hecate-settings.svg
entry=$DATA_DIR/applications/hecate-settings.desktop
cache_icon=${XDG_CACHE_HOME:-$HOME/.cache}/hecate/hecate-settings.svg

fail() {
  printf '\033[0;31m✗ %s\033[0m\n' "$1" >&2
  [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2
  exit 1
}

if [ "${1:-}" = "--uninstall" ]; then
  rm -f -- "$bin" "$icon" "$entry" "$cache_icon"
  echo "✓ hecate-settings removed"
  exit 0
fi

case "$(. /etc/os-release 2>/dev/null; echo "${ID:-}")" in
  arch | manjaro | endeavouros | cachyos) hint="sudo pacman -S --needed rust qt6-base qt6-declarative qt6-wayland base-devel" ;;
  *) hint="install Rust (cargo), a C++ compiler, and the Qt 6 base, declarative (QML) and wayland packages for your distro" ;;
esac

cargo --version >/dev/null 2>&1 || fail "cargo is missing or has no toolchain" "$hint (with rustup, run: rustup default stable)"
command -v c++ >/dev/null || command -v g++ >/dev/null || command -v clang++ >/dev/null || fail "no C++ compiler found" "$hint"

QMAKE=${QMAKE:-$(command -v qmake6 || command -v qmake-qt6 || true)}
[ -n "$QMAKE" ] || fail "Qt 6 was not found (no qmake6)" "$hint"
export QMAKE

qml=$("$QMAKE" -query QT_INSTALL_QML)
[ -d "$qml/QtQuick/Controls/Basic" ] || fail "Qt Quick Controls is missing from $qml" "$hint"

[ -f "$here/../../scripts/config_schema.json" ] || fail "scripts/config_schema.json is missing from this checkout" "the app embeds it at build time; regenerate it with scripts/gen_schema.py"

plugins=$("$QMAKE" -query QT_INSTALL_PLUGINS)
ls "$plugins/platforms" 2>/dev/null | grep -qi wayland || echo "⚠ Qt's Wayland plugin was not found, the app may not start on Hyprland ($hint)"

echo "Building hecate-settings (the first build takes a minute or two)..."
locked=()
[ -f "$here/Cargo.lock" ] && locked=(--locked)
(cd "$here" && cargo build --release "${locked[@]}")

install -Dm755 "$here/target/release/hecate-settings" "$bin"
install -Dm644 "$here/data/hecate-settings.svg" "$icon"
install -Dm644 "$here/data/hecate-settings.svg" "$cache_icon"
# Write the desktop entry for the current user (paths resolved at install time)
exec_path=$bin
case "$bin" in *" "*) exec_path=\"$bin\" ;; esac
install -dm755 "$(dirname -- "$entry")"
cat >"$entry" <<EOF
[Desktop Entry]
Type=Application
Name=Hecate Settings
GenericName=Settings
Comment=Configure the Hecate Hyprland dotfiles
Exec=$exec_path
Icon=$cache_icon
Terminal=false
Categories=Settings;DesktopSettings;
Keywords=hecate;hyprland;settings;config;
StartupWMClass=hecate-settings
EOF
chmod 644 "$entry"
update-desktop-database "$DATA_DIR/applications" >/dev/null 2>&1 || true

echo "✓ hecate-settings installed"
echo "  binary   $bin"
echo "  icon     $icon"
echo "  entry    $entry"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "⚠ $BIN_DIR is not in your PATH, so run it by full path or launch it from your app menu" ;; esac

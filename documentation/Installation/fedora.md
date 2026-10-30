# Fedora Installation

> **The Fedora install script is outdated** and no longer matches the dotfiles, so `install.sh` stops on Fedora and points here.

Follow the [manual installation guide](manual-install.md). Fedora notes:

- Hyprland, `hyprlock` and `hypridle` come from the Fedora repos or the `solopasha/hyprland` COPR.
- `quickshell`, `matugen` and `awww` may need a COPR or a build from source; check each project's install page.
- Qt 6 packages: `qt6-qtbase-devel`, `qt6-qtdeclarative-devel`, `qt6-qtwayland` (needed to build `hecate-settings`).
- Fonts: Inter, JetBrainsMono Nerd Font and Symbols Nerd Font.
- Package names differ from the Arch ones in the guide; search with `dnf search`.

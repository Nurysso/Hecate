# Arch Linux Installation

Arch and Arch-based systems (Manjaro, EndeavourOS, CachyOS) are fully supported.

## Run the installer

```bash
git clone https://github.com/Nurysso/Hecate.git ~/Hecate
cd ~/Hecate
./install.sh
```

Or without cloning first: `bash <(curl -fsSL https://raw.githubusercontent.com/Nurysso/Hecate/main/install.sh)`

The installer installs `gum` if it is missing, asks for your terminal, shell, browser, profile and theme mode up front, then:

1. Installs packages with pacman (and `paru`/`yay` for AUR ones)
2. Backs up existing configs to `~/.cache/hecate-backup/`
3. Copies the configs, rc files and helper commands
4. Writes `~/.config/hecate/hecate.toml` and `quickapps.conf`
5. Builds `hecate-settings` in the background
6. Offers the wallpaper collection and the SDDM theme

## Options

| Flag | Effect |
|------|--------|
| `--check` | Only report missing tools and fonts, change nothing |
| `--no-deps` | Skip packages: configs, hecate-settings and wallpapers only |
| `--help` | Show usage |

`HECATEDIR=<dir>` changes where the repo is cloned (default `~/Hecate`). Run from a checkout, the installer uses that checkout.

Packages that fail to install are listed in `~/hecate_failed_packages.txt`.

## Next

Reboot, log into Hyprland, and see the [manual guide](manual-install.md#troubleshooting) if something is missing.

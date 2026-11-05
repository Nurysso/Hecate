# Fedora Installation

Fedora has its own installer, ported from the Arch one. It is new and hasn't been tried on every Fedora release, so check what it reports and follow [manual-install.md](manual-install.md) for anything it can't do.

## Run the installer

```bash
git clone https://github.com/Nurysso/Hecate.git ~/Hecate
cd ~/Hecate
./install.sh
```

It asks for your terminal, shell, browser, profile and theme mode up front, then:

1. Sets up repositories for what you picked: RPM Fusion (Steam and Discord, gamer profile), Brave and Google Chrome repos
2. Installs packages with `dnf`. Names the repos don't offer are looked up in a COPR (`errornointernet/quickshell`, `solopasha/hyprland`, `atim/starship`, `lihaohong/yazi`, `scottames/ghostty`)
3. Downloads JetBrainsMono Nerd Font and Symbols Nerd Font into `~/.local/share/fonts`, since Fedora doesn't package them
4. Builds `matugen` and `awww` with cargo into `~/.local/bin`, since Fedora doesn't package them
5. Backs up existing configs to `~/.cache/hecate-backup/`, copies the configs, rc files and helper commands, and writes `~/.config/hecate/hecate.toml`
6. Builds `hecate-settings` in the background (with its icon and desktop entry)
7. Offers the wallpaper collection and the SDDM theme

Packages that can't be found are listed at the end and saved to `~/hecate_failed_packages.txt`.

## Options

| Flag | Effect |
|------|--------|
| `--check` | Only report missing tools and fonts, change nothing |
| `--no-deps` | Skip packages: configs, hecate-settings and wallpapers only |
| `--help` | Show usage |

## Notes

- Make sure `~/.local/bin` is in your `PATH`: `matugen`, `awww` and `hecate-settings` live there.
- `terraform` is not in the Fedora repos; install it from HashiCorp if you chose DevOps.
- PCSX2, RPCS3 and ProtonUp-Qt are installed from Flathub.
- Building `awww` needs `lz4-devel`, `wayland-devel` and `libxkbcommon-devel`; the installer includes them.

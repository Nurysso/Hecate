#!/usr/bin/env bash

# Starship Color Updater
# Generates dynamic starship.toml from pywal colors

STARSHIP_CONFIG="$HOME/.config/starship.toml"
BACKUP_CONFIG="$HOME/.config/starship.toml.backup"
COLOR_FILE="$HOME/.cache/wal/colors.sh"

# Source pywal colors
if [ -f "$COLOR_FILE" ]; then
  source "$COLOR_FILE"
else
  echo "Error: Pywal colors not found at $COLOR_FILE"
  echo "Please run 'wal' to generate colors first."
  exit 1
fi

# Backup existing config
if [ -f "$STARSHIP_CONFIG" ]; then
  cp "$STARSHIP_CONFIG" "$BACKUP_CONFIG"
fi

# Create the starship.toml file with pywal colors
cat >"$STARSHIP_CONFIG" <<EOF
# ────────────────────────────────────────────────────────────────
# 🌟 Starship Prompt Configuration
# Modern, clean prompt — Hecate Theme Edition
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ────────────────────────────────────────────────────────────────

"\$schema" = 'https://starship.rs/config-schema.json'

# Add a blank line between prompts for readability
add_newline = true

# Reduce lag for modules
command_timeout = 500

# Main prompt layout
format = """
[╭─](bold ${color2})\$username\$hostname\$directory\$git_branch\$git_status\$cmd_duration\$fill\$time
[╰─](bold ${color2})\$character
"""

# ─── PROMPT SYMBOLS ─────────────────────────────────────────────

[character]
success_symbol = "[➜](bold ${color2})"
error_symbol = "[✗](bold ${color1})"
vicmd_symbol = "[V](bold ${color3})"

# ─── USER & HOST ────────────────────────────────────────────────

[username]
style_user = "bold ${color3}"
style_root = "bold ${color1}"
format = "[\$user](\$style)"
show_always = true

[hostname]
ssh_only = false
format = "[@\$hostname](bold ${color4}) "
disabled = false

# ─── DIRECTORY ──────────────────────────────────────────────────

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold ${color6}"
read_only = " "
format = "[in](dim ${color8}) [\$path](\$style)[\$read_only](\$read_only_style) "

# ─── GIT ────────────────────────────────────────────────────────

[git_branch]
symbol = " "
format = "on [\$symbol\$branch](\$style) "
style = "bold ${color5}"

[git_status]
format = '([\[\$all_status\$ahead_behind\]](\$style) )'
style = "bold ${color1}"
conflicted = "🏳 "
ahead = "⇡\${count} "
diverged = "⇕⇡\${ahead_count}⇣\${behind_count} "
behind = "⇣\${count} "
untracked = "?\${count} "
stashed = "💾\${count} "
modified = "!\${count} "
staged = "+\${count} "
renamed = "»\${count} "
deleted = "✘\${count} "

# ─── LANGUAGES ──────────────────────────────────────────────────

[nodejs]
symbol = " "
format = "via [\$symbol(\$version )](\$style)"
style = "bold ${color2}"

[python]
symbol = " "
style = "bold ${color3}"

[rust]
symbol = " "
format = "via [\$symbol(\$version )](\$style)"
style = "bold ${color1}"

[java]
symbol = " "
format = "via [\$symbol(\$version )](\$style)"
style = "bold ${color1}"

[package]
symbol = " "
format = "[\$symbol\$version](\$style)"
style = "bold ${color4}"

[golang]
symbol = " "
format = "via [$symbol($version )]($style)"
style = "bold ${color6}"

[lua]
symbol = " "
format = "via [\$symbol(\$version )](\$style)"
style = "bold ${color4}"

# ─── MISC MODULES ───────────────────────────────────────────────

[cmd_duration]
min_time = 500
format = "[took \$duration](bold ${color3}) "

[time]
disabled = false
format = "[\$time](dim ${color8})"
time_format = "%R"  # 24h format

[fill]
symbol = " "

# ─── BATTERY / OS / EXTRAS ──────────────────────────────────────

[battery]
disabled = false
full_symbol = "🔋"
charging_symbol = "⚡"
discharging_symbol = "💀"
format = "[\$symbol \$percentage](\$style) "

[[battery.display]]
threshold = 10
style = "bold ${color1}"

[[battery.display]]
threshold = 30
style = "bold ${color3}"

[[battery.display]]
threshold = 100
style = "bold ${color2}"

[os]
disabled = false
format = "[\$symbol](\$style)"
style = "dim ${color7}"

[os.symbols]
Arch = " "
Ubuntu = " "
Debian = " "
Fedora = " "
Manjaro = " "
NixOS = " "
Pop = " "
Raspbian = " "

# ─── DOCKER / KUBERNETES ────────────────────────────────────────

[docker_context]
symbol = " "
format = "via [\$symbol\$context](bold ${color4}) "

[kubernetes]
symbol = "☸ "
format = 'on [\$symbol\$context( \(\$namespace\))](bold ${color4}) '
disabled = false

# ─── CLOUD PROVIDERS ────────────────────────────────────────────

[aws]
symbol = " "
format = 'on [\$symbol(\$profile )(\$region )](bold ${color3}) '

[gcloud]
format = 'on [\$symbol\$account(@\$domain)(\$region)](bold ${color4}) '

[azure]
symbol = " "
format = 'on [\$symbol(\$subscription)](bold ${color4}) '

# ─── END OF FILE ────────────────────────────────────────────────
EOF

echo "✓ Starship config updated successfully"
echo "  File: $STARSHIP_CONFIG"
echo ""
echo "Color mapping:"
echo "  • Prompt frame: ${color2}"
echo "  • Success:      ${color2}"
echo "  • Error:        ${color1}"
echo "  • Username:     ${color3}"
echo "  • Hostname:     ${color4}"
echo "  • Directory:    ${color6}"
echo "  • Git branch:   ${color5}"
echo "  • Git status:   ${color1}"
echo ""
echo "Changes will apply on next prompt"

#!/bin/bash
# Print the keybinds from the current terminal's config, grouped by its "# ─── Group ───" comments.
# Usage: termkeys [kitty|alacritty|foot|ghostty]

cfg="${XDG_CONFIG_HOME:-$HOME/.config}"

detect() {
  [ -n "$KITTY_WINDOW_ID" ] && { echo kitty; return; }
  [ -n "$ALACRITTY_WINDOW_ID" ] && { echo alacritty; return; }
  [ "$TERM_PROGRAM" = ghostty ] && { echo ghostty; return; }
  # foot sets no env var of its own (our foot.ini sets TERM=xterm-256color), so walk up the process tree
  local pid=$PPID name
  while [ "${pid:-1}" -gt 1 ]; do
    name=$(ps -o comm= -p "$pid")
    case "$name" in kitty | alacritty | foot | ghostty) echo "$name"; return ;; esac
    pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  done
}

term=${1:-$(detect)}
case "$term" in
  kitty) file="$cfg/kitty/kitty.conf" ;;
  alacritty) file="$cfg/alacritty/alacritty.toml" ;;
  foot) file="$cfg/foot/foot.ini" ;;
  ghostty) file="$cfg/ghostty/config" ;;
  *) echo "termkeys: unknown terminal '$term', pass one of: kitty alacritty foot ghostty" >&2; exit 1 ;;
esac
[ -f "$file" ] || { echo "termkeys: $file not found" >&2; exit 1; }

[ -t 1 ] && color=1
awk -v t="$term" -v color="$color" '
  function out(k, a) { printf "  %-32s %s\n", k, a }
  /^[[:space:]]*# ─── / {
    sub(/^[[:space:]]*# ─── /, ""); sub(/ ─.*$/, "")
    printf (color ? "\n\033[1;34m%s\033[0m\n" : "\n%s\n"), $0
    next
  }
  t == "kitty" && /^map / { k = $2; $1 = $2 = ""; sub(/^ +/, ""); out(k, $0) }
  t == "ghostty" && /^keybind *=/ { sub(/^keybind *= */, ""); i = index($0, "="); out(substr($0, 1, i - 1), substr($0, i + 1)) }
  t == "foot" && /^\[/ { keys = ($0 == "[key-bindings]") }
  t == "foot" && keys && /^[a-z-]+=/ { i = index($0, "="); k = substr($0, i + 1); gsub(/ /, " / ", k); out(k, substr($0, 1, i - 1)) }
  t == "alacritty" && /\{ *key *=/ {
    k = $0; sub(/.*key *= *"/, "", k); sub(/".*/, "", k)
    m = ""; if ($0 ~ /mods *=/) { m = $0; sub(/.*mods *= *"/, "", m); sub(/".*/, "", m); gsub(/\|/, "+", m); m = m "+" }
    a = $0; sub(/.*action *= *"/, "", a); sub(/".*/, "", a)
    out(m k, a)
  }
' "$file"
echo

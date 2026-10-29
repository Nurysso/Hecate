#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# Shared by bash and zsh (sourced from bashrc/zshrc). Fish mirrors this in config.fish.

# ─── PATH ───────────────────────────────────────────────────────
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":/snap/bin:"*) ;; *) [ -d /snap/bin ] && PATH="$PATH:/snap/bin" ;; esac
export PATH

# ─── Environment ────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R'

# ─── FZF (Tokyo Night, matches the terminals) ───────────────────
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --margin=1 --padding=1 \
--color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a \
--preview-window=right:60%:wrap"
export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:wrap --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"

# ─── Aliases ────────────────────────────────────────────────────
. "${XDG_CONFIG_HOME:-$HOME/.config}/shell/aliases"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ─── Functions ──────────────────────────────────────────────────
# Fuzzy cd to any directory under ~
cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . ~ |
    fzf --prompt="📁 Select directory: " --height 50% \
      --preview 'eza --tree --level=2 --icons --color=always {}')
  [ -n "$dir" ] && cd "$dir" && ls
}

# Fuzzy file edit
vf() {
  local file
  file=$(fd --type f --hidden --exclude .git |
    fzf --prompt="✏️  Select file to edit: " --height 50% \
      --preview 'bat --color=always --style=numbers --line-range :500 {}')
  [ -n "$file" ] && ${EDITOR:-nvim} "$file"
}

# Fuzzy history: fh_pick prints the chosen command, fh runs it
fh_pick() {
  fc -ln 1 | sed 's/^[[:space:]]*//' | fzf --tac --no-sort --prompt="🔍 History: " --height 50% \
    --preview 'echo {}' --preview-window up:3:wrap
}
fh() {
  local cmd
  cmd=$(fh_pick) && eval "$cmd"
}

# Fuzzy kill process (SIGTERM; pass a signal to override, e.g. fkill -9)
fkill() {
  local pid
  pid=$(ps -ef | sed 1d |
    fzf --prompt="💀 Select process to kill: " --height 50% \
      --preview 'echo {}' --preview-window down:3:wrap |
    awk '{print $2}')
  [ -n "$pid" ] && echo "Killing process $pid" && kill "${1:--TERM}" "$pid"
}

# Create and enter directory
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any common archive
extract() {
  [ -f "$1" ] || { echo "'$1' is not a valid file"; return 1; }
  case "$1" in
    *.tar | *.tar.* | *.tgz | *.tbz2 | *.txz) tar xf "$1" ;;
    *.zip) unzip "$1" ;;
    *.rar) unrar x "$1" ;;
    *.7z) 7z x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.xz) unxz "$1" ;;
    *.zst) unzstd "$1" ;;
    *.Z) uncompress "$1" ;;
    *) echo "'$1' cannot be extracted via extract()"; return 1 ;;
  esac
}

# ─── Tools ──────────────────────────────────────────────────────
command -v thefuck >/dev/null && eval "$(thefuck --alias)"

# uv/cargo-style env file, if present
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

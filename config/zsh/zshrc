#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# ═══════════════════════════════════════════════════════════════
# ZSH Configuration with Starship and custom functions for quality of life
# ═══════════════════════════════════════════════════════════════

# ZSH installation path
export ZSH="$HOME/.oh-my-zsh"

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"              # User local binaries (priority)
export PATH="$PATH:/snap/bin"                     # Snap package binaries

# ───────────────────────────────────────────────────────────────
# Plugin Configuration
# ───────────────────────────────────────────────────────────────
plugins=(
    sudo                      # Press ESC twice to prepend sudo
    history                   # History command enhancements
    fzf                       # Fuzzy finder integration
    zsh-autosuggestions       # Fish-like autosuggestions
    zsh-syntax-highlighting   # Syntax highlighting for commands
    thefuck                   # Corrects previous command errors
    command-not-found         # Suggests package for missing commands
    colored-man-pages         # Colorful man pages
)

# Load Oh-My-Zsh (without theme)
ZSH_THEME=""  # Disable Oh-My-Zsh themes (Starship will handle this)
source $ZSH/oh-my-zsh.sh

# ───────────────────────────────────────────────────────────────
# Starship Prompt Initialization
# ───────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ───────────────────────────────────────────────────────────────
# History Configuration
# ───────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY                  # Share history between sessions
setopt HIST_EXPIRE_DUPS_FIRST         # Remove duplicates first
setopt HIST_IGNORE_DUPS               # Don't store duplicated commands
setopt HIST_FIND_NO_DUPS              # Don't display duplicates when searching
setopt HIST_REDUCE_BLANKS             # Remove superfluous blanks
setopt APPENDHISTORY                  # Append to history file
setopt HIST_IGNORE_SPACE              # Don't save commands starting with space

# ───────────────────────────────────────────────────────────────
# FZF Configuration
# ───────────────────────────────────────────────────────────────
# Source FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh) 2>/dev/null || true

# FZF Appearance - Match Starship theme
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --margin=1
  --padding=1
  --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
  --preview-window=right:60%:wrap
"

# FZF Commands - Use modern tools
export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always --line-range :500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="
  --preview 'exa --tree --level=2 --icons --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window up:3:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
"

# ───────────────────────────────────────────────────────────────
# Completion System
# ───────────────────────────────────────────────────────────────
autoload -Uz compinit

# Load completions only once a day for faster shell startup
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# Better completion behavior
zstyle ':completion:*' menu select                          # Menu-driven completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # Colorful completion
zstyle ':completion:*' rehash true                          # Automatically find new executables

# ───────────────────────────────────────────────────────────────
# Aliases - System Information
# ───────────────────────────────────────────────────────────────
alias fast='fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc'

# ───────────────────────────────────────────────────────────────
# Aliases - Modern Command Replacements
# ───────────────────────────────────────────────────────────────
alias ls='exa --icons --group-directories-first'
alias ll='exa -la --icons --group-directories-first'
alias lt='exa -T --icons --level=2'
alias la='exa -la --icons --group-directories-first --git'
alias l='exa -l --icons --group-directories-first'

alias cat='bat --style=plain'                    # Use bat for cat
alias catp='bat --style=full'                    # Bat with line numbers

alias icat='kitty icat'                          # Display images in terminal

# ───────────────────────────────────────────────────────────────
# Aliases - Directory Navigation
# ───────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias doc='cd ~/Documents/'
alias dow='cd ~/Downloads/'
alias pic='cd ~/Pictures/'

# ───────────────────────────────────────────────────────────────
# Aliases - System Utilities
# ───────────────────────────────────────────────────────────────
alias meminfo='free -m'
alias cpuinfo='lscpu'
alias ports='sudo netstat -tulanp'
alias rdb='rm ~/.cache/cliphist/db'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ───────────────────────────────────────────────────────────────
# Custom Functions
# ───────────────────────────────────────────────────────────────

# Fuzzy cd to any directory
cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . ~ | \
    fzf --prompt="📁 Select directory: " \
        --height 50% \
        --preview 'exa --tree --level=2 --icons --color=always {}')
  if [[ -n "$dir" ]]; then
    cd "$dir" || return
    ls  # Show contents after cd
  fi
}

# Fuzzy file edit
vf() {
  local file
  file=$(fd --type f --hidden --exclude .git | \
    fzf --prompt="✏️  Select file to edit: " \
        --height 50% \
        --preview 'bat --color=always --style=numbers --line-range :500 {}')
  if [[ -n "$file" ]]; then
    ${EDITOR:-nvim} "$file"
  fi
}

# Fuzzy history search and execute
fh() {
  local cmd
  cmd=$(history | \
    fzf --prompt="🔍 Search history: " \
        --tac \
        --height 50% \
        --preview 'echo {}' \
        --preview-window up:3:wrap | \
    sed 's/ *[0-9]* *//')
  if [[ -n "$cmd" ]]; then
    eval "$cmd"
  fi
}

# Fuzzy kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | \
    fzf --prompt="💀 Select process to kill: " \
        --height 50% \
        --preview 'echo {}' \
        --preview-window down:3:wrap | \
    awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "Killing process $pid"
    kill -9 "$pid"
  fi
}

# Create and enter directory
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ───────────────────────────────────────────────────────────────
# Key Bindings
# ───────────────────────────────────────────────────────────────
bindkey -v  # Vi mode (comment out if you prefer emacs mode)

# Custom key bindings
bindkey '^[[A' history-substring-search-up      # Up arrow
bindkey '^[[B' history-substring-search-down    # Down arrow
bindkey '^[[3~' delete-char                     # Delete key
bindkey '^?' backward-delete-char               # Backspace key

# FZF key bindings (using zle)
bindkey -s '^g' 'cdf\n'      # Ctrl+G: fuzzy cd
bindkey -s '^e' 'vf\n'       # Ctrl+E: fuzzy edit
bindkey -s '^f' 'fh\n'       # Ctrl+F: fuzzy history

# ───────────────────────────────────────────────────────────────
# TheFuck Integration
# ───────────────────────────────────────────────────────────────
eval $(thefuck --alias)
eval $(thefuck --alias fk)  # Short alias 'fk'

# ───────────────────────────────────────────────────────────────
# Environment Variables
# ───────────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R'

# Load custom environment variables if they exist
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# ───────────────────────────────────────────────────────────────
# Performance & Misc Settings
# ───────────────────────────────────────────────────────────────
# Reduce ESC key delay in vi mode
export KEYTIMEOUT=1

# Enable colors
autoload -U colors && colors

# Disable beep
unsetopt BEEP

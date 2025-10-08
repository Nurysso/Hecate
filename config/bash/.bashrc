#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# ═══════════════════════════════════════════════════════════════
# BASH Configuration with Starship and custom functions for quality of life
# ═══════════════════════════════════════════════════════════════

# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# PATH Configuration
export PATH="$PATH:/snap/bin"
export PATH="$HOME/.local/bin:$PATH"

# History Configuration
export HISTFILE=~/.bash_history
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"

# Bash Options
shopt -s checkwinsize  # Update LINES and COLUMNS after each command
shopt -s globstar      # Enable ** for recursive globbing
shopt -s cdspell       # Auto-correct minor spelling errors in cd

# Enable bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# FZF Configuration
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="--preview 'exa --tree --level=1 {}'"

# TheFuck alias
command -v thefuck &> /dev/null && eval "$(thefuck --alias)"

# Starship Prompt
command -v starship &> /dev/null && eval "$(starship init bash)"

# Aliases
alias fast='fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc'
alias ls='exa --icons --group-directories-first'
alias ll='exa -la --icons --group-directories-first'
alias lt='exa -T --icons --level=2'
alias la='exa -a --icons --group-directories-first'
alias icat='kitty icat'
# alias rm='vx --noconfirm'

# Directory shortcuts
alias doc='cd ~/Documents/'
alias dow='cd ~/Downloads/'
alias pic='cd ~/Pictures/'
alias rdb='rm ~/.cache/cliphist/db'

# System utilities
alias meminfo='free -m'
alias cpuinfo='lscpu'
alias ports='sudo netstat -tulanp'
alias df='df -h'
alias du='du -h'

# Git aliases (if not using oh-my-bash git plugin)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

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

# Bind Ctrl+G to `cdf`
bind -x '"\C-g": cdf'

# Bind Ctrl+E to `vf` (edit file)
bind -x '"\C-e": vf'

# Bind Ctrl+F: fuzzy history
bind -x '"\C-f": fh\n'

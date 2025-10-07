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

# Custom function: fuzzy cd
cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . ~ | fzf --height 40% --reverse)
  if [[ -n "$dir" ]]; then
    cd "$dir" || return
  fi
}

# Custom function: fuzzy file edit
vf() {
  local file
  file=$(fd --type f --hidden --exclude .git | fzf --height 40% --reverse --preview 'bat --color=always {}')
  if [[ -n "$file" ]]; then
    ${EDITOR:-vim} "$file"
  fi
}

# Custom function: fuzzy history search
fh() {
  eval "$(history | fzf --height 40% --reverse --tac | sed 's/ *[0-9]* *//')"
}

# Bind Ctrl+G to `cdf`
bind -x '"\C-g": cdf'

# Bind Ctrl+E to `vf` (edit file)
bind -x '"\C-e": vf'

# Note: Ctrl+R is already bound to FZF history search if FZF is installed

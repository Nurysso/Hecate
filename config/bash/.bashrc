# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

export OSH='/home/dawu/.oh-my-bash'
OSH_THEME="agnoster"
source "$OSH"/oh-my-bash.sh
export PATH="$PATH:/snap/bin"
export PATH="$HOME/.local/bin:$PATH"



OMB_USE_SUDO=true

completions=(
  git
  composer
  ssh
)

aliases=(
  general
)

plugins=(
  git
  bashmarks
)
export HISTFILE=~/.bash_history
export HISTSIZE=100000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
export FZF_ALT_C_OPTS="--preview 'exa --tree --level=1 {}'"
eval "$(thefuck --alias)"


# Aliases
alias fast='fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc'
alias ls='exa --icons --group-directories-first'
alias ll='exa -la --icons --group-directories-first'
alias lt='exa -T --icons --level=2'
alias icat='kitty icat'
# alias rm='vx --noconfirm'

alias doc='cd ~/Documents/'
alias dow='cd ~/Downloads/'
alias pic='cd ~/Pictures/'
alias rdb='rm ~/.cache/cliphist/db'

# System utilities
# alias upgrade='sudo pacman -Syu'
alias meminfo='free -m'
alias cpuinfo='cat /proc/cpuinfo'
alias ports='sudo netstat -tulanp'
cdf() {
  local dir
  dir=$(fd --type d --hidden --exclude .git . ~ | fzf)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}

# Bind Ctrl+G to `cdf`
bind -x '"\C-g": cdf'

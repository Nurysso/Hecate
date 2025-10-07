#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# Must stay at the top of ~/.zshrc to work properly
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH installation path
export ZSH="$HOME/.oh-my-zsh"                     # Path to oh-my-zsh installation

# PATH Configuration
# These define where the shell looks for executables
export PATH="$PATH:/snap/bin"                     # Snap package binaries
export PATH="$HOME/.local/bin:$PATH"              # User local binaries



# Theme Configuration
ZSH_THEME="powerlevel10k/powerlevel10k"          # Set the ZSH theme to Powerlevel10k
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# Enhanced Plugins
plugins=(
    sudo                 # Press ESC twice to prepend sudo
    history              # History command enhancements
    fzf                  # Fuzzy finder integration
    zsh-autosuggestions  # Fish-like autosuggestions
    zsh-syntax-highlighting  # Syntax highlighting for commands
    thefuck              # Corrects previous command errors
)

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh                        # Initialize Oh-My-Zsh with the configuration

# alias poke='pokemon-colorscripts --no-title -s -n'

# System information display (alternative to neofetch)
alias fast='fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc'  # Display system info

# History Configuration
HISTFILE=~/.zsh_history                         # History file location
HISTSIZE=100000                                 # Number of commands to store in memory
SAVEHIST=100000                                 # Number of commands to save in history file
setopt SHARE_HISTORY                            # Share history between sessions
setopt HIST_EXPIRE_DUPS_FIRST                   # Remove duplicates first when history is full
setopt HIST_IGNORE_DUPS                         # Don't store duplicated commands
setopt HIST_FIND_NO_DUPS                        # Don't display duplicates when searching
setopt HIST_REDUCE_BLANKS                       # Remove superfluous blanks from commands
setopt APPENDHISTORY                            # Append to history file instead of overwriting

# FZF (Fuzzy Finder) Configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh          # Source FZF if installed
source <(fzf --zsh)                             # Set up FZF key bindings for zsh

# FZF key bindings enhancement
export FZF_CTRL_T_COMMAND="fd --type f --hidden --follow --exclude .git"  # Use fd instead of find for better performance
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"  # Preview files with bat
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"  # Directory search with fd
export FZF_ALT_C_OPTS="--preview 'exa --tree --level=1 {}'"  # Preview directories with exa

# Modern command replacements
# Uncomment if you have these tools installed
alias ls='exa --icons --group-directories-first'  # Replace ls with exa
alias ll='exa -la --icons --group-directories-first'  # Detailed list
alias lt='exa -T --icons --level=2'               # Tree view (2 levels)
# alias rm='vx --noconfirm'
alias icat='kitty icat'

# Directory shortcuts
alias doc='cd ~/Documents/'                     # Jump to Documents
alias dow='cd ~/Downloads/'                     # Jump to Downloads
alias pic='cd ~/Pictures/'                  # Jump to Programming
alias rdb='rm ~/.cache/cliphist/db'

# System utilities
# alias upgrade='sudo pacman -Syu'                # Update Arch Linux
alias meminfo='free -m'                         # Show memory info
alias cpuinfo='cat /proc/cpuinfo'               # Show CPU info
alias ports='sudo netstat -tulanp'              # Show open ports


# TheFuck setup - for correcting previous command errors
eval $(thefuck --alias)                         # Initialize 'thefuck' alias

# Source environment variables if they exist
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"  # Load custom environment variables

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh    # Load Powerlevel10k configuration if it exists


# Load zsh-autosuggestions and zsh-syntax-highlighting if not loaded by Oh-My-Zsh
# These should be at the end of .zshrc for proper functioning
# [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
# [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autoload zsh functions for advanced usage
autoload -Uz compinit                           # Initialize completion system
compinit                                        # Load completions

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

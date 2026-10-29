#  _   _ _____ ____    _  _____ _____
# | | | | ____/ ___|  / \|_   _| ____|     /\_/\
# | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
# |  _  | |__| |___ / ___ \| | | |___      > ^ <
# |_| |_|_____\____/_/   \_\_| |_____|

# Mirrors ~/.config/shell/common.sh (bash/zsh); aliases come from the shared file.

# === PATH ===
fish_add_path -g $HOME/.local/bin
fish_add_path -ga /snap/bin

# === Environment ===
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS -R
set -g fish_greeting

# === FZF (Tokyo Night, matches the terminals) ===
set -gx FZF_DEFAULT_OPTS "--height=40% --layout=reverse --border=rounded --margin=1 --padding=1 \
--color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff \
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a \
--preview-window=right:60%:wrap"
set -gx FZF_CTRL_T_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
set -gx FZF_CTRL_R_OPTS "--preview 'echo {}' --preview-window up:3:wrap --bind 'ctrl-/:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"

# === Aliases (shared with bash and zsh) ===
source (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/shell/aliases

# === Functions ===
# Fuzzy cd to any directory under ~
function cdf
    set dir (fd --type d --hidden --exclude .git . ~ | fzf --prompt="📁 Select directory: " --height 50% \
        --preview 'eza --tree --level=2 --icons --color=always {}')
    test -n "$dir"; and cd "$dir"; and ls
    commandline -f repaint
end

# Fuzzy file edit
function vf
    set file (fd --type f --hidden --exclude .git | fzf --prompt="✏️  Select file to edit: " --height 50% \
        --preview 'bat --color=always --style=numbers --line-range :500 {}')
    test -n "$file"; and $EDITOR "$file"
    commandline -f repaint
end

# Fuzzy history: fh_pick prints the chosen command, fh runs it
function fh_pick
    history | fzf --no-sort --prompt="🔍 History: " --height 50% --preview 'echo {}' --preview-window up:3:wrap
end

function fh
    set cmd (fh_pick); and eval $cmd
end

# Fuzzy kill process (SIGTERM; pass a signal to override, e.g. fkill -9)
function fkill
    set pid (ps -ef | sed 1d | fzf --prompt="💀 Select process to kill: " --height 50% \
        --preview 'echo {}' --preview-window down:3:wrap | awk '{print $2}')
    test -n "$pid"; or return
    echo "Killing process $pid"
    kill (set -q argv[1]; and echo $argv[1]; or echo -TERM) $pid
end

# Create and enter directory
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

# Extract any common archive
function extract
    test -f "$argv[1]"; or begin
        echo "'$argv[1]' is not a valid file"
        return 1
    end
    switch $argv[1]
        case '*.tar' '*.tar.*' '*.tgz' '*.tbz2' '*.txz'
            tar xf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*.rar'
            unrar x $argv[1]
        case '*.7z'
            7z x $argv[1]
        case '*.gz'
            gunzip $argv[1]
        case '*.bz2'
            bunzip2 $argv[1]
        case '*.xz'
            unxz $argv[1]
        case '*.zst'
            unzstd $argv[1]
        case '*.Z'
            uncompress $argv[1]
        case '*'
            echo "'$argv[1]' cannot be extracted via extract()"
            return 1
    end
end

# === Key bindings (same in bash and zsh) ===
#   Ctrl+R history · Ctrl+T files · Alt+C dirs   (fzf)
#   Ctrl+G cdf · Ctrl+E vf · Ctrl+F fh · Up/Down prefix history search (fish default)
command -q fzf; and fzf --fish | source
bind \cg cdf
bind \ce vf
bind \cf 'set -l cmd (fh_pick); and commandline -r -- $cmd; and commandline -f execute; or commandline -f repaint'

# === Tools ===
command -q thefuck; and thefuck --alias | source
test -f $HOME/.local/bin/env.fish; and source $HOME/.local/bin/env.fish
command -q starship; and starship init fish | source

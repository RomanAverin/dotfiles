# ============================================================================
# ZSH Benchmark Configuration (Optional)
# ============================================================================
# Uncomment the line below to enable startup benchmarking
# export ZSH_BENCHMARK="Yes"


# Benchmark initialization (only if enabled)
if [[ "$ZSH_BENCHMARK" == "Yes" ]]; then
    zmodload zsh/datetime
    zmodload zsh/zprof 2>/dev/null
    typeset -g _zsh_load_start=$EPOCHREALTIME
fi

# Load secrets
[ -f ~/.secrets ] && source ~/.secrets

### enable zinit and download zinit, if it's not there yet
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Define cache directory
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# Create cache and completions dir and add to $fpath
# for the oh-my-zsh error search plugins
mkdir -p "$ZSH_CACHE_DIR/completions"
(( ${fpath[(Ie)"$ZSH_CACHE_DIR/completions"]} )) || fpath=("$ZSH_CACHE_DIR/completions" $fpath)

# Fix insecure completion directories automatically
# This prevents "compinit: insecure directories" warnings
_fix_compinit_insecure_dirs() {
  local insecure_dirs
  insecure_dirs="$(compaudit 2>/dev/null)"

  if [[ -n "$insecure_dirs" ]]; then
    echo "Fixing insecure completion directories..." >&2
    echo "$insecure_dirs" | xargs chmod g-w,o-w 2>/dev/null
    echo "$insecure_dirs" | xargs chown -R "$USER" 2>/dev/null
  fi
}

# Run the fix before compinit initialization
# _fix_compinit_insecure_dirs
#

# Run to fix a broken completions
function zinit-fix-completions() {
  local broken
  broken=$(find ~/.local/share/zinit/completions -xtype l)
  
  if [[ -z "$broken" ]]; then
    echo "No broken completions found"
    return 0
  fi

  echo "Removing broken completions:"
  echo "$broken"
  find ~/.local/share/zinit/completions -xtype l -delete
  echo "Done. Restarting shell..."
  exec zsh
}

# Early compinit initialization with caching for OMZ plugins
# This prevents "compdef: command not found" errors from OMZ snippets
autoload -Uz compinit
if [[ -n ${ZSH_CACHE_DIR}/compdump(#qN.mh+24) ]]; then
  compinit -d "${ZSH_CACHE_DIR}/compdump"
else
  compinit -C -d "${ZSH_CACHE_DIR}/compdump"
fi

# Setup of a cursor shape
reset-cursor() {
    echo -ne '\e[6 q'
}
precmd_functions+=(reset-cursor)

# Add Starship
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Add in zsh plugins
zinit ice depth=1
zinit light zdharma-continuum/history-search-multi-word
zinit light Aloxaf/fzf-tab
# zinit ice depth=1
# zinit light jeffreytse/zsh-vi-mode

# Add in snippets
zinit snippet OMZ::lib/clipboard.zsh
zinit snippet OMZ::lib/directories.zsh
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::cp
zinit snippet OMZP::sudo
zinit snippet OMZP::pip
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::dotenv
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
zinit snippet OMZP::rust
zinit snippet OMZP::virtualenv
zinit snippet OMZP::mise
zinit snippet OMZP::uv



### Auto completions
# Load completions with proper initialization order
zinit wait lucid for \
    atpull'zinit creinstall -q .' \
    blockf \
    zsh-users/zsh-completions

zinit wait'1' lucid for \
    atload'zicdreplay' \
    zdharma-continuum/fast-syntax-highlighting \
    atload'!_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions

# Completion styling
zstyle ':completion:*:git-checkout:*' sort false # disable sort when completing `git checkout`
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>' # switch group using `<` and `>`

### History options
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

### Bind keys
# Fix Ctrl+H: prevent PTY from interpreting it as erase in SSH sessions
[[ -t 0 ]] && stty erase '^?'
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
# bindkey '^[[A' history-search-backward
# bindkey '^[[B' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
zle_highlight+=(paste:none)

### Environment variables 
export PATH=$HOME/.local/bin:/usr/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export EDITOR='nvim'
export VISUAL='nvim'

export UID=$(id -u) 
export GID=$(id -g)
export XDG_CONFIG_HOME=$HOME/.config

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

### Aliases
# Some alias
function s() {
  wezterm cli spawn --domain-name SSH:$1
}
alias fix_compinit_insecure_dirs="_fix_compinit_insecure_dirs"
alias remove_nvim_folders="rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim"
alias ls="ls --color"
alias zshconfig="vim ~/.zshrc"
alias flushdns="sudo systemd-resolve --flush-caches"
alias compose="podman-compose"
alias show_use_ports="sudo lsof -i -P -n | grep LISTEN"
alias preview='nvim $(fzf -m --preview="bat --color=always {}")'
alias zsh-bench='ZSH_BENCHMARK=Yes zsh'

# Update all
alias update_all="sudo dnf upgrade --refresh --assumeyes && flatpak update --assumeyes && flatpak remove --unused"

# Ollama and openwebui
alias ollama='f() { if [ "$1" = "stop" ]; then
    (cd ~/dockers/open-webui-docker && docker compose down --remove-orphans);
  elif [[ "$1" = "start" ]]; then
    (cd ~/dockers/open-webui-docker && docker compose up -d);
  fi;
}; f'

# Dotfiles-manager 
alias dotfiles="~/dotfiles/dotfiles-manager/dotfiles-manager.py"

# fnm (Fast Node Manager)
#
FNM_PATH="/home/rastler/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
fi

eval "$(fnm env --use-on-cd --shell zsh)"

# Golang
export GOPATH=$HOME/Develop/go
export PATH=$HOME/Develop/go/bin:$PATH

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Deno
. "$HOME/.deno/env"
# Add deno completions to search path
# if [[ ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then export FPATH="$HOME/.zsh/completions:$FPATH"; fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
[ -s "$HOME/.bun" ] && export BUN_INSTALL="$HOME/.bun" 
[ -f "$BUN_INSTALL/bin/bun" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# Fzf settings
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude .cache"

# https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6IiIsImJvcmRlckxhYmVsUG9zaXRpb24iOjAsInByZXZpZXdCb3JkZXJTdHlsZSI6InJvdW5kZWQiLCJwYWRkaW5nIjoiMCIsIm1hcmdpbiI6IjAiLCJwcm9tcHQiOiI+ICIsIm1hcmtlciI6Ij4iLCJwb2ludGVyIjoi4oebIiwic2VwYXJhdG9yIjoi4pSAIiwic2Nyb2xsYmFyIjoi4pSCIiwibGF5b3V0IjoiZGVmYXVsdCIsImluZm8iOiJyaWdodCIsImNvbG9ycyI6ImZnOiNDNUM4RDMsZmcrOiNkMGQwZDAsYmc6IzMwMzUzQixiZys6IzMwMzUzQixobDojZmZmZmZmLGhsKzojZGU5MzVmLGluZm86I2FmYWY4NyxtYXJrZXI6Izg3ZmYwMCxwcm9tcHQ6I0QwQUIzQyxzcGlubmVyOiNhZjVmZmYscG9pbnRlcjojZmZmZmZmLGhlYWRlcjojODdhZmFmLGJvcmRlcjojNjU2NjZiLGxhYmVsOiNhZWFlYWUscXVlcnk6I2Q5ZDlkOSJ9
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#C5C8D3,fg+:#d0d0d0,bg:#30353B,bg+:#30353B
  --color=hl:#EFC986,hl+:#de935f,info:#afaf87,marker:#A9C476
  --color=prompt:#D0AB3C,spinner:#ffffff,pointer:#ffffff,header:#95739C
  --color=border:#65666b,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="⇛" --separator="─" --scrollbar="│"
  --info="right"'

# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

# Set up tms
# cargo install --git https://github.com/jrmoulton/tmux-sessionizer.git --tag v0.5.0
source <(COMPLETE=zsh tms)

# Set up zoxide as default cd command
# eval "$(zoxide init --cmd cd zsh)"
eval "$(zoxide init zsh)"

# Set up python uv autocomplion
eval "$(uv generate-shell-completion zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/lmstudio/bin"
# End of LM Studio CLI section

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# The next line enables shell command completion for yc.
if [ -f '$HOME/yandex-cloud/completion.zsh.inc' ]; then source '$HOME/yandex-cloud/completion.zsh.inc'; fi

# Activate mise
[ -f "$HOME/.local/bin/mise" ] && eval "$($HOME/.local/bin/mise activate zsh)"

# ============================================================================
# ZSH Benchmark Report (if enabled)
# ============================================================================
if [[ "$ZSH_BENCHMARK" == "Yes" ]]; then
    # Capture end time immediately to avoid measuring benchmark code itself
    typeset -g _zsh_load_end=$EPOCHREALTIME
    typeset -g total_ms=$(( (_zsh_load_end - _zsh_load_start) * 1000 ))

    # Source benchmark UI module
    local BENCH_UI="${${(%):-%x}:A:h}/benchmark.zsh"
    [[ -r "$BENCH_UI" ]] && source "$BENCH_UI" || \
        printf "\n⚠️  Benchmark enabled but UI not found at: %s\n" "$BENCH_UI"

    # Ask user whether to close the benchmark session
    local _bench_reply
    read -r "?Close benchmark session? [Y/n] " _bench_reply
    [[ -z "$_bench_reply" || "$_bench_reply" =~ ^[Yy]$ ]] && exit
fi

# fnm
FNM_PATH="/home/rastler/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

export PATH=/opt/nvim-linux-x86_64/bin:$PATH

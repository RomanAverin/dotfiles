# Load secrets
[ -f ~/.secrets ] && source ~/.secrets

### enable zinit and download zinit, if it's not there yet
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

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
zinit snippet OMZP::uv

# Create cache and completions dir and add to $fpath
# for the oh-my-zsh error search plugins
mkdir -p "$ZSH_CACHE_DIR/completions"
(( ${fpath[(Ie)"$ZSH_CACHE_DIR/completions"]} )) || fpath=("$ZSH_CACHE_DIR/completions" $fpath)


### Auto completions
# Load completions
zinit wait lucid for \
 atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

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
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

my-backward-delete-word() {
    local WORDCHARS=$WORDCHARS
    WORDCHARS="${WORDCHARS//\/}"  # delete / from WORDCHARS
    WORDCHARS="${WORDCHARS//.}"   # delete . from WORDCHARS
    zle backward-delete-word
}
zle -N my-backward-delete-word
bindkey '^W' my-backward-delete-word

bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
# movement with ctrl key and vi move keys
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search
bindkey '^l' forward-word
bindkey '^h' backward-word

### Environment variables 
export PATH=$HOME/.local/bin:/usr/local/bin:$:/usr/local/go/bin:$PATH

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
alias remove_nvim_folders="rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim"
alias ls="ls --color"
alias zshconfig="vim ~/.zshrc"
alias flushdns="sudo systemd-resolve --flush-caches"
alias compose="podman-compose"
alias show_use_ports="sudo lsof -i -P -n | grep LISTEN"
#alias syncing_mount="~/syncing.sh mount"
#alias syncing_umount="~/syncing.sh umount"
alias preview='nvim $(fzf -m --preview="bat --color=always {}")'

# Update all
alias update_all="sudo dnf upgrade --refresh --assumeyes && flatpak update --assumeyes && flatpak remove --unused"

# Ollama and openwebui
alias ollama='f() { if [ "$1" = "stop" ]; then
    (cd ~/dockers/open-webui-docker && docker compose down --remove-orphans);
  elif [[ "$1" = "start" ]]; then
    (cd ~/dockers/open-webui-docker && docker compose up -d);
  fi;
}; f'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Golang
export GOPATH=$HOME/Develop/go
export PATH=$HOME/Develop/go/bin:$PATH

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Deno 
. "$HOME/.deno/env"
# Add deno completions to search path
# if [[ ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then export FPATH="$HOME/.zsh/completions:$FPATH"; fi

# Fzf settings
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude .cache"

# https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6IiIsImJvcmRlckxhYmVsUG9zaXRpb24iOjAsInByZXZpZXdCb3JkZXJTdHlsZSI6InJvdW5kZWQiLCJwYWRkaW5nIjoiMCIsIm1hcmdpbiI6IjAiLCJwcm9tcHQiOiI+ICIsIm1hcmtlciI6Ij4iLCJwb2ludGVyIjoi4oebIiwic2VwYXJhdG9yIjoi4pSAIiwic2Nyb2xsYmFyIjoi4pSCIiwibGF5b3V0IjoiZGVmYXVsdCIsImluZm8iOiJyaWdodCIsImNvbG9ycyI6ImZnOiNDNUM4RDMsZmcrOiNkMGQwZDAsYmc6IzMwMzUzYixiZys6IzMwMzUzYixobDojRDBBQjNDLGhsKzojY2M2NjY2LGluZm86I2FmYWY4NyxtYXJrZXI6Izg3ZmYwMCxwcm9tcHQ6I0QwQUIzQyxzcGlubmVyOiNhZjVmZmYscG9pbnRlcjojYWY1ZmZmLGhlYWRlcjojODdhZmFmLGJvcmRlcjojNjU2NjZiLGxhYmVsOiNhZWFlYWUscXVlcnk6I2Q5ZDlkOSJ9
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#C5C8D3,fg+:#d0d0d0,bg:#30353b,bg+:#30353b
  --color=hl:#D0AB3C,hl+:#cc6666,info:#afaf87,marker:#87ff00
  --color=prompt:#D0AB3C,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#65666b,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="⇛" --separator="─" --scrollbar="│"
  --info="right"'

# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source <(fzf --zsh)

# Set up zoxide as default cd command
eval "$(zoxide init --cmd cd zsh)"

# Set up python uv autocomplion
eval "$(uv generate-shell-completion zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/rastler/.lmstudio/bin"
# End of LM Studio CLI section


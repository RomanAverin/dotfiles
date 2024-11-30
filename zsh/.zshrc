### Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### enable zinit and download zinit, if it's not there yet
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

### Loads plugins
# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zi snippet OMZ::lib/clipboard.zsh
zi snippet OMZ::lib/directories.zsh
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::cp
zinit snippet OMZP::sudo
zinit snippet OMZP::pip
zinit snippet OMZP::command-not-found
zinit snippet OMZP::dotenv
zinit snippet OMZP::docker
zinit snippet OMZP::docker-compose
zinit snippet OMZP::rust

# Create cache and completions dir and add to $fpath
# for the oh-my-zsh error search plugins
mkdir -p "$ZSH_CACHE_DIR/completions"
(( ${fpath[(Ie)"$ZSH_CACHE_DIR/completions"]} )) || fpath=("$ZSH_CACHE_DIR/completions" $fpath)


### Auto completions
# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

### History options
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

### Bind keys
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

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

### Oh My Zsh configuration

# ZSH_THEME="refined"
# HYPHEN_INSENSITIVE="true"
# zstyle ':omz:update' frequency 3 # how often to auto-update (in days)
# zstyle ':omz:update' mode auto   # update automatically without asking
# COMPLETION_WAITING_DOTS="true"
# source $ZSH/oh-my-zsh.sh


### Enable zsh plugins
# plugins=(git docker docker-compose pip rust zsh-autosuggestions cp command-not-found)

### Antigen
# source ~/antigen.zsh

# Load theme
# antigen theme romkatv/powerlevel10k

# Load the oh-my-zsh's library.
# antigen use ohmyzsh/ohmyzsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
# antigen bundle command-not-found

# Syntax highlighting bundle.
# antigen bundle zsh-users/zsh-syntax-highlighting

# Tell Antigen that you're done.
# antigen apply

### Aliases
# Some alias
alias s="wezterm ssh"
alias ls="ls --color"
alias zshconfig="vim ~/.zshrc"
alias flushdns="sudo systemd-resolve --flush-caches"
alias compose="podman-compose"
alias show_use_ports="sudo lsof -i -P -n | grep LISTEN"
#alias syncing_mount="~/syncing.sh mount"
#alias syncing_umount="~/syncing.sh umount"
alias invokeai_run="/home/rastler/invokeai/invoke.sh"


# Update all
alias update_all="sudo dnf upgrade --refresh --assumeyes && flatpak update --assumeyes && flatpak remove --unused"

# Force set Wayland variable of Firefox
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    export MOZ_ENABLE_WAYLAND=1
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Golang
export GOPATH=$HOME/Develop/go
export PATH=$HOME/Develop/go/bin:$PATH

# Rust
export PATH=/home/rastler/.cargo/bin:$PATH

#
# CUDA path
#export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
#export LD_LIBRARY_PATH=/usr/lib64/cuda${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
#

# Deno 
. "/home/rastler/.deno/env"
# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/rastler/.zsh/completions:"* ]]; then export FPATH="/home/rastler/.zsh/completions:$FPATH"; fi

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
eval "$(zoxide init --cmd cd zsh)"
# Fzf settings
# https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6ImZ6ZiIsImJvcmRlckxhYmVsUG9zaXRpb24iOjAsInByZXZpZXdCb3JkZXJTdHlsZSI6InJvdW5kZWQiLCJwYWRkaW5nIjoiMCIsIm1hcmdpbiI6IjAiLCJwcm9tcHQiOiI+ICIsIm1hcmtlciI6Ij4iLCJwb2ludGVyIjoi4peGIiwic2VwYXJhdG9yIjoi4pSAIiwic2Nyb2xsYmFyIjoi4pSCIiwibGF5b3V0IjoiZGVmYXVsdCIsImluZm8iOiJyaWdodCIsImNvbG9ycyI6ImZnOiNlMmUyZTMsZmcrOiNkMGQwZDAsYmc6IzIyMjMyNyxiZys6IzIyMjMyNyxobDojNWY4N2FmLGhsKzojNWZkN2ZmLGluZm86I2FmYWY4NyxtYXJrZXI6IzllZDA3Mixwcm9tcHQ6I2ZjNWQ3YyxzcGlubmVyOiM3NmNjZTAscG9pbnRlcjojYWY1ZmZmLGhlYWRlcjojODdhZmFmLGJvcmRlcjojNDU0NTQ1LHNlcGFyYXRvcjojNGU0ZTRlLHNjcm9sbGJhcjojMGMwYzBjLGxhYmVsOiNhZWFlYWUscXVlcnk6I2Q5ZDlkOSJ9
# export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
#   --color=fg:#e2e2e3,fg+:#d0d0d0,bg:#222327,bg+:#222327
#   --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#9ed072
#   --color=prompt:#fc5d7c,spinner:#76cce0,pointer:#af5fff,header:#87afaf
#   --color=border:#454545,separator:#4e4e4e,scrollbar:#0c0c0c,label:#aeaeae
#   --color=query:#d9d9d9
#   --border="rounded" --border-label="fzf" --border-label-pos="0" --preview-window="border-rounded"
#   --prompt="> " --marker=">" --pointer="◆" --separator="─"
#   --scrollbar="│" --info="right"'

# bun completions
[ -s "/home/rastler/.bun/_bun" ] && source "/home/rastler/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"



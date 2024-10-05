### History options

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS

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

ZSH_THEME="refined"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' frequency 3	# how often to auto-update (in days)
zstyle ':omz:update' mode auto      	# update automatically without asking
COMPLETION_WAITING_DOTS="true"
plugins=(git docker docker-compose pip rust zsh-autosuggestions cp)
source $ZSH/oh-my-zsh.sh


### Antigen
source ~/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
#antigen theme robbyrussell

# Tell Antigen that you're done.
antigen apply

### Aliases
# Kitty ssh
alias s="kitten ssh"
#alias vim="nvim"
alias ls="ls --color"
alias zshconfig="vim ~/.zshrc"
alias flushdns="sudo systemd-resolve --flush-caches"
alias compose="podman-compose"
alias show_use_ports="sudo lsof -i -P -n | grep LISTEN"
#alias syncing_mount="~/syncing.sh mount"
#alias syncing_umount="~/syncing.sh umount"
alias invokeai_run="/home/rastler/invokeai/invoke.sh"

# Update all
alias update_all="sudo dnf5 upgrade --refresh --assumeyes && flatpak update --assumeyes && flatpak remove --unused"
### DNF
alias dnf="dnf5"
alias dnf.upgrade="sudo dnf5 upgrade --refresh --assumeyes"
alias dnf.install="sudo dnf5 install"
alias dnf.remove="sudo dnf5 remove"
alias dnf.search="sudo dnf5 --cacheonly search"
alias dnf.provides="sudo dnf5 --cacheonly provides"
alias dnf.list_installed="sudo dnf5 --cacheonly list installed"
alias dnf.repolist="sudo dnf5 --cacheonly repolist"
alias dnf.list_package_files="sudo dnf5 --cacheonly repoquery --list"
alias dnf.history_list="sudo dnf5 --cacheonly history list --reverse"
alias dnf.history_info="sudo dnf5 --cacheonly history info"
alias dnf.requires="sudo dnf5 --cacheonly repoquery --requires --resolve"
alias dnf.info="sudo dnf5 --cacheonly info"
alias dnf.whatrequires="sudo dnf5 repoquery --installed --whatrequires"
alias dnf.repo_disable="sudo dnf5 config-manager --set-disabled"

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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/rastler/.anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/rastler/.anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/rastler/.anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/rastler/.anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# CUDA path
#export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
#export LD_LIBRARY_PATH=/usr/lib64/cuda${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
#

# Deno 
. "/home/rastler/.deno/env"
# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/rastler/.zsh/completions:"* ]]; then export FPATH="/home/rastler/.zsh/completions:$FPATH"; fi

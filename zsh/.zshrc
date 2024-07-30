# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.local/bin:/usr/local/bin:$:/usr/local/go/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="eastwood"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' frequency 3	# how often to auto-update (in days)
zstyle ':omz:update' mode auto      	# update automatically without asking

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Antigen 
source ~/antigen.zsh
# Load the oh-my-zsh's library.
antigen use oh-my-zsh
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
# Tell Antigen that you're done.
antigen apply


# Plug-ins
plugins=(git docker docker-compose pip rust) 

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vi'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Aliases
alias zshconfig="nvim ~/.zshrc"
alias flushdns="sudo systemd-resolve --flush-caches"
alias compose="podman-compose"
alias show_use_ports="sudo lsof -i -P -n | grep LISTEN"
alias wezterm='flatpak run org.wezfurlong.wezterm'
### DNF
alias dnf.upgrade="sudo dnf upgrade --refresh --assumeyes && flatpak update --assumeyes && flatpak remove --unused"
alias dnf.install="sudo dnf install"
alias dnf.remove="sudo dnf remove"
alias dnf.search="sudo dnf --cacheonly search"
alias dnf.provides="sudo dnf --cacheonly provides"
alias dnf.list_installed="sudo dnf --cacheonly list installed"
alias dnf.repolist="sudo dnf --cacheonly repolist"
alias dnf.list_package_files="sudo dnf --cacheonly repoquery --list"
alias dnf.history_list="sudo dnf --cacheonly history list --reverse"
alias dnf.history_info="sudo dnf --cacheonly history info"
alias dnf.requires="sudo dnf --cacheonly repoquery --requires --resolve"
alias dnf.info="sudo dnf --cacheonly info"
alias dnf.whatrequires="sudo dnf repoquery --installed --whatrequires"
alias dnf.repo_disable="sudo dnf config-manager --set-disabled"

# Force set Wayland variable of Firefox
if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
    export MOZ_ENABLE_WAYLAND=1
fi

# Environment variables
export UID=$(id -u) 
export GID=$(id -g)
export XDG_CONFIG_HOME=$HOME/.config


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Golang
export GOPATH=$HOME/dev/go

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


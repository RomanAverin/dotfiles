# ============================================================================
# Login shell environment
# ============================================================================
# Keep PATH ready before interactive shell initialization so programs started
# from the login shell (notably the tmux server) inherit the complete toolchain.
typeset -U path PATH

_path_prepend() {
  [[ -d "$1" ]] && path=("$1" $path)
}

_path_append() {
  [[ -d "$1" ]] && path+=("$1")
}

# User and system executables.
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  /usr/bin
  /usr/local/bin
  $path
)

# Add fnm itself early. On this machine it may also be installed through Cargo.
FNM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
_path_prepend "$FNM_PATH"

# Golang
export GOPATH="$HOME/Develop/go"
_path_prepend "$GOPATH/bin"

# Rust
_path_prepend "$HOME/.cargo/bin"

# fnm must be initialized in the login shell so tmux inherits the selected
# Node.js environment. The directory-change hook is installed in .zshrc.
if (( $+commands[fnm] )); then
  eval "$(fnm env --shell zsh)"
fi

# Deno
[[ -r "$HOME/.deno/env" ]] && source "$HOME/.deno/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -x "$BUN_INSTALL/bin/bun" ]] && _path_prepend "$BUN_INSTALL/bin"

# LM Studio CLI is intentionally appended, matching its installer defaults.
_path_append "$HOME/lmstudio/bin"

# User-installed applications.
_path_prepend "$HOME/.opencode/bin"
_path_prepend "${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims"
_path_prepend /opt/nvim-linux-x86_64/bin

unset -f _path_prepend _path_append
unset FNM_PATH

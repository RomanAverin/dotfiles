# ============================================================================
# Shell environment
# ============================================================================
# Keep the deterministic environment available to every zsh invocation,
# regardless of whether the shell is interactive or a login shell.
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

# Add fnm itself early. The selected Node.js version is initialized later by
# .zprofile for login shells or .zshrc for interactive non-login shells.
FNM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
_path_prepend "$FNM_PATH"

# Golang
export GOPATH="$HOME/Develop/go"
path=("$GOPATH/bin" $path)

# Rust
_path_prepend "$HOME/.cargo/bin"

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

# Keep fnm's multishell and the physical installation directory synchronized.
# The multishell must win command lookup for `fnm use`; npm doctor additionally
# requires the physical `installation/bin` directory to be present in PATH.
_fnm_sync_node_path() {
  local installation_bin

  path=(${path:#*/fnm_multishells/*/bin})
  path=(${path:#*/fnm/node-versions/*/installation/bin})

  if [[ -n ${FNM_MULTISHELL_PATH:-} && -d "$FNM_MULTISHELL_PATH/bin" ]]; then
    installation_bin="${FNM_MULTISHELL_PATH:A}/bin"
    [[ -d "$installation_bin" ]] && path=(
      "$FNM_MULTISHELL_PATH/bin"
      "$installation_bin"
      $path
    )
  fi
}

_fnm_sync_node_path

unset -f _path_prepend _path_append
unset FNM_PATH

# ============================================================================
# Login shell environment
# ============================================================================
# fnm must be initialized in the login shell so tmux inherits the selected
# Node.js environment. Static PATH setup is loaded earlier from .zshenv.
if (( $+commands[fnm] )); then
  eval "$(fnm env --shell zsh)"
  (( $+functions[_fnm_sync_node_path] )) && _fnm_sync_node_path
fi

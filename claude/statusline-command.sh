#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')

# Get username and hostname
username=$(whoami)
hostname=$(hostname -s)

# Get directory (shortened to basename if in home)
if [[ "$current_dir" == "$HOME"* ]]; then
  dir_display="~${current_dir#$HOME}"
else
  dir_display="$current_dir"
fi

# Git information (skip optional locks for safety)
git_branch=""
git_status_info=""
git_state_info=""
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
  # Get branch name
  git_branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
  if [ -z "$git_branch" ]; then
    git_branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
  fi

  # Check for git state (merge, rebase, etc.)
  git_dir=$(git -C "$current_dir" rev-parse --git-dir 2>/dev/null)
  if [ -f "$git_dir/MERGE_HEAD" ]; then
    git_state_info="(MERGING)"
  elif [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
    git_state_info="(REBASING)"
  elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
    git_state_info="(CHERRY-PICKING)"
  elif [ -f "$git_dir/REVERT_HEAD" ]; then
    git_state_info="(REVERTING)"
  elif [ -f "$git_dir/BISECT_LOG" ]; then
    git_state_info="(BISECTING)"
  fi

  # Get git status (disable optional locks)
  if git_status=$(git -C "$current_dir" --no-optional-locks status --porcelain 2>/dev/null); then
    modified=$(echo "$git_status" | grep -c "^ M\|^M " 2>/dev/null || echo 0)
    untracked=$(echo "$git_status" | grep -c "^??" 2>/dev/null || echo 0)
    staged=$(echo "$git_status" | grep -c "^A \|^M \|^D " 2>/dev/null || echo 0)
    renamed=$(echo "$git_status" | grep -c "^R " 2>/dev/null || echo 0)
    deleted=$(echo "$git_status" | grep -c "^.D\| D" 2>/dev/null || echo 0)

    status_parts=""
    [ "$modified" -gt 0 ] && status_parts+="*"
    [ "$untracked" -gt 0 ] && status_parts+="?"
    [ "$staged" -gt 0 ] && status_parts+="+"

    if [ -n "$status_parts" ]; then
      git_status_info="$status_parts"
    fi
  fi

  # Check for stashed changes
  if git -C "$current_dir" --no-optional-locks rev-parse --verify refs/stash >/dev/null 2>&1; then
    git_status_info+="≡"
  fi

  # Check ahead/behind
  upstream=$(git -C "$current_dir" rev-parse --abbrev-ref @{upstream} 2>/dev/null)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$current_dir" rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$current_dir" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    if [ "$ahead" -gt 0 ]; then
      git_status_info+="⇡$ahead"
    fi
    if [ "$behind" -gt 0 ]; then
      git_status_info+="⇣$behind"
    fi
  fi
fi

# Python virtualenv
python_env=""
if [ -n "$VIRTUAL_ENV" ]; then
  python_env=$(basename "$VIRTUAL_ENV")
elif [ -n "$CONDA_DEFAULT_ENV" ]; then
  python_env="$CONDA_DEFAULT_ENV"
fi

# Token usage and context information
token_info=""
context_used=$(echo "$input" | jq -r '.usage.context_used // empty' 2>/dev/null)
context_limit=$(echo "$input" | jq -r '.usage.context_limit // empty' 2>/dev/null)
input_tokens=$(echo "$input" | jq -r '.usage.input_tokens // empty' 2>/dev/null)
output_tokens=$(echo "$input" | jq -r '.usage.output_tokens // empty' 2>/dev/null)

if [ -n "$context_used" ] && [ -n "$context_limit" ]; then
  # Calculate percentage
  context_percent=$(awk "BEGIN {printf \"%.0f\", ($context_used/$context_limit)*100}")
  token_info="${context_used}/${context_limit} (${context_percent}%)"
elif [ -n "$input_tokens" ] || [ -n "$output_tokens" ]; then
  # Fallback to input/output tokens if context info not available
  total_tokens=$((input_tokens + output_tokens))
  if [ "$total_tokens" -gt 0 ]; then
    token_info="${total_tokens}tk"
  fi
fi

# Cost information
cost_info=""
session_cost=$(echo "$input" | jq -r '.cost.session // .costs.session // empty' 2>/dev/null)
total_cost=$(echo "$input" | jq -r '.cost.total // .costs.total // empty' 2>/dev/null)

if [ -n "$session_cost" ]; then
  cost_info="\$${session_cost}"
  if [ -n "$total_cost" ]; then
    cost_info="${cost_info} (Σ\$${total_cost})"
  fi
elif [ -n "$total_cost" ]; then
  cost_info="\$${total_cost}"
fi

# Build status line with colors (using printf for ANSI codes)
# Colors match Starship config: blue for directory, bright-black (90) for git branch,
# cyan for git status, yellow for duration, bright-black for python
output=""

# Username@hostname (optional, can be enabled)
# output+="$(printf '\033[90m%s@%s\033[0m ' "$username" "$hostname")"

# Directory in blue
output+="$(printf '\033[34m%s\033[0m' "$dir_display")"

# Git branch in bright-black (90 = dim/gray)
if [ -n "$git_branch" ]; then
  output+=" $(printf '\033[90m%s\033[0m' "$git_branch")"
fi

# Git state in bright-black
if [ -n "$git_state_info" ]; then
  output+=" $(printf '\033[90m%s\033[0m' "$git_state_info")"
fi

# Git status in cyan
if [ -n "$git_status_info" ]; then
  output+=" $(printf '\033[36m%s\033[0m' "$git_status_info")"
fi

# Python virtualenv in bright-black
if [ -n "$python_env" ]; then
  output+=" $(printf '\033[90m%s\033[0m' "$python_env")"
fi

# Token usage in yellow
if [ -n "$token_info" ]; then
  output+=" $(printf '\033[33m%s\033[0m' "$token_info")"
fi

# Cost information in green
if [ -n "$cost_info" ]; then
  output+=" $(printf '\033[32m%s\033[0m' "$cost_info")"
fi

echo "$output"

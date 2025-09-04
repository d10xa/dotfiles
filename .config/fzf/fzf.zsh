# ~/.config/fzf/fzf.zsh

# Setup fzf
# ---------
system_type=$(uname -s)

# Determine sed extended regex flag based on system
if [[ "$system_type" == "Darwin" ]]; then
    SED_EXTENDED_FLAG="-E"
else
    SED_EXTENDED_FLAG="-r"
fi

if [ "$system_type" = "Darwin" ]; then
  # macOS with homebrew
  if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
  elif command -v brew >/dev/null 2>&1; then
    # Try to source from homebrew installation
    BREW_PREFIX=$(brew --prefix 2>/dev/null)
    if [[ -n "$BREW_PREFIX" && -f "$BREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
      source "$BREW_PREFIX/opt/fzf/shell/completion.zsh"
    fi
    if [[ -n "$BREW_PREFIX" && -f "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
      source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
    fi
  fi
elif [ "$system_type" = "Linux" ]; then
  # Ubuntu/Debian
  if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  fi
  if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
    source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# Environment variables
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --margin=1
  --padding=1
  --info=inline
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --color=fg:#f8f8f2
  --color=bg:#282a36
  --color=hl:#bd93f9
  --color=fg+:#f8f8f2
  --color=bg+:#44475a
  --color=hl+:#bd93f9
  --color=info:#ffb86c
  --color=prompt:#50fa7b
  --color=pointer:#ff79c6
  --color=marker:#ff79c6
  --color=spinner:#ffb86c
  --color=header:#6272a4
"

# Use ag/rg if available
if command -v ag >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
fi

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="find . -type d -not -path '*/\.*' 2>/dev/null | head -200"

# Custom functions
# ----------------

# fh - search in command history
fh() {
  local cmd
  if command -v fc >/dev/null 2>&1; then
    cmd=$(fc -l 1 2>/dev/null | fzf +s --tac | sed $SED_EXTENDED_FLAG 's/ *[0-9]*\*? *//' | sed 's/\\/\\\\/g')
  else
    cmd=$(history | fzf +s --tac | sed $SED_EXTENDED_FLAG 's/ *[0-9]*\*? *//' | sed 's/\\/\\\\/g')
  fi

  if [[ -n "$cmd" ]]; then
    print -z "$cmd"
  fi
}

# fd - cd to selected directory
fd() {
  local dir
  local search_path="${1:-.}"

  # Validate search path exists and is a directory
  if [[ ! -d "$search_path" ]]; then
    echo "Error: '$search_path' is not a valid directory" >&2
    return 1
  fi

  dir=$(find "$search_path" -path '*/\.*' -prune \
                  -o -type d -print 2>/dev/null | fzf +m)

  if [[ -n "$dir" && -d "$dir" ]]; then
    cd "$dir"
  elif [[ -n "$dir" ]]; then
    echo "Error: Selected path is not a directory" >&2
    return 1
  fi
}

# fda - including hidden directories
fda() {
  local dir
  local search_path="${1:-.}"

  # Validate search path exists and is a directory
  if [[ ! -d "$search_path" ]]; then
    echo "Error: '$search_path' is not a valid directory" >&2
    return 1
  fi

  dir=$(find "$search_path" -type d 2>/dev/null | fzf +m)

  if [[ -n "$dir" && -d "$dir" ]]; then
    cd "$dir"
  elif [[ -n "$dir" ]]; then
    echo "Error: Selected path is not a directory" >&2
    return 1
  fi
}

# fe - open file in editor
fe() {
  local IFS=$'\n'  # Local IFS to avoid global modification
  local files
  files=($(fzf-tmux --query="${1:-}" --multi --select-1 --exit-0))

  if [[ ${#files[@]} -gt 0 ]]; then
    # Validate all selected files exist
    local file
    for file in "${files[@]}"; do
      if [[ ! -f "$file" ]]; then
        echo "Warning: File '$file' does not exist" >&2
      fi
    done
    "${EDITOR:-vim}" "${files[@]}"
  fi
}

# fkill - kill process
fkill() {
  local signal="${1:-9}"
  local pids

  # Validate signal is numeric
  if [[ ! "$signal" =~ ^[0-9]+$ ]]; then
    echo "Error: Signal must be numeric" >&2
    return 1
  fi

  # Get process selection
  local ps_output
  ps_output=$(ps -ef | sed 1d | fzf -m --header="Select processes to kill (TAB for multi-select)")

  if [[ -z "$ps_output" ]]; then
    return 0
  fi

  # Extract PIDs and validate them
  local IFS=$'\n'
  local lines=($ps_output)
  local valid_pids=()

  for line in "${lines[@]}"; do
    local pid=$(echo "$line" | awk '{print $2}')
    if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$pid" -ne $$ ]]; then  # Don't allow killing current shell
      valid_pids+=("$pid")
    else
      echo "Warning: Skipping invalid or dangerous PID: $pid" >&2
    fi
  done

  if [[ ${#valid_pids[@]} -gt 0 ]]; then
    printf 'About to kill %d process(es) with signal %s:\n' "${#valid_pids[@]}" "$signal"
    printf '  PID: %s\n' "${valid_pids[@]}"
    printf 'Continue? (y/N): '
    read -r confirmation
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
      printf '%s\n' "${valid_pids[@]}" | xargs kill "-$signal"
    else
      echo "Cancelled."
    fi
  else
    echo "No valid PIDs selected" >&2
    return 1
  fi
}

# Git functions with fzf
# ----------------------

# fbr - checkout git branch
fbr() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local branches branch branch_name
  branches=$(git --no-pager branch -vv 2>/dev/null) || {
    echo "Error: Failed to get git branches" >&2
    return 1
  }

  branch=$(echo "$branches" | fzf +m)
  if [[ -n "$branch" ]]; then
    branch_name=$(echo "$branch" | awk '{print $1}' | sed 's/^[* ]*//')
    if [[ -n "$branch_name" ]]; then
      git checkout "$branch_name"
    fi
  fi
}

# fco - checkout git commit
fco() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  local commits commit commit_hash
  commits=$(git log --pretty=oneline --abbrev-commit --reverse 2>/dev/null) || {
    echo "Error: Failed to get git log" >&2
    return 1
  }

  commit=$(echo "$commits" | fzf --tac +s +m -e)
  if [[ -n "$commit" ]]; then
    commit_hash=$(echo "$commit" | awk '{print $1}')
    if [[ -n "$commit_hash" && "$commit_hash" =~ ^[a-f0-9]+$ ]]; then
      git checkout "$commit_hash"
    else
      echo "Error: Invalid commit hash" >&2
      return 1
    fi
  fi
}

# fshow - git commit browser
fshow() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    return 1
  fi

  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" 2>/dev/null |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7,\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" || {
    echo "Error: Failed to get git log" >&2
    return 1
  }
}

# Docker functions with fzf
# ---------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  # Helper function to validate container ID
  _validate_container_id() {
    local cid="$1"
    # Docker container IDs are hexadecimal and can be 12 or 64 characters
    [[ "$cid" =~ ^[a-f0-9]{12}([a-f0-9]{52})?$ ]]
  }

  # Select a docker container to start and attach to
  fda_docker() {
    local cid
    if ! docker ps -a >/dev/null 2>&1; then
      echo "Error: Cannot access Docker daemon" >&2
      return 1
    fi

    cid=$(docker ps -a 2>/dev/null | sed 1d | fzf -1 -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" ]]; then
      if _validate_container_id "$cid"; then
        docker start "$cid" && docker attach "$cid"
      else
        echo "Error: Invalid container ID format" >&2
        return 1
      fi
    fi
  }

  # Select a running docker container to stop
  fds_docker() {
    local cid
    if ! docker ps >/dev/null 2>&1; then
      echo "Error: Cannot access Docker daemon" >&2
      return 1
    fi

    cid=$(docker ps 2>/dev/null | sed 1d | fzf -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" ]]; then
      if _validate_container_id "$cid"; then
        docker stop "$cid"
      else
        echo "Error: Invalid container ID format" >&2
        return 1
      fi
    fi
  }

  # Select a docker container to remove
  fdrm_docker() {
    local cid
    if ! docker ps -a >/dev/null 2>&1; then
      echo "Error: Cannot access Docker daemon" >&2
      return 1
    fi

    cid=$(docker ps -a 2>/dev/null | sed 1d | fzf -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" ]]; then
      if _validate_container_id "$cid"; then
        printf 'Remove container %s? (y/N): ' "$cid"
        read -r confirmation
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
          docker rm "$cid"
        else
          echo "Cancelled."
        fi
      else
        echo "Error: Invalid container ID format" >&2
        return 1
      fi
    fi
  }
fi

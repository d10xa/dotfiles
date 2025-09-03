# ~/.config/fzf/fzf.zsh

# Setup fzf
# ---------
system_type=$(uname -s)
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
export FZF_ALT_C_COMMAND="find . -type d -not -path '*/\.*' | head -200"

# Custom functions
# ----------------

# fh - search in command history (FIXED: removed dangerous eval)
fh() {
  local cmd
  cmd=$(fc -l 1 | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
  if [[ -n "$cmd" ]]; then
    print -z "$cmd"  # Put command in ZSH buffer instead of executing directly
  fi
}

# fd - cd to selected directory (FIXED: better path handling)
fd() {
  local dir
  local search_path="${1:-.}"
  dir=$(find "$search_path" -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  [[ -n "$dir" ]] && cd "$dir"
}

# fda - including hidden directories (FIXED: better path handling)
fda() {
  local dir
  local search_path="${1:-.}"
  dir=$(find "$search_path" -type d 2> /dev/null | fzf +m) &&
  [[ -n "$dir" ]] && cd "$dir"
}

# fe - open file in editor (FIXED: better file handling)
fe() {
  local files
  IFS=$'\n' files=($(fzf-tmux --query="${1:-}" --multi --select-1 --exit-0))
  [[ ${#files[@]} -gt 0 ]] && "${EDITOR:-vim}" "${files[@]}"
}

# fkill - kill process (FIXED: safer PID handling)
fkill() {
  local pid signal
  signal="${1:-9}"

  # Validate signal is numeric
  if [[ ! "$signal" =~ ^[0-9]+$ ]]; then
    echo "Error: Signal must be numeric" >&2
    return 1
  fi

  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [[ -n "$pid" ]]; then
    # Validate PID is numeric
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
      printf '%s\n' "$pid" | xargs kill "-$signal"
    else
      echo "Error: Invalid PID selected" >&2
      return 1
    fi
  fi
}

# Git functions with fzf (FIXED: better error handling)
# ----------------------

# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git --no-pager branch -vv 2>/dev/null) || {
    echo "Error: Not in a git repository" >&2
    return 1
  }
  branch=$(echo "$branches" | fzf +m) &&
  [[ -n "$branch" ]] &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fco - checkout git commit
fco() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse 2>/dev/null) || {
    echo "Error: Not in a git repository" >&2
    return 1
  }
  commit=$(echo "$commits" | fzf --tac +s +m -e) &&
  [[ -n "$commit" ]] &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

# fshow - git commit browser (FIXED: safer execution)
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" 2>/dev/null |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" || {
    echo "Error: Not in a git repository or no commits found" >&2
    return 1
  }
}

# Docker functions with fzf (FIXED: better validation)
# ---------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  # Select a docker container to start and attach to
  da() {
    local cid
    cid=$(docker ps -a 2>/dev/null | sed 1d | fzf -1 -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" && "$cid" =~ ^[a-f0-9]+$ ]]; then
      docker start "$cid" && docker attach "$cid"
    elif [[ -n "$cid" ]]; then
      echo "Error: Invalid container ID" >&2
      return 1
    fi
  }

  # Select a running docker container to stop
  ds() {
    local cid
    cid=$(docker ps 2>/dev/null | sed 1d | fzf -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" && "$cid" =~ ^[a-f0-9]+$ ]]; then
      docker stop "$cid"
    elif [[ -n "$cid" ]]; then
      echo "Error: Invalid container ID" >&2
      return 1
    fi
  }

  # Select a docker container to remove
  drm() {
    local cid
    cid=$(docker ps -a 2>/dev/null | sed 1d | fzf -q "${1:-}" | awk '{print $1}')

    if [[ -n "$cid" && "$cid" =~ ^[a-f0-9]+$ ]]; then
      docker rm "$cid"
    elif [[ -n "$cid" ]]; then
      echo "Error: Invalid container ID" >&2
      return 1
    fi
  }
fi

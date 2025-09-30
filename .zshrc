# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

export ZSH="$HOME/.oh-my-zsh"
# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"
HIST_STAMPS="yyyy-mm-dd"
# https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins=(
  git
  macos
  docker
  docker-compose
  vi-mode
  history-substring-search
  fasd
  last-working-dir
)
HISTSIZE=1000000
SAVEHIST=1000000
# https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
setopt EXTENDED_HISTORY # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_SPACE # Don't record an entry starting with a space.
setopt HIST_FIND_NO_DUPS # Do not display a line previously found.
setopt HIST_SAVE_NO_DUPS # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS # Remove superfluous blanks before recording entry.
source $ZSH/oh-my-zsh.sh
system_type=$(uname -s)
if [ "$system_type" = "Darwin" ]; then
  # https://iterm2.com/documentation-shell-integration.html
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [[ -f ~/.config/fzf/fzf.zsh ]]; then
  source ~/.config/fzf/fzf.zsh
fi

if [ -f "$HOME/.zshrc_local" ]; then
  source "$HOME/.zshrc_local"
fi

# Directory jumping tool
# Migrating from fasd to zoxide - both will work during transition
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  # Compatibility aliases for muscle memory
  alias j='z'    # jump to directory
  alias ji='zi'  # interactive selection with fzf
elif command -v fasd &> /dev/null; then
  # Fallback to fasd if zoxide not installed yet
  fasd_cache="$HOME/.fasd-init-zsh"
  if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
    fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >| "$fasd_cache"
  fi
  source "$fasd_cache"
  unset fasd_cache
fi
if ! command -v terraform &> /dev/null
then
else
  alias tf=terraform
fi

export PATH="/usr/local/opt/curl/bin:$PATH"

#alias cfv="PYENV_VERSION=2.7.18 pyenv exec cfv"

# kubernetes
if [ "$(command -v kubectl)" ]; then
  alias k=kubectl
  complete -F __start_kubectl k
  source <(kubectl completion zsh)
fi

# npm
export PATH="$HOME/.npm-packages/bin/:$PATH"

# python
export PATH="${PATH}:$(python3 -c 'import site; print(site.USER_BASE)')/bin"

export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
eval "$(cs install --env)"

# File listing tools - support both exa and eza during transition
if command -v eza &> /dev/null; then
  # Modern file listing with eza
  alias ls='eza --color=auto --group-directories-first'
  alias ll='eza -l --color=auto --group-directories-first'
  alias la='eza -la --color=auto --group-directories-first'
  alias lt='eza --tree --color=auto'
  alias lT='eza --tree --color=auto --level=2'
  alias lg='eza -l --color=auto --group-directories-first --git'
  alias l='eza --color=auto --group-directories-first'
elif command -v exa &> /dev/null; then
  # Fallback to exa if eza not installed yet
  alias ls='exa --color=auto --group-directories-first'
  alias ll='exa -l --color=auto --group-directories-first'
  alias la='exa -la --color=auto --group-directories-first'
  alias lt='exa --tree --color=auto'
  alias lg='exa -l --color=auto --group-directories-first --git'
  alias l='exa --color=auto --group-directories-first'
fi

# qr to text (Shift + Control + Command + 4)
alias qrpaste='zbarimg -q --raw <(pngpaste -)'


# Created by `pipx` on 2024-12-05 07:36:59
export PATH="$PATH:/Users/d10xa/.local/bin"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

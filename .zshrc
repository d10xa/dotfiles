# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# https://github.com/romkatv/powerlevel10k#how-do-i-initialize-direnv-when-using-instant-prompt
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

# =============================================================================
# Zinit
# =============================================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not present
if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}Installing Zinit...%f"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# Powerlevel10k (must load synchronously for instant prompt)
# =============================================================================

zinit ice depth=1
zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# History settings
# =============================================================================

HISTSIZE=1000000
SAVEHIST=1000000
HIST_STAMPS="yyyy-mm-dd"

setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY          # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.

# =============================================================================
# Turbo mode plugins (wait"0" - load immediately after prompt)
# =============================================================================

# Vi-mode
zinit ice wait"0" lucid
zinit light jeffreytse/zsh-vi-mode

# History substring search
zinit ice wait"0" lucid atload"bindkey '^[[A' history-substring-search-up; bindkey '^[[B' history-substring-search-down; bindkey -M vicmd 'k' history-substring-search-up; bindkey -M vicmd 'j' history-substring-search-down"
zinit light zsh-users/zsh-history-substring-search

# Syntax highlighting
zinit ice wait"0" lucid atinit"zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

# Autosuggestions
zinit ice wait"0" lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# =============================================================================
# Oh My Zsh snippets (wait"1" - load after initial plugins)
# =============================================================================

zinit ice wait"1" lucid
zinit snippet OMZL::git.zsh

zinit ice wait"1" lucid
zinit snippet OMZP::git

zinit ice wait"1" lucid
zinit snippet OMZP::docker

zinit ice wait"1" lucid
zinit snippet OMZP::docker-compose

# Loaded synchronously: triggers cd on load, which causes chpwd reentrant
# call to @zinit-scheduler if loaded in turbo mode
zinit snippet OMZP::last-working-dir

# =============================================================================
# Lazy loading tools (wait"2")
# =============================================================================

# Zoxide (directory jumper)
zinit ice wait"2" lucid atload'if (( $+commands[zoxide] )); then eval "$(zoxide init zsh)"; alias j="z"; alias ji="zi"; fi'
zinit light zdharma-continuum/null

# Kubectl completions
zinit ice wait"2" lucid atload'if (( $+commands[kubectl] )); then source <(kubectl completion zsh); alias k=kubectl; fi'
zinit light zdharma-continuum/null

# =============================================================================
# Lazy loading functions (jenv, coursier)
# =============================================================================

export PATH="$HOME/.jenv/bin:$PATH"

# jenv lazy loading - initializes on first java/javac/jenv call
_jenv_lazy_init() {
  unfunction java javac jenv 2>/dev/null
  eval "$(jenv init -)"
}

if (( $+commands[jenv] )); then
  java()  { _jenv_lazy_init && command java "$@" }
  javac() { _jenv_lazy_init && command javac "$@" }
  jenv()  { _jenv_lazy_init && command jenv "$@" }
fi

# Coursier lazy loading - initializes on first cs/scala/scala-cli call
_cs_lazy_init() {
  unfunction cs scala scala-cli 2>/dev/null
  eval "$(cs install --env)"
}

if (( $+commands[cs] )); then
  cs()        { _cs_lazy_init && command cs "$@" }
  scala()     { _cs_lazy_init && command scala "$@" }
  scala-cli() { _cs_lazy_init && command scala-cli "$@" }
fi

# =============================================================================
# macOS functions (replacement for OMZP::macos)
# =============================================================================

if [[ "$OSTYPE" == darwin* ]]; then
  # Open current directory in Finder
  ofd() { open "$PWD" }

  # cd to frontmost Finder window directory
  cdf() {
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')" || return
  }

  # Return path of frontmost Finder window
  pfd() {
    osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)'
  }

  # Return paths of selected Finder items
  pfs() {
    osascript -e 'tell app "Finder" to POSIX path of (selection as alias)'
  }

  # Quick Look a file
  quick-look() { qlmanage -p "$@" &>/dev/null }

  # Open man page in Preview
  man-preview() { man -t "$@" | open -f -a Preview }
fi

# =============================================================================
# Aliases
# =============================================================================

# Terraform
(( $+commands[terraform] )) && alias tf=terraform

# File listing tools - support both exa and eza during transition
if (( $+commands[eza] )); then
  alias ls='eza --color=auto --group-directories-first'
  alias ll='eza -l --color=auto --group-directories-first'
  alias la='eza -la --color=auto --group-directories-first'
  alias lt='eza --tree --color=auto'
  alias lT='eza --tree --color=auto --level=2'
  alias lg='eza -l --color=auto --group-directories-first --git'
  alias l='eza --color=auto --group-directories-first'
elif (( $+commands[exa] )); then
  alias ls='exa --color=auto --group-directories-first'
  alias ll='exa -l --color=auto --group-directories-first'
  alias la='exa -la --color=auto --group-directories-first'
  alias lt='exa --tree --color=auto'
  alias lg='exa -l --color=auto --group-directories-first --git'
  alias l='exa --color=auto --group-directories-first'
fi

# QR to text (Shift + Control + Command + 4)
alias qrpaste='zbarimg -q --raw <(pngpaste -)'

# =============================================================================
# PATH
# =============================================================================

export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="$HOME/.npm-packages/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# =============================================================================
# External configs
# =============================================================================

# FZF
[[ -f ~/.config/fzf/fzf.zsh ]] && source ~/.config/fzf/fzf.zsh

# iTerm2 shell integration (macOS only)
if [[ "$OSTYPE" == darwin* && -e "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Local configuration (last, to override anything)
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local

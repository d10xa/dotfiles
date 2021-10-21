export ZSH="$HOME/.oh-my-zsh"
# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"
HIST_STAMPS="yyyy-mm-dd"
# https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins=(
  git
  osx
  docker
  docker-compose
  vi-mode
  hisory-substring-search
  fasd
  last-working-dir
  zsh-aliases-exa
)
source $ZSH/oh-my-zsh.sh
# https://iterm2.com/documentation-shell-integration.html
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
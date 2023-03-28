# https://superuser.com/questions/187639/zsh-not-hitting-profile
emulate sh
. ~/.profile
emulate zsh
eval $(/opt/homebrew/bin/brew shellenv)


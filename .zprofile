# https://superuser.com/questions/187639/zsh-not-hitting-profile
emulate sh
. ~/.profile
emulate zsh
eval $(/opt/homebrew/bin/brew shellenv)



# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"


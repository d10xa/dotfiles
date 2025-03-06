# https://superuser.com/questions/187639/zsh-not-hitting-profile
emulate sh
. ~/.profile
emulate zsh
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi
if [ -f "/usr/local/bin/brew" ]; then
    eval $(/usr/local/bin/brew shellenv)
fi


# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"


export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/share/coursier/bin"

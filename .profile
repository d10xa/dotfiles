export PATH=$PATH:~/bin

system_type=$(uname -s)
if [ "$system_type" = "Darwin" ]; then
  alias google-chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
  export JAVA_HOME="$HOME/Library/Caches/Coursier/jvm/adopt@1.11.0-11/Contents/Home"
  export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi


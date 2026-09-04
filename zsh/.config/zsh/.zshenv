preappend_path "$HOME/.local/bin"
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
source $ZDOTDIR/zsh_vars
source_folder "$XDG_CONFIG_HOME/aliases"

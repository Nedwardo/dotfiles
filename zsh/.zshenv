preappend_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
	        *)
			export PATH="$1:$PATH"
    esac
}

preappend_path "$HOME/.local/bin"

export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

source $ZDOTDIR/zsh_vars

preappend_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
	        *)
			export PATH="$1:$PATH"
    esac
}

preappend_path "$HOME/.local/bin"

export ZDOTDIR="$HOME/.config/zsh"

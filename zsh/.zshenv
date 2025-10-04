preappend_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
	        *)
			export PATH="$1:$PATH"
    esac
}

if [ -d "$HOME/.local/bin" ]; then
    preappend_path "$HOME/.local/bin"
fi

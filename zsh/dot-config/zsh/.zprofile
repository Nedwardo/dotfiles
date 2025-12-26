preappend_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
	        *)
			export PATH="$1:$PATH"
    esac
}

source_folder(){
	local folder="${1%/}"
	[[ "$folder" != /* ]] && folder="$HOME/$folder"
	if [ -d $folder ]; then
		files_to_source=($folder/*(N))
		for file_to_source in "${(@o)files_to_source[@]}"; do
			if [[ $file_to_source != *.disabled && -r $file_to_source ]]; then
				{source $file_to_source || print -u2 "⚠️ Failed to init $file_to_source"}
			fi
		done
	else
		print -u2 "⚠️ Failed to source folder $folder, does not exist"
	fi
}

preappend_path "$HOME/.local/bin"
source $ZDOTDIR/zsh_vars
source_folder "$XDG_CONFIG_HOME/aliases"

if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec Hyprland
fi

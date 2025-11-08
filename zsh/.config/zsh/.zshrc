#############
### Zinit ###
#############
init_zinit(){
	ZINIT_HOME="/usr/share/zinit"
	source "${ZINIT_HOME}/zinit.zsh"
}

###############
### Plugins ###
###############
init_plugins(){
	zicompinit; zicdreplay
	zinit ice depth"1" lucid; zinit light Aloxaf/fzf-tab
	zinit ice blockf atpull'zinit creinstall -q .'
	zinit light zsh-users/zsh-completions
	zinit ice depth"1" wait lucid 
	zinit light-mode for \
		zdharma-continuum/fast-syntax-highlighting \
		atload"_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
		joshskidmore/zsh-fzf-history-search
}

###############
### My shit ###
###############
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
init_my_stuff(){
	export MANPATH="$HOME/.local/share/man:$MANPATH"
	source_folder ".aliases"
	source_folder ".rc.d"
}

################################
### Actually initalise shell ###
################################

[[ -z "$ZDOTDIR" ]] && export ZDOTDIR=$HOME
init_zinit || print -u2 "⚠️ zinit init failed"
source "$ZDOTDIR/.zsh_autocomplete_config" || print -u2 "⚠️ autocomplete config failed"
source "$ZDOTDIR/.zshopts" || print -u2 "⚠️ shell options init failed"
init_plugins || print -u2 "⚠️ plugin init failed"
init_my_stuff || print -u2 "⚠️ My stuff init failed"

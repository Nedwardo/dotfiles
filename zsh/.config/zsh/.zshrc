#############
### Zinit ###
#############
init_zinit(){
	ZINIT_HOME="/usr/share/zinit"
	source "${ZINIT_HOME}/zinit.zsh"
}

####################
### ZLE plugins ####
####################
init_zle_plugins(){
	source "$ZDOTDIR/zle_widgets/main"
}

#####################
### zinit Plugins ###
#####################
init_plugins(){
	zinit light-mode lucid depth="1" blockf for \
		atpull'zinit creinstall -q .' zsh-users/zsh-completions
	zicompinit; zicdreplay
#		wait atload'load_widgets_for_plugin zsh-users/zsh-history-substring-search' \
	zinit depth"1" lucid light-mode for \
		Aloxaf/fzf-tab \
		wait zsh-users/zsh-history-substring-search \
		wait"0b" atload"_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
		wait"0b" joshskidmore/zsh-fzf-history-search \
		wait"0c" zdharma-continuum/fast-syntax-highlighting
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
	source_folder "$ZDOTDIR/zsh_hooks"
	source_folder "$XDG_CONFIG_HOME/aliases"
	source_folder "$XDG_CONFIG_HOME/rc.d"
}

################################
### Actually initalise shell ###
################################

source "$ZDOTDIR/zsh_vars" || print -u2 "⚠️ zsh vars init failed"
init_zle_plugins || print -u2 "⚠️ zle plugins init failed"
init_zinit || print -u2 "⚠️ zinit init failed"
source "$ZDOTDIR/zsh_autocomplete_config" || print -u2 "⚠️ autocomplete config failed"
source "$ZDOTDIR/zshopts" || print -u2 "⚠️ shell options init failed"
init_plugins || print -u2 "⚠️ plugin init failed"
init_my_stuff || print -u2 "⚠️ My stuff init failed"

#############
### Zinit ###
#############
init_zinit(){
	ZINIT_HOME="/usr/share/zinit"
	if [ ! -d "$ZINIT_HOME" ]; then
		ZINIT_HOME="/home/user/.local/share/zinit/zinit.git"
	fi
	source "${ZINIT_HOME}/zinit.zsh"
}

##################
### ZLE Custom ###
##################
# For the zsh line editor, see man zshzle(1) for more info
init_zle_plugins(){
	source "$ZDOTDIR/zle_custom/main"
}

#####################
### zinit Plugins ###
#####################
init_plugins(){
	zinit light-mode lucid depth="1" blockf for \
		atpull'zinit creinstall -q .' zsh-users/zsh-completions
	zicompinit; zicdreplay
	zinit depth"1" lucid light-mode for \
		Aloxaf/fzf-tab \
		MichaelAquilina/zsh-you-should-use \
		wait zsh-users/zsh-history-substring-search \
		wait"0b" atload"_zsh_autosuggest_start" zsh-users/zsh-autosuggestions \
		wait"0b" joshskidmore/zsh-fzf-history-search \
		wait"0c" zdharma-continuum/fast-syntax-highlighting
}

###############
### My shit ###
###############
load_rc_and_completions(){
	source_folder "$XDG_CONFIG_HOME/rc.d" || print -u2 "⚠️ Failed to init rc.d scripts"
	source_folder "$XDG_CONFIG_HOME/compdefs" || print -u2 "⚠️ Failed to init zle completions"
}

#################################
### Actually initialise shell ###
#################################
source "$ZDOTDIR/zsh_vars" || print -u2 "⚠️ zsh vars init failed"
init_zle_plugins || print -u2 "⚠️ zle plugins init failed"
init_zinit || print -u2 "⚠️ zinit init failed"
source "$ZDOTDIR/zsh_autocomplete_config" || print -u2 "⚠️ autocomplete config failed"
source "$ZDOTDIR/zshopts" || print -u2 "⚠️ shell options init failed"
init_plugins || print -u2 "⚠️ plugin init failed"
load_rc_and_completions || print -u2 "⚠️ My stuff init failed"

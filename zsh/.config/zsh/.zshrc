#################
### Oh My Zsh ###
#################
# https://github.com/ohmyzsh/ohmyzsh/wiki
init_oh_my_zsh(){
	export ZSH="$HOME/.oh-my-zsh"
	ZSH_THEME="robbyrussell"

	HYPHEN_INSENSITIVE="true"
	ENABLE_CORRECTION="true"
	zstyle ':omz:update' mode reminder  # just remind me to update when it's time
	zstyle ':omz:update' frequency 13

	source $ZSH/oh-my-zsh.sh || return $?
}

##################
### My Plugins ###
##################
my_plugins=(
	zsh-syntax-highlighting
	fzf-tab-git
	zsh-autosuggestions
	zsh-fzf-plugin
)
init_plugins(){
	plugin_dir=/usr/share/zsh/plugins
	for plugin in "${my_plugins[@]}"; do
		plugin_file=($plugin_dir/$plugin/*.plugin.zsh(N[1]))
		if [ -f "${plugin_file}" ]; then
			source "${plugin_file}" || print -u2 "Failed to source ${plugin}, failed during sourcing file: $plugin_file}"
		else
			print -u2 "Failed to find plugin ${plugin}, looking for ${plugin_file}, not found"
		fi
	done
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
init_oh_my_zsh || print -u2 "⚠️ oh my zsh init failed"
source "$ZDOTDIR/.zsh_autocomplete_init" || print -u2 "⚠️ autocomplete init failed"
init_plugins || print -u2 "⚠️ plugin init failed"
source "$ZDOTDIR/.zsh_autocomplete_config" || print -u2 "⚠️ autocomplete config failed"
source "$ZDOTDIR/.zshopts" || print -u2 "⚠️ shell options init failed"
init_my_stuff || print -u2 "⚠️ My stuff init failed"

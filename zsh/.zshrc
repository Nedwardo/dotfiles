# Path to your Oh My Zsh installation.
# https://github.com/ohmyzsh/ohmyzsh/wiki
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
HYPHEN_INSENSITIVE="true"

###########################
### Auto Update Setting ###
###########################
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13

# ZSH_CUSTOM=/path/to/new-custom-folder


###############
### Plugins ###
###############
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
	git
	zsh-autosuggestions
	fzf-tab
)

source $ZSH/oh-my-zsh.sh

if [ -d $HOME/.aliases ]; then
	for alias_file in $HOME/.aliases/*; do
		[ -r "$alias_file" ] && source "$alias_file"
	done
fi

eval $(thefuck --alias)

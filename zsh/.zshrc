# https://github.com/ohmyzsh/ohmyzsh/wiki
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

###################
### ZSH options ###
###################
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"

###########################
### Auto Update Setting ###
###########################
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13

###############
### Plugins ###
###############
plugins=(
	git
	zsh-autosuggestions
	fzf-tab
)

source $ZSH/oh-my-zsh.sh

if [ -d $HOME/.aliases ]; then
	for alias_file in $HOME/.aliases/*; do
		[ -r $alias_file ] && source $alias_file
	done
fi

if [ -d $HOME/.rc.d ]; then
	for rc_file in $HOME/.rc.d/*; do
		[ -r $rc_file ] && source $rc_file
	done
fi

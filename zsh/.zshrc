#################
### Oh My Zsh ###
#################
# https://github.com/ohmyzsh/ohmyzsh/wiki
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

###################
### OMZ Plugins ###
###################
plugins=(
	git
	zsh-autosuggestions
	fzf-tab
)

source $ZSH/oh-my-zsh.sh

###################
### ZSH options ###
###################
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
setopt globdots
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
zstyle ':omz:update' frequency 13
zstyle ':completion:*' special-dirs special-dirs false # Excludes '.' and '..' from autocompletion

###############
### My shit ###
###############
export MANPATH="$HOME/.local/share/man:$MANPATH"

if [ -d $HOME/.aliases ]; then
	alias_files=($HOME/.aliases/*(N))
	for alias_file in "${(@o)alias_files[@]}"; do
		[ -r $alias_file ] && source $alias_file 
	done
fi

if [ -d $HOME/.rc.d ]; then
	rc_files=($HOME/.rc.d/*)
	for rc_file in "${(@o)rc_files[@]}"; do
		[ -r $rc_file ] && source $rc_file
	done
fi



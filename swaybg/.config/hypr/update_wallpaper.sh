#!/bin/bash
shopt -s nullglob
CONFIG_FILE="$HOME/.config/swaybg.json"
declare -gA CONFIG

function config(){
	echo "$CONFIG_FILE"
}

function load_config(){
	while IFS="=" read -r key value; do
		CONFIG[$key]="$value"
	done < <(jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' "$CONFIG_FILE")
}

function get_active_wallpaper(){
	readlink "$CONFIG[wallpaper_dir]"/active_wallpaper
}

function select_random_wallpaper(){
	if [ "$#" = 0 ]; then
		wallpaper_dir="$CONFIG[wallpaper_dir]"
	else
		wallpaper_dir=$1
	fi

	images=($wallpaper_dir/*.{png,jpg,jpeg,xl,webp})

	random=$$$(date +%s)
	echo ${images[$random % ${#images[@]}]}
}

function run_singleton_sway() {
	if [ "$#" != 1 ]; then
		>&2 echo "Please only select at least one, and only one wallpaper"
	fi
	wallpaper=$1

	if pgrep swaybg &> /dev/null; then
		pkill swaybg &> /dev/null
	fi
	swaybg -i $wallpaper -m $CONFIG[default_mode] &> /dev/null &

	rm $wallpaper_dir/active_wallpaper
	ln -sf $wallpaper $wallpaper_dir/active_wallpaper
}

load_config
run_singleton_sway $(select_random_wallpaper)
echo $wallpaper

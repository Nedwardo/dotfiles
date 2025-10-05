#!/bin/bash
shopt -s nullglob
wallpaper_dir=$HOME/documents/wallpapers

images=($wallpaper_dir/*.{png,jpg,jpeg,xl,webp})

random=$$$(date +%s)
wallpaper=${images[$random % ${#images[@]}]}

if pgrep swaybg; then
	pkill swaybg
fi
swaybg -i $wallpaper -m fit > /dev/null 2&>1 &
echo $wallpaper

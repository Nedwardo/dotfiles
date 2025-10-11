#!/bin/bash
shopt -s nullglob
wallpaper_dir=$HOME/documents/wallpapers

images=($wallpaper_dir/*.{png,jpg,jpeg,xl,webp})

random=$$$(date +%s)
export wallpaper=${images[$random % ${#images[@]}]}

if pgrep swaybg &> /dev/null; then
	pkill swaybg &> /dev/null
fi
swaybg -i $wallpaper -m fit &> /dev/null &

ln -sf $wallpaper $wallpaper_dir/active_wallpaper

echo $wallpaper

#!/bin/bash
shopt -s nullglob
wallpaper_dir=$HOME/documents/wallpapers

images=($wallpaper_dir/*.{png,jpg,jpeg,xl,webp})

random=$$$(date +%s)
chosen_wallpaper=${images[$random % ${#images[@]}]}
swaybg -i $chosen_wallpaper -m fit & 

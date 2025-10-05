#!/bin/bash
hyprpaper_config=$(cat << EOF
# Auto generated from $HOME/.config/hypr/hyprpaper-generate.sh

# See https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper
EOF
)
wallpaper_dir=$HOME/documents/wallpapers
config_file=$HOME/.config/hypr/hyprpaper.conf

shopt -s nullglob
images=($wallpaper_dir/*.{png,jpg,jpeg,xl,webp})

for image in $images; do
	[ -f $img ] && hyprpaper_config="$hyprpaper_config"$'\n'$"preload = $image"
done

random=$$$(date +%s)
chosen_wallpaper=${images[$random % ${#images[@]}]}

hyprpaper_config="$hyprpaper_config"$'\n'"wallpaper = , $chosen_wallpaper"
echo "$hyprpaper_config" > $config_file

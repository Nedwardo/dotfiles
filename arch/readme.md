# Arch Packages
## Export
pacman -Qqe | grep -Fvx "$(pacman -Qqm)" > packages

## Import
xargs pacman -S --needed --noconfirm < packages

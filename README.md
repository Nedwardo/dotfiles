# Dotfiles

## Installation

You can install one of my dotfiles with:
```sh
stow --adopt --target=$HOME <foldername>
```
or, alternativley if you've stow'd .aliases, and added .aliases to your aliases (does not work with firefox)
```sh
update-stow <foldername>
```
Where `<foldername>` is the name of dotfile you'd like to install (alacritty, firefox, mise, python, tmux, wezterm, zim)

Do note for firefox, some more configuration will be required.

```sh
stow --adopt --target=$HOME/.mozilla/firefox/<yourprofile>default-release firefox
```
Fill in `<yourprofile>`. Read about firefox profiles [here](https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data?redirectslug=Profiles&redirectlocale=en-US).

## Tmux first time startup

* Press a + I (capital I, as in Install) to install the tmux plugin manager


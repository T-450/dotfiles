#!/usr/bin/env bash
# swaybg/setup.sh: the two wallpaper links in ~/.local/state/wallpaper, pointed somewhere when they
# are missing or their file is gone (wallpaper-set points them at each pick):
#   current  the desktop (swaybg.service for an image, gslapper.service for a video): the palette's
#            own wallpaper, ~/.config/swaybg/wallpaper.png (render.sh)
#   lock     hyprlock's image: the Blue Dawn eclipse (pkg/wallpaper-cosmic-storm), else the
#            palette's own wallpaper
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
state=$HOME/.local/state/wallpaper
own=$HOME/.config/swaybg/wallpaper.png
dawn=/usr/share/backgrounds/cosmic-storm/blue-dawn-lock.png
mkdir -p "$state"
link() { # link NAME TARGET: point NAME at TARGET unless NAME already reaches a file
	[[ -e $state/$1 ]] && return 0
	ln -sfn -- "$2" "$state/$1"
	echo "link    ~/.local/state/wallpaper/$1 -> ${2/#$HOME/\~}"
}
link current "$own"
if [[ -r $dawn ]]; then link lock "$dawn"; else link lock "$own"; fi

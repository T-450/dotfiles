#!/usr/bin/env bash
# swaybg/setup.sh: swaybg.service shows ~/.local/state/wallpaper/current, a link that wallpaper-set
# points at each pick. When it is missing, or its file is gone, it goes back to the palette's own
# wallpaper, ~/.config/swaybg/wallpaper.png (render.sh).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
current=$HOME/.local/state/wallpaper/current
[[ -e $current ]] && exit 0
mkdir -p "${current%/*}"
ln -sfn -- "$HOME/.config/swaybg/wallpaper.png" "$current"
echo "link    ~/.local/state/wallpaper/current -> ~/.config/swaybg/wallpaper.png"

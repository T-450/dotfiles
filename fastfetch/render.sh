#!/usr/bin/env bash
# fastfetch/render.sh: the logo, .config/fastfetch/logo.png (linked into your home). Godzilla from
# pkg/godzilla-starry-sky-art, cropped to the breath, the head and the claws, in its own colors
# (deep blues that sit in a dark terminal). Lanczos-scaled to exactly the logo's 26x17 cells in
# config.jsonc at Ghostty's 10x22 px cells (font-size 12), so Ghostty draws it 1:1, with rounded
# corners. Run by `theme` after rendering templates; remade only when its inputs changed.
# ART=file reads the illustration from file.
set -euo pipefail
cd "$(dirname "$0")"
src=${ART:-/usr/share/godzilla-starry-sky-art/art.jpg}
out=.config/fastfetch/logo.png
stamp=render.stamp # sha256 of what the logo is made from
if [[ ! -f $src ]]; then
	echo "skip    fastfetch logo: no $src (install.sh --packages)" >&2
	exit 0
fi
inputs=$(cat "$0" "$src" | sha256sum | cut -d' ' -f1)
[[ -f $out && $(cat "$stamp" 2>/dev/null) == "$inputs" ]] && exit 0

W=260 H=374 R=12
# a slightly widened Lanczos keeps the fine linework from aliasing into noise at this size
magick "$src" -crop 1050x1510+150+330 +repage -filter Lanczos -define filter:blur=1.1 -resize "${W}x${H}!" \
	-unsharp 0x0.5+0.4+0.02 \
	\( +clone -alpha extract -fill black -colorize 100 -fill white -draw "roundrectangle 0,0 $((W - 1)),$((H - 1)) $R,$R" \) \
	-alpha off -compose copyopacity -composite -define png:exclude-chunks=date,time "$out"
echo "$inputs" >"$stamp"
echo "render  fastfetch/$out"

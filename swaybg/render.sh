#!/usr/bin/env bash
# swaybg/render.sh: the desktop wallpaper, .config/swaybg/wallpaper.png (linked into your home).
# Dark palettes get Neptune in ASCII (pkg/wallpaper-neptune-ascii) at 3840x2160, the largest
# output; the near-black image suits every dark palette as it is. Light palettes get their plain
# desktop color. Run by `theme` after rendering templates; remade only when its inputs changed.
set -euo pipefail
cd "$(dirname "$0")"
colors=../theme/.config/theme/colors.sh
src=/usr/share/backgrounds/neptune-ascii.png
out=.config/swaybg/wallpaper.png
stamp=render.stamp # sha256 of what the wallpaper is made from
. "$colors"
if [[ $THEME_VARIANT == light ]]; then
	source_id=$THEME_BG_DESKTOP
else
	[[ -r $src ]] || { echo "swaybg/render.sh: $src is missing (./install.sh --only swaybg installs it)" >&2; exit 1; }
	source_id=$(sha256sum <"$src")
fi
inputs=$( (echo "$THEME_VARIANT $source_id" && cat "$0") | sha256sum | cut -d' ' -f1)
[[ -f $out && $(cat "$stamp" 2>/dev/null) == "$inputs" ]] && exit 0
mkdir -p "$(dirname "$out")"
if [[ $THEME_VARIANT == light ]]; then
	magick -size 16x16 "xc:$THEME_BG_DESKTOP" "$out" # swaybg -m fill scales it to the output
else
	# no alpha (the image is opaque): ImageMagick then downscales with Lanczos, which keeps the
	# characters crisp
	magick "$src" -alpha off -resize '3840x2160^' -gravity center -extent 3840x2160 -strip "$out"
fi
echo "$inputs" >"$stamp"
echo "render  swaybg/$out"

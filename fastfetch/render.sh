#!/usr/bin/env bash
# fastfetch/render.sh: the logo, .config/fastfetch/logo.png (linked into your home): the λ of
# logo.svg (rendered by `theme` from logo.svg.tmpl in the palette's colors), rasterized at twice
# the size it is drawn at. Ghostty scales it down to the logo's cell box in config.jsonc, which
# keeps it sharp up to a display scale of 2 and at larger fonts, with no cell size written here.
# When Ghostty scales it, the color of a nearly transparent pixel bleeds into its neighbors, so
# none may hold a stray color: the faintest 2% of alpha (the glow's tail) is cut (a color at
# alpha 1 has only all-or-nothing channels left, which showed as white specks) and the transparent
# pixels take the terminal's background in place of black.
# Run by `theme` after rendering templates; remade only when its inputs changed.
set -euo pipefail
cd "$(dirname "$0")"
colors=../theme/.config/theme/colors.sh
src=logo.svg
out=.config/fastfetch/logo.png
stamp=render.stamp # sha256 of what the logo is made from
. "$colors"
if ! command -v rsvg-convert >/dev/null || ! command -v magick >/dev/null; then
	echo "skip    fastfetch logo: no rsvg-convert or magick (install.sh --packages)" >&2
	exit 0
fi
inputs=$({ echo "$THEME_TERM_BG"; cat "$0" "$src"; } | sha256sum | cut -d' ' -f1)
[[ -f $out && $(cat "$stamp" 2>/dev/null) == "$inputs" ]] && exit 0

rsvg-convert --zoom 2 "$src" |
	magick png:- -channel A -level 2%,100% +channel -background "$THEME_TERM_BG" -alpha background \
		-define png:exclude-chunks=date,time "$out"
echo "$inputs" >"$stamp"
echo "render  fastfetch/$out"

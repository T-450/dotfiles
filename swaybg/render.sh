#!/usr/bin/env bash
# swaybg/render.sh: the desktop wallpaper, .config/swaybg/wallpaper.png (linked into your home).
# A palette may name its own style (`wallpaper = "nebula"` in [meta], THEME_WALLPAPER). Otherwise
# dark palettes get Neptune in ASCII (pkg/wallpaper-neptune-ascii) at 3840x2160, the largest
# output; the near-black image suits every dark palette as it is. Light palettes get their plain
# desktop color. Run by `theme` after rendering templates; remade only when its inputs changed.
set -euo pipefail
cd "$(dirname "$0")"
colors=../theme/.config/theme/colors.sh
src=/usr/share/backgrounds/neptune-ascii.png
out=.config/swaybg/wallpaper.png
stamp=render.stamp # sha256 of what the wallpaper is made from
. "$colors"
style=${THEME_WALLPAPER:-}
if [[ $style == nebula ]]; then
	source_id="nebula $THEME_BG_DESKTOP $THEME_SELECTION_BG $THEME_ACCENT $THEME_LINK $THEME_FG_BRIGHT $THEME_WARNING"
elif [[ $THEME_VARIANT == light ]]; then
	source_id=$THEME_BG_DESKTOP
else
	[[ -r $src ]] || { echo "swaybg/render.sh: $src is missing (./install.sh --only swaybg installs it)" >&2; exit 1; }
	source_id=$(sha256sum <"$src")
fi
inputs=$( (echo "$THEME_VARIANT $source_id" && cat "$0") | sha256sum | cut -d' ' -f1)
[[ -f $out && $(cat "$stamp" 2>/dev/null) == "$inputs" ]] && exit 0
mkdir -p "$(dirname "$out")"

# mix A B T: color A blended toward B by T (0..1), as #rrggbb
mix() { magick xc:"$1" xc:"$2" -fx "u*(1-$3)+v*$3" -depth 8 -format '#%[hex:p{0,0}]' info:; }

# nebula: a diagonal arm of layered, ridged noise mapped onto the palette's purples (the selection
# and two darker blends of it, then accent and link only at the brightest cores) over bg_desktop,
# with white and amber stars. Fixed seeds, so the same palette always gives the same image.
nebula() {
	local tmp
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' RETURN
	local bg=$THEME_BG_DESKTOP deep mid=$THEME_SELECTION_BG lift
	deep=$(mix "$THEME_SELECTION_BG" "$bg" 0.6)
	local dusk
	dusk=$(mix "$THEME_SELECTION_BG" "$bg" 0.25)
	lift=$(mix "$THEME_SELECTION_BG" "$THEME_ACCENT" 0.45)
	# 640x360 noise, scaled up: fine detail comes from the smallest octave, not the resolution
	local s b
	for s in 3:40 17:14 29:5 41:1.5; do
		magick -size 640x360 -seed "${s%%:*}" plasma:fractal -colorspace gray -auto-level -blur "0x${s##*:}" -auto-level "$tmp/o${s%%:*}.png"
	done
	magick "$tmp"/o3.png "$tmp"/o17.png "$tmp"/o29.png "$tmp"/o41.png \
		-fx '0.45*u[0]+0.28*u[1]+0.17*u[2]+0.10*u[3]' -auto-level "$tmp/fbm.png"
	magick "$tmp/fbm.png" -fx '1-abs(2*u-1)' -auto-level -gamma 1.6 "$tmp/ridge.png"
	magick -size 640x360 xc: -fx 'yy=(j/h-0.5)-(i/w-0.5)*0.55; exp(-pow(yy/0.22,2))' "$tmp/band.png"
	magick "$tmp/fbm.png" "$tmp/ridge.png" "$tmp/o41.png" "$tmp/band.png" \
		-fx '(0.45*u[0]+0.35*u[1]+0.20*u[2])*(0.45+0.55*u[3])' -auto-level \
		-resize 3840x2160\! -blur 0x2 -level 5%,100% "$tmp/cloud.png"
	# the color ramp: half the range stays bg_desktop, so the arm floats in black
	magick \( -size 1x110 xc:"$bg" \) \( -size 1x46 gradient:"$bg-$deep" \) \( -size 1x40 gradient:"$deep-$dusk" \) \
		\( -size 1x34 gradient:"$dusk-$mid" \) \( -size 1x18 gradient:"$mid-$lift" \) \
		\( -size 1x6 gradient:"$lift-$THEME_ACCENT" \) \( -size 1x2 gradient:"$THEME_ACCENT-$THEME_LINK" \) \
		-append -resize 1x256\! "$tmp/ramp.png"
	b=$tmp/stars
	magick -size 1920x1080 xc:black -seed 5 +noise Random -channel G -separate +channel -threshold 99.97% \
		-resize 3840x2160 -blur 0x1 -level 0,55% +level-colors "black,$THEME_FG_BRIGHT" "$b-white.png"
	magick -size 960x540 xc:black -seed 9 +noise Random -channel R -separate +channel -threshold 99.99% \
		-resize 3840x2160 -blur 0x3 -level 0,25% +level-colors "black,$THEME_WARNING" "$b-amber.png"
	magick "$tmp/cloud.png" "$tmp/ramp.png" -clut "$b-white.png" -compose screen -composite \
		"$b-amber.png" -compose screen -composite -strip "$out"
}

if [[ $style == nebula ]]; then
	nebula
elif [[ $THEME_VARIANT == light ]]; then
	magick -size 16x16 "xc:$THEME_BG_DESKTOP" "$out" # swaybg -m fill scales it to the output
else
	# no alpha (the image is opaque): ImageMagick then downscales with Lanczos, which keeps the
	# characters crisp
	magick "$src" -alpha off -resize '3840x2160^' -gravity center -extent 3840x2160 -strip "$out"
fi
echo "$inputs" >"$stamp"
echo "render  swaybg/$out"

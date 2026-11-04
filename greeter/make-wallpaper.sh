#!/usr/bin/env bash
# Render the greeter wallpaper: a ringed planet on the Dark 2026 background (original art).
# Output: wallpapers/sysc-greet-dark-2026.png (3840x2160; sysc-greet picks it for theme "Dark 2026")
set -euo pipefail
cd "$(dirname "$0")"
W=3840 H=2160 CX=2540 CY=1020 R=430
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# stars: sparse thresholded noise, two sizes
magick -size ${W}x${H} xc:black -seed 2026 +noise Random -channel G -separate +channel \
  -threshold 99.985% -morphology Dilate Disk:1.5 -blur 0x1.4 -level 0,55% "$tmp/stars_big.png"
magick -size ${W}x${H} xc:black -seed 7 +noise Random -channel R -separate +channel \
  -threshold 99.93% -evaluate multiply 0.45 "$tmp/stars_small.png"

# planet: lit from the upper left, primary -> secondary -> shadow
magick -size $((2*R))x$((2*R)) radial-gradient:'#7cc4e6'-'#0b1f2a' \
  -distort SRT "$((R)),$((R)) 1.55 0 $((R-180)),$((R-160))" "$tmp/body.png"
magick -size $((2*R))x$((2*R)) xc:black -fill white -draw "circle $R,$R $R,0" "$tmp/mask.png"
# faint bands
magick -size $((2*R))x$((2*R)) gradient:'#ffffff'-'#000000' -function Sinusoid 9,90 \
  -level 0,100% -evaluate multiply 0.10 "$tmp/bands.png"
magick "$tmp/body.png" "$tmp/bands.png" -compose screen -composite "$tmp/mask.png" \
  -alpha off -compose copy-opacity -composite "$tmp/planet.png"

# ring as an ellipse band; split into back (upper) and front (lower) halves
ring() { # ring <out> <half: back|front>
  local clip
  if [[ $2 == back ]]; then clip="rectangle 0,0 $W,$CY"; else clip="rectangle 0,$CY $W,$H"; fi
  magick -size ${W}x${H} xc:none -fill none \
    -stroke '#e5ba7dcc' -strokewidth 46 -draw "ellipse $CX,$CY 900,170 0,360" \
    \( -size ${W}x${H} xc:none -fill none -stroke white -strokewidth 10 -draw "ellipse $CX,$CY 880,165 0,360" \) -compose DstOut -composite -compose over \
    -stroke '#c9a066aa' -strokewidth 18 -draw "ellipse $CX,$CY 790,148 0,360" \
    \( -size ${W}x${H} xc:none -fill white -draw "$clip" \) -compose DstIn -composite \
    -background none -virtual-pixel transparent -distort SRT "$CX,$CY 1 -11" "$1"
}
ring "$tmp/ring_back.png" back
ring "$tmp/ring_front.png" front

magick -size ${W}x${H} xc:'#121314' \
  "$tmp/stars_small.png" -compose screen -composite \
  "$tmp/stars_big.png" -compose screen -composite \
  "$tmp/ring_back.png" -compose over -composite \
  "$tmp/planet.png" -geometry +$((CX-R))+$((CY-R)) -compose over -composite \
  "$tmp/ring_front.png" -compose over -composite \
  -depth 8 wallpapers/sysc-greet-dark-2026.png
echo wallpapers/sysc-greet-dark-2026.png

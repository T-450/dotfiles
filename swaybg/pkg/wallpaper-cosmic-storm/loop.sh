#!/usr/bin/env bash
# loop.sh loop SRC OUT.mp4 START LAST CROSSFADE CROP_Y | loop.sh still SRC OUT.png SECONDS CROP_Y
# A portrait 720x1280 clip -> a 1920x1080 wallpaper. loop: frames START..LAST, a 16:9 band from
# CROP_Y, its last CROSSFADE frames faded into its first, so playback restarts on the frame that
# follows the last one (a seamless loop). still: the band at SECONDS as a PNG.
# Every step keeps 16 bits per channel (eq, vignette and hue would drop to 8 or 10 and band the dark
# gradients): nlmeans (compression noise), zimg Lanczos upscale, deband, CAS sharpen, a slight
# contrast curve and vibrance; loops add fine temporal grain and end as 10-bit HEVC, which the
# UHD 620 decodes in hardware.
set -euo pipefail
mode=$1 src=$2 out=$3
band() { echo "crop=720:404:0:$1,format=yuv444p16le,nlmeans=s=1.2:p=7:r=9"; }
grade="zscale=w=1920:h=1080:filter=lanczos:matrixin=709:transferin=709:primariesin=709:rangein=limited:transfer=709:primaries=709:range=full,format=gbrp16le,deband=1thr=0.012:2thr=0.012:3thr=0.012:range=24:blur=1,cas=strength=0.3,curves=all='0/0 0.25/0.235 0.75/0.765 1/1',vibrance=intensity=0.08"

case $mode in
loop)
	start=$4 last=$5 c=$6 y=$7
	n=$((last - start + 1))
	off=$(awk -v n=$n -v c=$c 'BEGIN { printf "%.6f", (n - 2 * c) / 24 }')
	dur=$(awk -v c=$c 'BEGIN { printf "%.6f", c / 24 }')
	ffmpeg -nostdin -v error -y -i "$src" -filter_complex "
[0:v]trim=start_frame=$start,setpts=PTS-STARTPTS,$(band "$y"),split=2[a][b];
[a]trim=start_frame=$c:end_frame=$n,setpts=PTS-STARTPTS[body];
[b]trim=start_frame=0:end_frame=$c,setpts=PTS-STARTPTS[head];
[body][head]xfade=transition=fade:duration=$dur:offset=$off,$grade,noise=alls=2:allf=t,
zscale=matrix=709:transfer=709:primaries=709:range=limited:dither=error_diffusion,format=yuv420p10le[v]" \
		-map '[v]' -c:v libx265 -preset slow -crf 18 -tag:v hvc1 -an \
		-x265-params 'log-level=error:keyint=999:min-keyint=999:scenecut=0:aq-mode=3:deblock=-1,-1:open-gop=0' \
		-color_primaries bt709 -color_trc bt709 -colorspace bt709 -movflags +faststart "$out"
	;;
still)
	t=$4 y=$5
	ffmpeg -nostdin -v error -y -ss "$t" -i "$src" -frames:v 1 -vf "$(band "$y"),$grade,format=rgb24" -update 1 "$out"
	;;
*) echo "usage: loop.sh loop|still ..." >&2 && exit 2 ;;
esac

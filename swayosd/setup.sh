#!/usr/bin/env bash
# swayosd/setup.sh: your user in the video group, so the brightness keys (swayosd) and the bar's
# brightness scroll (waybar) can write the backlight. Both run as systemd user units, outside the
# logind session, so logind's SetBrightness (brightnessctl's fallback without write access) refuses
# them; the backlight's brightness file is root:video and group-writable. Applies from the next login.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
me=$(id -un)
if ! id -nG "$me" | tr ' ' '\n' | grep -qx video; then
	sudo usermod -aG video "$me"
	echo "group   $me in video (brightness from user units; next login)"
fi

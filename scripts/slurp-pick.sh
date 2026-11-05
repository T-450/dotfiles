#!/usr/bin/env bash
# slurp-pick.sh [slurp args...]: slurp in the active palette's colors
# Used by screenshot.sh and the screencast output chooser (xdg-desktop-portal-wlr).
colors=~/.config/mango/theme/colors.sh
if [[ ! -r $colors ]]; then
	# rendered by `theme/theme init`; without it slurp would get "-b 88" and refuse
	notify-send -u critical -a theme "Colors not rendered" "run ~/.config/mango/theme/theme init"
	exec slurp "$@"
fi
. "$colors"
exec slurp -b "${THEME_BG_DESKTOP}88" -c "${THEME_ACCENT}ff" "$@"

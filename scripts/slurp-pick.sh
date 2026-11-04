#!/usr/bin/env bash
# slurp-pick.sh [slurp args...]: slurp in the active palette's colors
# Used by screenshot.sh and the screencast output chooser (xdg-desktop-portal-wlr).
. ~/.config/mango/theme/colors.sh
exec slurp -b "${THEME_BG_DESKTOP}88" -c "${THEME_ACCENT}ff" "$@"

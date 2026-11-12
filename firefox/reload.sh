#!/usr/bin/env bash
# firefox/reload.sh: ask for a restart when Firefox is running (run by `theme set`).
# Firefox reads userChrome.css only at startup, so a running browser keeps the old colors.
pgrep -x firefox >/dev/null || exit 0
exec notify-send -a theme "Theme: Firefox" "Restart Firefox to apply ${THEME_NAME}"

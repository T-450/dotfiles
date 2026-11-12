#!/usr/bin/env bash
# opencode/reload.sh: ask for a restart when opencode is running (run by `theme set`).
# opencode reads its theme only at startup.
pgrep -x opencode >/dev/null || exit 0
exec notify-send -a theme "Theme: opencode" "Restart opencode to apply ${THEME_NAME}"

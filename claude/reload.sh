#!/usr/bin/env bash
# claude/reload.sh: ask for a restart when Claude Code is running (run by `theme set`).
# Claude Code reads its theme only when a session starts.
pgrep -x claude >/dev/null || exit 0
exec notify-send -a theme "Theme: Claude Code" "Start a new Claude Code session to apply ${THEME_NAME}"

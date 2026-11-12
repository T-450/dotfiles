#!/usr/bin/env bash
# ghostty/reload.sh: open ghostty windows re-read config.ghostty, its colors.ghostty and tabs.css (run by `theme set`)
pkill -USR2 -x ghostty || true

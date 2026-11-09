#!/usr/bin/env bash
# kitty/reload.sh: open kitty windows re-read kitty.conf and its colors.conf (run by `theme set`)
pkill -USR1 -x kitty || true

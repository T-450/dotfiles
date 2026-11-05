#!/usr/bin/env bash
# qutebrowser/reload.sh: re-read config.py (and colors.py) in a running qutebrowser (run by
# `theme set`). Only when one runs: the command line would otherwise start a new browser.
pgrep -u "$USER" -f '^/usr/bin/python[0-9.]* /usr/bin/qutebrowser|^/usr/bin/qutebrowser' >/dev/null || exit 0
exec qutebrowser --nowindow ':config-source' >/dev/null 2>&1

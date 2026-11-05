#!/usr/bin/env bash
# mako/reload.sh: re-read ~/.config/mako/config (and its colors include) (run by `theme set`)
systemctl --user -q is-active mako.service || exit 0
exec systemctl --user reload mako.service

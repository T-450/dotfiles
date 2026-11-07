#!/usr/bin/env bash
# swaybg/reload.sh: restart swaybg.service, which reads its color and wallpaper at startup (run by
# `theme set`). try-restart leaves a stopped unit alone.
systemctl --user -q is-active graphical-session.target || exit 0
exec systemctl --user try-restart swaybg.service

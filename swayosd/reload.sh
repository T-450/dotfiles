#!/usr/bin/env bash
# swayosd/reload.sh: restart swayosd.service, which reads its colors at startup (run by `theme set`).
# try-restart leaves a stopped unit alone (a bar hidden with its toggle stays hidden).
systemctl --user -q is-active graphical-session.target || exit 0
exec systemctl --user try-restart swayosd.service

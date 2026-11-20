#!/usr/bin/env bash
# walker/reload.sh: restart walker.service so the updated viewport colors.css loads (run by `theme set`).
systemctl --user -q is-active graphical-session.target || exit 0
exec systemctl --user try-restart walker.service

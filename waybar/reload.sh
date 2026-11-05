#!/usr/bin/env bash
# waybar/reload.sh: reload waybar's config and CSS (colors.css changed) in place (run by `theme set`).
# A stopped bar (hidden with waybar-toggle) stays stopped.
systemctl --user -q is-active waybar.service || exit 0
exec systemctl --user reload waybar.service

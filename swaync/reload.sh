#!/usr/bin/env bash
# swaync/reload.sh: reload swaync's CSS after colors.css changes (run by `theme set`).
systemctl --user -q is-active swaync.service || exit 0
exec swaync-client -rs

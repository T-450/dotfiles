#!/usr/bin/env bash
# mako/reload.sh: re-read ~/.config/mako/config (and its colors include) (run by `theme set`)
pidof -q mako || exit 0
exec makoctl reload

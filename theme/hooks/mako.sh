#!/usr/bin/env bash
# mako.sh: re-read mako/config (and its colors include) (run by `theme set`)
pidof -q mako || exit 0
exec makoctl reload

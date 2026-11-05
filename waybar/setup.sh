#!/usr/bin/env bash
# waybar/setup.sh: remove mangobar, which waybar replaced (idempotent).
set -euo pipefail
if pacman -Q mangobar-git &>/dev/null; then sudo pacman -Rns --noconfirm mangobar-git; fi

#!/usr/bin/env bash
# waybar/setup.sh: remove mangobar, which waybar replaced (idempotent).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
remove_pkgs mangobar-git

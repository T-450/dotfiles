#!/usr/bin/env bash
# mango/setup.sh: drop xorg-xrdb, used only by the removed 1.5x-scale variant (idempotent).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
remove_pkgs xorg-xrdb

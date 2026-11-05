#!/usr/bin/env bash
# this machine's explicitly installed packages are exactly the declared ones (reference machine only:
# a CI VM's base image brings packages of its own).
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_command pacman
if [[ -n ${CI:-} ]]; then skip "package drift: CI VM (cloud image packages are not declared)"; exit 0; fi
out=$("$ROOT/tools/docs" --drift) || fail "installed packages match */packages" "$out"
pass "no package drift"

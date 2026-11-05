#!/usr/bin/env bash
# the home this checkout is installed into matches it: every link in place, no app replaced a
# linked file with a real one, system files current (install.sh --check). Skipped where this
# checkout isn't the installed one.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
installed=$(realpath -m "$HOME/.config/mango/config.conf" 2>/dev/null || true)
if [[ $installed != "$ROOT"/* ]]; then skip "this checkout isn't the installed one"; exit 0; fi
out=$("$ROOT/install.sh" --check 2>&1) || fail "install.sh --check" "$out"
pass "home and system files match the repo"

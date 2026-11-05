#!/usr/bin/env bash
# docs/ in step with the repo: generated blocks current, one page per app, no orphan pages.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
out=$("$ROOT/tools/docs" --check) || fail "tools/docs --check" "$out"
pass "docs match the repo"
# every relative link in docs/ points at a file
bad=$(cd "$ROOT/docs" && grep -rnoE '\]\([^)#:]+(#[^)]*)?\)' --include=*.md . | while IFS=: read -r f _ m; do
	t=${m#*](}; t=${t%)}; t=${t%%#*}; [[ -e $(dirname "$f")/$t ]] || echo "$f -> $t"; done)
[[ -z $bad ]] || fail "docs links resolve" "$bad"
pass "docs links resolve"

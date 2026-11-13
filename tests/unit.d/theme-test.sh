#!/usr/bin/env bash
# theme engine: every template renders, outputs are complete and stable, lint is clean, errors abort.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_command python3
scratch_home
theme=$ROOT/theme/.local/bin/theme
out=$TEST_TMP/out

# a template with {palette} in its name renders once per palette
n_plain=$(cd "$ROOT" && find . -path ./tests -prune -o -name '*.tmpl' ! -name '*{palette}*' -print | wc -l)
n_each=$(cd "$ROOT" && find . -path ./tests -prune -o -name '*{palette}*.tmpl' -print | wc -l)
n_tmpl=$((n_plain + n_each * $("$theme" list | wc -l)))
for p in $("$theme" list | tr -d '* '); do
	rm -rf "$out"
	msg=$("$theme" init "$p" --to "$out") || fail "palette $p renders" "$msg"
	n_out=$(find "$out" -type f | wc -l)
	((n_out == n_tmpl)) || fail "palette $p renders every template ($n_out of $n_tmpl)"
	! grep -rIl '{{' "$out" >/dev/null || fail "palette $p leaves no {{token}}" "$(grep -rIn '{{' "$out" | head)"
done
pass "every palette renders all $n_tmpl files, no token left"

rm -rf "$out" && "$theme" init dark-2026 --to "$out" >/dev/null && a=$(cd "$out" && find . -type f -exec sha256sum {} + | sort)
rm -rf "$out" && "$theme" init dark-2026 --to "$out" >/dev/null && b=$(cd "$out" && find . -type f -exec sha256sum {} + | sort)
[[ $a == "$b" ]] || fail "rendering is deterministic"
pass "rendering is deterministic"

msg=$("$theme" lint) || fail "theme lint" "$msg"
pass "lint: no color literals, rendered files gitignored, no secrets tracked"

[[ ! -e $HOME/.local/state/theme/current ]] || fail "--to does not change the active palette"
pass "--to renders without touching the active palette"

# an unknown role must abort before anything is written (in a copy of the repo)
cp -r "$ROOT" "$TEST_TMP/repo" && rm -rf "$TEST_TMP/repo/.git"
echo 'x={{no_such_role}}' >"$TEST_TMP/repo/ghostty/bad.conf.tmpl"
rm -rf "$out"
if "$TEST_TMP/repo/theme/.local/bin/theme" init dark-2026 --to "$out" >/dev/null 2>&1; then
	fail "an unknown role is an error"
fi
[[ ! -e $out ]] || [[ -z $(find "$out" -type f) ]] || fail "nothing is written when a template fails"
pass "an unknown role aborts before any file is written"

#!/usr/bin/env bash
# install.sh --system into a scratch root: every <app>/root file lands, owners follow the nearest
# existing dir, templates stay out, a second run is silent, --check sees a changed file.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
scratch_home
r=$TEST_TMP/root
mkdir -p "$r/etc" "$r/usr/share" "$r/usr/local" "$r/var/lib/greeter"
"$ROOT/theme/.local/bin/theme" init >/dev/null 2>&1 || true # outputs of root/ templates (repo copy)

out=$("$ROOT/install.sh" --root "$r") || fail "install.sh --root" "$out"
want=$(cd "$ROOT" && find ./*/root \( -type f -o -type l \) ! -name '*.tmpl' | sed 's|^\./[^/]*/root||' | sort)
got=$(cd "$r" && find . -type f | sed 's|^\.||' | sort)
[[ $want == "$got" ]] || fail "every root file is installed, nothing else" "$(diff <(echo "$want") <(echo "$got"))"
pass "every <app>/root file installed ($(wc -l <<<"$got") files), templates left out"

[[ $(stat -c %U "$r/var/lib/greeter/.cache") == "$(stat -c %U "$r/var/lib/greeter")" ]] ||
	fail "created dirs take the owner of the nearest existing dir"
pass "created dirs owned like their existing parent"

out=$("$ROOT/install.sh" --root "$r")
! grep -q '^install ' <<<"$out" || fail "second run installs nothing" "$out"
pass "second run is silent"

f=$(find "$r/etc" -type f | head -1)
echo changed >>"$f"
if "$ROOT/install.sh" --root "$r" --check >/dev/null 2>&1; then fail "--check reports a changed system file"; fi
pass "--check reports a changed system file"

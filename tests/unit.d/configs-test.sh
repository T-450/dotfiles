#!/usr/bin/env bash
# every app's config parses with its own tool, against the rendered palette files.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
scratch_home
"$ROOT/theme/.local/bin/theme" init dark-2026 --to "$TEST_TMP/r" >/dev/null
# a home with the repo stowed, rendered files included (copied over the repo's own renders)
cp -r "$ROOT" "$TEST_TMP/repo" && rm -rf "$TEST_TMP/repo/.git"
(cd "$TEST_TMP/r" && find . -type f -exec cp --parents {} "$TEST_TMP/repo/" \;)
"$TEST_TMP/repo/install.sh" --home "$HOME" >/dev/null
cfg=$HOME/.config

if command -v mango >/dev/null; then
	out=$(mango -c "$cfg/mango/config.conf" -p 2>&1) || fail "mango config parses" "$out"
	pass "mango -p"
else skip "mango not installed"; fi

if command -v ghostty >/dev/null; then
	# ghostty's own loader (config.ghostty, its colors.ghostty and tabs.css): prints each bad line.
	# Through a pipe: ghostty truncates a file it is given as stdout.
	out=$(ghostty +validate-config 2>&1 </dev/null | cat) && [[ -z $out ]] || fail "ghostty config parses" "$out"
	pass "ghostty config loads cleanly"
else skip "ghostty not installed"; fi

for f in "$cfg/waybar/config.jsonc" "$cfg/fastfetch/config.jsonc"; do
	python3 - "$f" <<'PY' || fail "$f is valid JSONC"
import json, re, sys
t = open(sys.argv[1]).read()
t = re.sub(r'^\s*//.*$', '', t, flags=re.M)  # line comments only (URLs inside strings keep their //)
json.loads(t)
PY
done
pass "waybar and fastfetch JSONC parse"

python3 -c "
class N:
    def __getattr__(s, k): v = N(); object.__setattr__(s, k, v); return v
    def __call__(s, *a, **k): return None
c = N(); config = N()
exec(open('$cfg/qutebrowser/colors.py').read()); exec(open('$cfg/qutebrowser/config.py').read())
" || fail "qutebrowser config.py and colors.py run"
pass "qutebrowser config runs"

if command -v systemd-analyze >/dev/null; then
	for u in "$cfg"/systemd/user/*.service; do
		out=$(systemd-analyze --user verify "$u" 2>&1 | grep -v -e 'Unit .* not found' -e 'is not executable' || true)
		[[ -z $out ]] || fail "$(basename "$u") verifies" "$out"
	done
	pass "user units verify"
else skip "systemd-analyze not installed"; fi

while IFS= read -r -d '' f; do
	head -1 "$f" | grep -q bash || continue
	bash -n "$f" || fail "bash syntax: $f"
done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -type f \( -name '*.sh' -o -path '*/.local/bin/*' \) -print0)
pass "every bash script parses"
if command -v shellcheck >/dev/null; then
	out=$(cd "$ROOT" && find . -path ./.git -prune -o -type f \( -name '*.sh' -o -path '*/.local/bin/*' \) -print |
		xargs grep -l '^#!.*bash' | xargs shellcheck -S error 2>&1) || fail "shellcheck errors" "$out"
	pass "shellcheck (errors)"
else skip "shellcheck not installed"; fi

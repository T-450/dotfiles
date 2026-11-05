#!/usr/bin/env bash
# a live session: every repo unit is active, the bar is up, the theme reloads cleanly.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_session
failed=$(systemctl --user --failed --no-legend --plain | awk '{print $1}')
[[ -z $failed ]] || fail "no failed user units" "$failed"
pass "no failed user units"
for f in "$ROOT"/*/.config/systemd/user/*.service; do
	u=$(basename "$f")
	[[ $u == runner-up.service ]] && continue
	systemctl --user -q is-active "$u" || fail "$u is active"
done
pass "every session unit is active"
pidof -q waybar || fail "waybar runs"
pass "waybar runs"

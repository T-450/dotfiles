#!/usr/bin/env bash
# a live session: every repo unit is active (or switched off by its ConditionPathExists=! flag),
# the bar is up, the theme reloads cleanly.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_session
failed=$(systemctl --user --failed --no-legend --plain | awk '{print $1}')
[[ -z $failed ]] || fail "no failed user units" "$failed"
pass "no failed user units"
for f in "$ROOT"/*/.config/systemd/user/*.service; do
	u=$(basename "$f")
	[[ $u == runner-up.service ]] && continue
	systemctl --user -q is-active "$u" && continue
	# off by the user's choice: a ConditionPathExists=!PATH flag (nightlight's `off`) that exists
	off=0
	while IFS= read -r p; do
		[[ -e ${p//%h/$HOME} ]] && off=1
	done < <(sed -n 's/^ConditionPathExists=!//p' "$f")
	# or by its ExecCondition: swaybg.service and gslapper.service each start only for their kind of
	# wallpaper (wallpaper-is), so one of them is always skipped
	while IFS= read -r c; do
		read -ra cmd <<<"${c//%h/$HOME}"
		"${cmd[@]}" &>/dev/null || off=1
	done < <(sed -n 's/^ExecCondition=//p' "$f")
	((off)) || fail "$u is active"
done
pass "every session unit is active"
pidof -q waybar || fail "waybar runs"
pass "waybar runs"

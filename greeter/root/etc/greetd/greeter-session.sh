#!/usr/bin/env bash
# Started by mango -s: the panel is off before sysc-greet picks the monitor for its prompt, and
# follows a display plugged in or out while the login screen is up.
/etc/greetd/greeter-panel

# mango streams focus and tag changes too: act only when the set of monitor names changes.
# The stream ends when mango quits, so the watcher dies with the greeter. Its output goes to
# /dev/null: a descriptor it inherited would keep the greeter's log pipe open past mango.
watch_monitors() {
	local line names last=
	while read -r line; do
		names=$(jq -r '[.monitors[]?.name] | sort | join(",")' <<<"$line" 2>/dev/null) || continue
		[[ -n $names && $names != "$last" ]] || continue
		last=$names
		/etc/greetd/greeter-panel
	done < <(mmsg watch all-monitors 2>/dev/null)
}
if command -v mmsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
	watch_monitors </dev/null >/dev/null 2>&1 &
fi

exec /etc/greetd/mango-greeter-session.sh

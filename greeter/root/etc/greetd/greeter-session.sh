#!/usr/bin/env bash
# Started by mango -s inside greetd: disables the closed laptop panel before the greeter opens,
# displays the Blue Dawn eclipse backdrop via swaybg, runs the Viewport GTK3 greeter, and quits
# mango once authentication succeeds so greetd launches the user session.
export HOME=/var/lib/greeter
export XDG_CACHE_HOME=/var/lib/greeter/.cache
export XDG_CONFIG_HOME=/var/lib/greeter/.config
export XDG_STATE_HOME=/var/lib/greeter/.local/state

/etc/greetd/greeter-panel

# follow monitor hotplug at the login screen; dies when mango exits
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

# static Blue Dawn eclipse backdrop (matching hyprlock)
bg_pid=
dawn=/usr/share/backgrounds/cosmic-storm/blue-dawn-lock.png
if command -v swaybg >/dev/null 2>&1 && [[ -r $dawn ]]; then
	swaybg -i "$dawn" -m fill </dev/null >/dev/null 2>&1 &
	bg_pid=$!
fi
cleanup() {
	[[ -n $bg_pid ]] && kill "$bg_pid" 2>/dev/null || true
}
trap cleanup EXIT

/etc/greetd/greeter-ui || true
mmsg dispatch quit

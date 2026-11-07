# tools/setup-lib.sh: helpers for <app>/setup.sh and install.sh (sourced): enable_system,
# user_bus, retry. A helper that changes state checks it first and acts (and prints) only on a
# difference, so a second run is silent.
# Usage in a setup.sh:  . "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

# enable_system UNIT...: enable (and start) system units not enabled yet
enable_system() {
	local u
	for u; do
		[[ $(systemctl is-enabled "$u" 2>/dev/null) == enabled ]] && continue
		sudo systemctl enable --now "$u" || return 1
		echo "enable  $u"
	done
}

# user_bus: true when a user systemd/dbus session is reachable (not in a bare VM or chroot)
user_bus() { systemctl --user show-environment &>/dev/null; }

retry() { # retry CMD...: up to 3 attempts; a mirror that stalls on one file must not fail the run
	local i
	for i in 1 2 3; do
		"$@" && return 0
		((i < 3)) && echo "retry   attempt $i of 3 failed: $*; again in 15s" >&2 && sleep 15
	done
	return 1
}

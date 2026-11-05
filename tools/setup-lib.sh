# tools/setup-lib.sh: helpers for <app>/setup.sh (sourced). Each helper checks the current state
# first and acts (and prints) only on a difference, so a second run is silent.
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

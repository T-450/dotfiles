# tools/setup-lib.sh: helpers for <app>/setup.sh and install.sh (sourced): enable_system,
# user_bus, default_app, retry, when_changed. A helper that changes state checks it first and acts
# (and prints) only on a difference, so a second run is silent.
# Usage in a setup.sh:  . "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
set -euo pipefail
# Ctrl+C ends the run. yay and pacman catch SIGINT and exit 1, so without this bash can't tell an
# interrupt from a failure and retry() would run them again.
trap 'echo "interrupted" >&2; exit 130' INT
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

# default_app DESKTOP TYPE...: make DESKTOP (an installed .desktop file) the default for each MIME
# type that has another default (~/.config/mimeapps.list, through GLib like every app reads it)
default_app() {
	local desktop=$1 t n=0
	shift
	for t; do
		[[ $(gio mime "$t" 2>/dev/null | head -1) == *": $desktop" ]] && continue
		gio mime "$t" "$desktop" >/dev/null && n=$((n + 1))
	done
	((n == 0)) || echo "default $desktop for $n type(s)"
}

retry() { # retry CMD...: up to 3 attempts; a mirror that stalls on one file must not fail the run
	local i
	for i in 1 2 3; do
		"$@" && return 0
		((i < 3)) && echo "retry   attempt $i of 3 failed: $*; again in 15s" >&2 && sleep 15
	done
	return 1
}

# when_changed STAMP CMD...: run CMD when the inputs on stdin (file contents, `pacman -Q` lines)
# hash differently from the last run that succeeded, whose sha256 STAMP holds. A failed CMD leaves
# STAMP as it was, so the next run tries again. bash ignores set -e inside a tested command, so CMD
# chains its steps with &&.
when_changed() {
	local stamp=$1 sum
	shift
	sum=$(sha256sum | cut -d' ' -f1)
	[[ $(cat -- "$stamp" 2>/dev/null) == "$sum" ]] && return 0
	"$@" || return
	echo "$sum" >"$stamp"
}

# tools/setup-lib.sh: helpers for <app>/setup.sh (sourced). Every helper is idempotent:
# it checks the current state first and only acts (and prints) on a difference.
# Usage in a setup.sh:  . "$(dirname "$0")/../tools/setup-lib.sh"
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

# sys_file SRC DST [MODE]: install a repo file into the system (sudo) when it differs
sys_file() {
	local src=$1 dst=$2 mode=${3:-644}
	# compare without sudo when the target is readable (most of /etc is), so a no-op run asks nothing
	if [[ -r $dst ]] && cmp -s -- "$src" "$dst"; then return 0; fi
	if [[ -e $dst && ! -r $dst ]] && sudo cmp -s -- "$src" "$dst"; then return 0; fi
	sudo install -Dm"$mode" -- "$src" "$dst"
	echo "install $dst"
}

# enable_system UNIT...: enable (and start) system units not enabled yet
enable_system() {
	local u
	for u; do
		[[ $(systemctl is-enabled "$u" 2>/dev/null) == enabled ]] && continue
		sudo systemctl enable --now "$u" && echo "enable  $u"
	done
}

# remove_pkgs PKG...: uninstall packages this setup replaced, if still installed
remove_pkgs() {
	local p have=()
	for p; do pacman -Q "$p" &>/dev/null && have+=("$p"); done
	((${#have[@]})) || return 0
	sudo pacman -Rns --noconfirm "${have[@]}" && echo "remove  ${have[*]}"
}

# user_bus: true when a user systemd/dbus session is reachable (not in a bare VM or chroot)
user_bus() { systemctl --user show-environment &>/dev/null; }

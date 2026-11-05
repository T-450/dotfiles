#!/usr/bin/env bash
# install.sh [--packages] [--link] [--theme] [--setup] [--units] [--home DIR] [--only PKG...]
# Set up this desktop from the repo. Idempotent: safe to re-run, a clean Arch install included.
# No phase flag = every phase, in this order:
#   packages  pacman/AUR packages from every <app>/packages (sudo; AUR via yay)
#   link      GNU stow every <app> (its .config/ .local/ and dot-entries) into $HOME
#   theme     render the active palette (theme init)
#   setup     each <app>/setup.sh (idempotent extras: system files, gsettings, profiles)
#   units     enable the repo's user units, start them inside a running session
# --home DIR links into DIR instead of $HOME (tests); it implies --link only unless phases are given.
# Run as your user, not root: sudo is called where needed.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
home=$HOME
phases=() only=()

while (($#)); do
	case $1 in
	--packages | --link | --theme | --setup | --units) phases+=("${1#--}") ;;
	--home) home=$(realpath -m -- "$2") && shift ;;
	--only) shift && while (($#)) && [[ $1 != --* ]]; do only+=("$1") && shift; done && continue ;;
	-h | --help) sed -n '2,13s/^# \{0,1\}//p' "$0" && exit 0 ;;
	*) echo "install.sh: unknown argument $1" >&2 && exit 2 ;;
	esac
	shift
done
if ((${#phases[@]} == 0)); then
	if [[ $home != "$HOME" ]]; then phases=(link); else phases=(packages link theme setup units); fi
fi
[[ $EUID -ne 0 ]] || { echo "install.sh: run as your user (it calls sudo itself)" >&2 && exit 1; }

say() { printf '==> %s\n' "$*"; }
has() { local p; for p in "${phases[@]}"; do [[ $p == "$1" ]] && return 0; done; return 1; }

# Packages: every top-level dir with a .stow-local-ignore, optionally limited by --only.
packages() {
	local d name
	for d in "$repo"/*/.stow-local-ignore; do
		[[ -e $d ]] || continue
		name=$(basename "$(dirname "$d")")
		if ((${#only[@]})) && [[ " ${only[*]} " != *" $name "* ]]; then continue; fi
		echo "$name"
	done
}

# ---------------------------------------------------------------- link (GNU stow)
# Shared dirs that must stay real: other programs write into them, and with
# --no-folding stow never turns a dir into a link anyway; created up front so a
# fresh home looks like a used one.
shared_dirs=(.config .config/systemd/user .local/bin .local/share .local/state)

stow_() { stow --dir="$repo" --target="$home" --no-folding "$@"; }

# Before stowing, clear what stow refuses to replace (it aborts instead of backing up):
#  - a real file where a link goes: moved to <name>.bak.<ts>
#  - a symlink stow doesn't own (an older layout's link): removed if it points into the
#    repo, else moved to <name>.bak.<ts>. Nothing is deleted that isn't the repo's own link.
clear_conflicts() {
	local out line t ts=$(date +%s) n=0
	for _ in 1 2 3 4 5; do
		out=$(stow_ -n -R "$@" 2>&1) && return 0
		n=0
		while IFS= read -r line; do
			case $line in
			*"over existing target "*" since neither a link nor a directory"*)
				t=${line#*over existing target } t=${t%% since neither*} ;;
			*"existing target is not owned by stow: "*)
				t=${line#*existing target is not owned by stow: } ;;
			*"existing target is stowed to a different package: "*)
				echo "install.sh: two packages provide ${line#*different package: }" >&2 && return 1 ;;
			*) continue ;;
			esac
			t=$home/$t
			if [[ -L $t && $(realpath -m -- "$t") == "$repo"/* ]]; then
				rm -- "$t" && echo "unlink  $t (old repo link)"
			else
				mv -- "$t" "$t.bak.$ts" && echo "backup  $t -> $t.bak.$ts"
			fi
			n=$((n + 1))
		done <<<"$out"
		((n)) || { printf '%s\n' "$out" >&2 && return 1; }
	done
	printf '%s\n' "$out" >&2
	return 1
}

# Links into the repo that point at nothing (a file or package that was removed).
prune_dangling() {
	local l
	while IFS= read -r -d '' l; do
		[[ $(realpath -m -- "$l") == "$repo"/* ]] || continue
		rm -- "$l" && echo "prune   $l"
	done < <(find "$home" -maxdepth 1 -xtype l -print0 2>/dev/null
		find "$home/.config" "$home/.local" -xtype l -print0 2>/dev/null)
}

link() {
	command -v stow >/dev/null || { echo "install.sh: stow missing (run the packages phase)" >&2 && return 1; }
	local pkgs d
	mapfile -t pkgs < <(packages)
	((${#pkgs[@]})) || { echo "install.sh: no packages found" >&2 && return 1; }
	for d in "${shared_dirs[@]}"; do mkdir -p "$home/$d"; done
	clear_conflicts "${pkgs[@]}"
	stow_ -R "${pkgs[@]}"
	prune_dangling
	echo "linked  ${#pkgs[@]} packages into $home"
}

has link && { say "link" && link; }
exit 0

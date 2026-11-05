#!/usr/bin/env bash
# install.sh [--packages] [--link] [--theme] [--setup] [--units] [--home DIR] [--only PKG...]
# Set up this desktop from the repo. Idempotent: safe to re-run, a clean Arch install included.
# No phase flag = every phase, in this order:
#   packages  pacman/AUR packages from every <app>/packages (sudo; AUR via yay)
#   theme     render the active palette (theme init); before link: stow --no-folding links
#             only files that exist, and the rendered ones are part of the apps
#   link      GNU stow every <app> (its .config/ .local/ and dot-entries) into $HOME
#   setup     each <app>/setup.sh (idempotent extras: system files, gsettings, profiles)
#   units     enable the repo's user units, start them inside a running session
# --home DIR links into DIR instead of $HOME (tests); it implies --link only unless phases are given.
# Run as your user, not root: sudo is called where needed.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
home=$HOME
phases=() only=() home_set=

while (($#)); do
	case $1 in
	--packages | --link | --theme | --setup | --units) phases+=("${1#--}") ;;
	--home) home=$(realpath -m -- "$2") home_set=1 && shift ;;
	--only) shift && while (($#)) && [[ $1 != --* ]]; do only+=("$1") && shift; done && continue ;;
	-h | --help) sed -n '2,13s/^# \{0,1\}//p' "$0" && exit 0 ;;
	*) echo "install.sh: unknown argument $1" >&2 && exit 2 ;;
	esac
	shift
done
if ((${#phases[@]} == 0)); then
	if [[ -n $home_set ]]; then phases=(link); else phases=(packages theme link setup units); fi
fi
[[ $EUID -ne 0 ]] || { echo "install.sh: run as your user (it calls sudo itself)" >&2 && exit 1; }

say() { printf '==> %s\n' "$*"; }
has() { local p; for p in "${phases[@]}"; do [[ $p == "$1" ]] && return 0; done; return 1; }

# Stow packages: every top-level dir with a .stow-local-ignore, optionally limited by --only.
stow_packages() {
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
	mapfile -t pkgs < <(stow_packages)
	((${#pkgs[@]})) || { echo "install.sh: no packages found" >&2 && return 1; }
	for d in "${shared_dirs[@]}"; do mkdir -p "$home/$d"; done
	clear_conflicts "${pkgs[@]}"
	stow_ -R "${pkgs[@]}"
	prune_dangling
	echo "stowed  ${#pkgs[@]} packages into $home"
}

# ---------------------------------------------------------------- packages
# Every <app>/packages (one name per line, # comments). Names in the sync databases go to
# pacman, the rest to yay (bootstrapped from the AUR's yay-bin when missing). -Syu, never a
# partial -Sy: Arch doesn't support partial upgrades.
apps() { # every top-level dir that is an app (has packages, setup.sh or .stow-local-ignore)
	local d name
	for d in "$repo"/*/; do
		name=$(basename "$d")
		[[ -e $d/packages || -e $d/setup.sh || -e $d/.stow-local-ignore ]] || continue
		if ((${#only[@]})) && [[ " ${only[*]} " != *" $name "* ]]; then continue; fi
		echo "$name"
	done
}

install_packages() {
	local a all=() repo_pkgs=() aur=() p
	for a in $(apps); do
		[[ -f $repo/$a/packages ]] || continue
		while read -r p; do all+=("$p"); done < <(sed 's/#.*//' "$repo/$a/packages" | tr -s ' \t' '\n' | sed '/^$/d')
	done
	((${#all[@]})) || return 0
	sudo pacman -Sy >/dev/null # refresh the database list only to sort repo vs AUR; -Syu follows
	declare -A sync
	while read -r p; do sync[$p]=1; done < <(pacman -Slq)
	for p in $(printf '%s\n' "${all[@]}" | sort -u); do
		if [[ -n ${sync[$p]:-} ]]; then repo_pkgs+=("$p"); else aur+=("$p"); fi
	done
	sudo pacman -Syu --needed --noconfirm "${repo_pkgs[@]}"
	((${#aur[@]})) || return 0
	if ! command -v yay >/dev/null; then
		local t
		t=$(mktemp -d)
		git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin"
		(cd "$t/yay-bin" && makepkg -si --noconfirm)
		rm -rf -- "$t"
	fi
	yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${aur[@]}"
}

# ---------------------------------------------------------------- theme, setup, units
render_theme() { "$repo/theme/.local/bin/theme" init; }

run_setup() { # base first (services, /etc), then every app's setup.sh in name order
	local a
	for a in base $(apps); do
		[[ -x $repo/$a/setup.sh ]] || continue
		[[ $a == base && -n ${seen_base:-} ]] && continue
		[[ $a == base ]] && seen_base=1
		say "setup $a"
		"$repo/$a/setup.sh"
	done
}

enable_units() {
	if ! systemctl --user show-environment &>/dev/null; then
		echo "skip    units: no user systemd manager (enable them from a login session)"
		return 0
	fi
	local f units=()
	for f in "$repo"/*/.config/systemd/user/*.service; do
		[[ -e $f ]] || continue
		if ((${#only[@]})) && [[ " ${only[*]} " != *" $(basename "${f%%/.config/*}") "* ]]; then continue; fi
		units+=("$(basename "$f")")
	done
	((${#units[@]})) || return 0
	systemctl --user daemon-reload
	systemctl --user enable "${units[@]}" 2>&1 | grep -v '^$' || true
	# start what isn't running yet; session units only inside a running session (Requisite=)
	if systemctl --user -q is-active graphical-session.target; then
		systemctl --user start "${units[@]}"
	else
		systemctl --user start runner-up.service 2>/dev/null || true
	fi
	echo "units   ${#units[@]} enabled"
}

has packages && { say "packages" && install_packages; }
has theme && { say "theme" && render_theme; }
has link && { say "link" && link; }
has setup && run_setup
has units && { say "units" && enable_units; }
exit 0

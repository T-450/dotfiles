#!/usr/bin/env bash
# install.sh [--packages] [--theme] [--link] [--system] [--setup] [--units] [--check]
#            [--only APP...] [--home DIR] [--root DIR]
# Build this desktop from the repo. Idempotent: a second run changes nothing. Every app folder
# is handled the same way, by these phases (no flag = all, in this order):
#   packages  <app>/packages: pacman (repo) or yay (AUR); <app>/pkg/*/PKGBUILD: makepkg;
#             <app>/keys/FINGERPRINT.asc: signing keys those builds verify, imported first
#   theme     render every <app>/**/*.tmpl and run <app>/render.sh (theme init)
#   link      GNU stow: each <app>'s dot-entries (.config/, .local/, .zshrc …) into $HOME
#   system    copy each <app>/root/** to /** (sudo; owner = owner of the nearest existing dir)
#   setup     <app>/setup.sh: state that isn't a file (services, gsettings, login shell)
#   units     enable every <app>/.config/systemd/user/*.service; start the new ones, restart the
#             running ones whose file changed
# --check     report what differs from the repo (missing links, files in the way, system files);
#             exit 1 on any difference. Changes nothing.
# --home DIR / --root DIR  link / copy into DIR instead of $HOME / / (tests).
# Run as your user, not root: sudo is called only where something must change.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/tools/setup-lib.sh"
home=$HOME root=/
phases=() only=() check=

while (($#)); do
	case $1 in
	--packages | --theme | --link | --system | --setup | --units) phases+=("${1#--}") ;;
	--check) check=1 ;;
	--home) home=$(realpath -m -- "$2") && phases+=(link) && shift ;;
	--root) root=$(realpath -m -- "$2") && phases+=(system) && shift ;;
	--only) shift && while (($#)) && [[ $1 != --* ]]; do only+=("$1") && shift; done && continue ;;
	-h | --help) sed -n '2,16s/^# \{0,1\}//p' "$0" && exit 0 ;;
	*) echo "install.sh: unknown argument $1" >&2 && exit 2 ;;
	esac
	shift
done
((${#phases[@]})) || [[ -n $check ]] || phases=(packages theme link system setup units)
[[ $EUID -ne 0 ]] || { echo "install.sh: run as your user (it calls sudo itself)" >&2 && exit 1; }

say() { printf '==> %s\n' "$*"; }
has() { local p; for p in "${phases[@]}"; do [[ $p == "$1" ]] && return 0; done; return 1; }

# every top-level folder that is an app (it has at least one of the parts below), --only applied
apps() {
	local d name
	for d in "$repo"/*/; do
		name=$(basename "$d")
		[[ -e $d/packages || -d $d/pkg || -e $d/.stow-local-ignore || -d $d/root || -e $d/setup.sh ]] || continue
		if ((${#only[@]})) && [[ " ${only[*]} " != *" $name "* ]]; then continue; fi
		echo "$name"
	done
}

# ---------------------------------------------------------------- packages
# Names in the sync databases go to pacman, the rest to yay (yay-bin is built from the AUR when
# missing). A full -Syu runs first: Arch doesn't support partial upgrades. Local PKGBUILDs (for
# programs neither repo nor AUR packages) are built when their version isn't installed.
# A PKGBUILD that lists validpgpkeys has makepkg check its sources against those keys, which yay
# would otherwise fetch from a public keyserver on every fresh install: when the keyservers are
# down, the install fails. So an app keeps such keys as <app>/keys/FINGERPRINT.asc (the public
# key, checked against a signed release when added), imported into your keyring before any build.
import_keys() {
	local a f fpr
	for a in $(apps); do
		for f in "$repo/$a"/keys/*.asc; do
			[[ -e $f ]] || continue
			fpr=$(basename -- "$f" .asc)
			gpg --batch --list-keys "$fpr" &>/dev/null && continue
			gpg --batch --import "$f" 2>/dev/null
			# the file must hold the key its name promises
			gpg --batch --list-keys "$fpr" &>/dev/null || { echo "install.sh: $f does not hold key $fpr" >&2 && return 1; }
			echo "import  pgp key $fpr ($a)"
		done
	done
}
install_packages() {
	local a all=() repo_pkgs=() aur=() p
	for a in $(apps); do
		[[ -f $repo/$a/packages ]] || continue
		while read -r p; do all+=("$p"); done < <(sed 's/#.*//' "$repo/$a/packages" | tr -s ' \t' '\n' | sed '/^$/d')
	done
	retry sudo pacman -Syu --noconfirm
	import_keys
	declare -A sync
	while read -r p; do sync[$p]=1; done < <(pacman -Slq)
	for p in $(printf '%s\n' "${all[@]}" | sort -u); do
		if [[ -n ${sync[$p]:-} ]]; then repo_pkgs+=("$p"); else aur+=("$p"); fi
	done
	((${#repo_pkgs[@]} == 0)) || retry sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
	if ((${#aur[@]})); then
		if ! command -v yay >/dev/null; then
			local t
			t=$(mktemp -d)
			retry git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$t/yay-bin"
			(cd "$t/yay-bin" && makepkg -si --noconfirm)
			rm -rf -- "$t"
		fi
		retry yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${aur[@]}"
	fi
	local pb info name ver build
	for a in $(apps); do
		for pb in "$repo/$a"/pkg/*/PKGBUILD; do
			[[ -e $pb ]] || continue
			info=$(cd "$(dirname "$pb")" && makepkg --printsrcinfo)
			name=$(awk -F' = ' '/^pkgname = /{print $2; exit}' <<<"$info")
			ver=$(awk -F' = ' '/^\tepoch = /{e=$2":"} /^\tpkgver = /{v=$2} /^\tpkgrel = /{r=$2} END{print e v "-" r}' <<<"$info")
			[[ $(pacman -Q "$name" 2>/dev/null) == "$name $ver" ]] && continue
			build=$(mktemp -d)
			cp -r "$(dirname "$pb")/." "$build"
			# --rmdeps: the build-only tools (makedepends) it installs go again, as yay --removemake
			# does for the AUR
			(cd "$build" && retry makepkg -si --rmdeps --noconfirm --needed)
			rm -rf -- "$build"
		done
	done
}

# ---------------------------------------------------------------- theme
render_theme() { "$repo/theme/.local/bin/theme" init; }

# ---------------------------------------------------------------- link (GNU stow)
# Dirs other programs also write into stay real (--no-folding never folds a dir into a link;
# these are made up front so a fresh home looks like a used one).
shared_dirs=(.config .config/systemd/user .local/bin .local/share .local/state)
stow_packages() { local a; for a in $(apps); do [[ -e $repo/$a/.stow-local-ignore ]] && echo "$a"; done; return 0; }
stow_() { stow --dir="$repo" --target="$home" --no-folding "$@"; }

# Before stowing, clear what stow refuses to replace (it aborts instead of backing up):
#  - a real file where a link goes: moved to <name>.bak.<ts>
#  - a symlink stow doesn't own: removed if it points into the repo, else moved to <name>.bak.<ts>
clear_conflicts() {
	local out line t ts n
	ts=$(date +%s)
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
				echo "install.sh: two apps provide ${line#*different package: }" >&2 && return 1 ;;
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

# links into the repo that point at nothing (a file or an app that was removed)
prune_dangling() {
	local l
	while IFS= read -r -d '' l; do
		[[ $(realpath -m -- "$l") == "$repo"/* ]] || continue
		rm -- "$l" && echo "prune   $l"
	done < <(find "$home" -maxdepth 1 -xtype l -print0 2>/dev/null
		find "$home/.config" "$home/.local" "$home/.claude" -xtype l -print0 2>/dev/null)
}

link() {
	local pkgs d
	mapfile -t pkgs < <(stow_packages)
	((${#pkgs[@]})) || return 0
	for d in "${shared_dirs[@]}"; do mkdir -p "$home/$d"; done
	clear_conflicts "${pkgs[@]}"
	stow_ -R "${pkgs[@]}"
	prune_dangling
	echo "stowed  ${#pkgs[@]} apps into $home"
}

# ---------------------------------------------------------------- system (<app>/root -> /)
# Copies, not links: system services can't read your home. A file is installed only when it
# differs. Its owner (and that of any dir created for it) is the owner of the nearest existing
# dir above it: /etc/* stays root's, /var/lib/<service>/* the service user's. Mode comes from the repo.
as_root() { if [[ -w $root ]]; then "$@"; else sudo "$@"; fi; }
# root's view of a path: you may not be allowed to look (a service's /var/lib dir is often 0700), root always is
root_test() { test "$@" 2>/dev/null || { [[ ! -w $root ]] && sudo test "$@"; }; }

system_files() { # app-relative paths under <app>/root/, templates excluded (their output is used)
	local a f
	for a in $(apps); do
		[[ -d $repo/$a/root ]] || continue
		while IFS= read -r -d '' f; do printf '%s\0' "$a/root/${f#./}"; done < <(cd "$repo/$a/root" && find . \( -type f -o -type l \) ! -name '*.tmpl' -print0)
	done
}

system_dst() { local rel=${1#*/root/}; printf '%s' "${root%/}/$rel"; }

same_file() { # same_file SRC DST: 0 same, 1 differs or missing, 2 can't tell (DST needs root, no sudo)
	if [[ -r $2 ]]; then cmp -s -- "$1" "$2" && return 0 || return 1; fi
	# root can look when sudo works without a password or can prompt on your terminal
	[[ -w $root ]] || sudo -n true 2>/dev/null || (: </dev/tty) 2>/dev/null || return 2
	root_test -e "$2" && as_root cmp -s -- "$1" "$2" && return 0 || return 1
}

install_system() {
	local f src dst dir up owner mode missing
	while IFS= read -r -d '' f; do
		src=$repo/$f dst=$(system_dst "$f")
		same_file "$src" "$dst" && continue
		up=$(dirname "$dst")
		while ! root_test -d "$up"; do up=$(dirname "$up"); done
		owner=$(as_root stat -c %U:%G "$up")
		# create the missing dirs one level at a time, owned like the existing one above them
		dir=$(dirname "$dst")
		while ! root_test -d "$dir"; do
			missing=$dir
			while ! root_test -d "$(dirname "$missing")"; do missing=$(dirname "$missing"); done
			as_root install -d -o "${owner%:*}" -g "${owner#*:}" -m "$(as_root stat -c %a "$up")" -- "$missing"
		done
		mode=$(stat -L -c %a "$src")
		as_root install -o "${owner%:*}" -g "${owner#*:}" -m "$mode" -- "$src" "$dst"
		echo "install $dst"
	done < <(system_files)
}

# ---------------------------------------------------------------- setup, units
run_setup() {
	local a
	for a in $(apps); do
		[[ -x $repo/$a/setup.sh ]] || continue
		say "setup $a"
		"$repo/$a/setup.sh"
	done
}

enable_units() {
	if ! systemctl --user show-environment &>/dev/null; then
		echo "skip    units: no user systemd manager (enable them from a login session)"
		return 0
	fi
	local a f u units=() new=() changed=()
	for a in $(apps); do
		for f in "$repo/$a"/.config/systemd/user/*.service; do [[ -e $f ]] && units+=("$(basename "$f")"); done
	done
	((${#units[@]})) || return 0
	# a unit whose file changed since systemd loaded it runs the old command until it restarts
	for u in "${units[@]}"; do
		[[ $(systemctl --user show -P NeedDaemonReload "$u" 2>/dev/null) == yes ]] && changed+=("$u")
	done
	systemctl --user daemon-reload
	if ((${#changed[@]})); then
		# try-restart: a stopped unit stays stopped
		systemctl --user try-restart "${changed[@]}" 2>/dev/null || true
		echo "restart ${changed[*]}"
	fi
	# enable and start only units not enabled yet: a re-run starts nothing and doesn't bring back
	# a bar hidden with waybar-toggle. Session units refuse to start outside a session (Requisite=).
	for u in "${units[@]}"; do
		[[ $(systemctl --user is-enabled "$u" 2>/dev/null) == enabled ]] || new+=("$u")
	done
	((${#new[@]})) || return 0
	systemctl --user enable "${new[@]}" 2>/dev/null
	echo "enable  ${new[*]}"
	systemctl --user start "${new[@]}" 2>/dev/null || true
}

# ---------------------------------------------------------------- check
check() {
	local bad=0 out f pkgs
	mapfile -t pkgs < <(stow_packages)
	if ((${#pkgs[@]})); then
		out=$(stow_ -n -v "${pkgs[@]}" 2>&1 | grep -E '^LINK:|existing target|cannot stow' || true)
		[[ -z $out ]] || { echo "home: differs from the repo (install.sh --link fixes it):" && printf '  %s\n' "$out" && bad=1; }
	fi
	local unknown=0 rc
	while IFS= read -r -d '' f; do
		rc=0
		same_file "$repo/$f" "$(system_dst "$f")" || rc=$?
		case $rc in
		1) echo "system: $(system_dst "$f") differs from $f" && bad=1 ;;
		2) unknown=$((unknown + 1)) ;;
		esac
	done < <(system_files)
	((unknown == 0)) || echo "note: $unknown system file(s) need root to read; not compared (run --check in a terminal)"
	((bad)) || echo "ok: home and system files match the repo"
	return "$bad"
}

has packages && { say "packages" && install_packages; }
has theme && { say "theme" && render_theme; }
has link && { say "link" && link; }
has system && { say "system" && install_system; }
has setup && run_setup
has units && { say "units" && enable_units; }
if [[ -n $check ]]; then check || exit 1; fi
exit 0

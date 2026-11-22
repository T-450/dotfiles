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
# --check     report what differs from the repo (missing links, files in the way, system files, disabled services);
#             exit 1 on any difference. Changes nothing.
# --home DIR / --root DIR  link / copy into DIR instead of $HOME / / (tests).
# Run as your user, not root: sudo is called only where something must change.
# Each run ends with a summary (per phase: status, time, what changed) and keeps its full output in
# ~/.local/state/dotfiles/install/<UTC time>.log (the last 20 runs). A failed phase stops the run
# and names the command, the line, and the likely cause.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/tools/setup-lib.sh"
home=$HOME root=/
phases=() only=() check=
args=("$@")

while (($#)); do
	case $1 in
	--packages | --theme | --link | --system | --setup | --units) phases+=("${1#--}") ;;
	--check) check=1 ;;
	--home) home=$(realpath -m -- "$2") && phases+=(link) && shift ;;
	--root) root=$(realpath -m -- "$2") && phases+=(system) && shift ;;
	--only) shift && while (($#)) && [[ $1 != --* ]]; do only+=("$1") && shift; done && continue ;;
	-h | --help) sed -n '2,19s/^# \{0,1\}//p' "$0" && exit 0 ;;
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
			# on disk, as yay builds in ~/.cache/yay: /tmp is RAM (half of it, and a per-user quota),
			# which a build like helix-gj1118's (grammar sources and cargo's output, several GB)
			# outgrows on a small machine
			mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
			build=$(mktemp -d -p "${XDG_CACHE_HOME:-$HOME/.cache}" makepkg.XXXXXX)
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
# Units setup.sh would enable, without running it (that needs sudo). A continued
# enable_system line is joined first; a leading --boot is not a unit.
system_units() {
	local a line buf rest u skip
	local -a units
	for a in $(apps); do
		[[ -f $repo/$a/setup.sh ]] || continue
		buf=
		while IFS= read -r line || [[ -n $line ]]; do
			line=${line%%#*}
			line=${line%"${line##*[![:space:]]}"}
			if [[ $line == *\\ ]]; then
				buf+="${line%\\} "
				continue
			fi
			line=$buf$line
			buf=
			[[ $line =~ ^[[:space:]]*enable_system([[:space:]]|$) ]] || continue
			rest=${line#*enable_system}
			read -ra units <<<"$rest" || true
			skip=1
			for u in "${units[@]}"; do
				if ((skip)) && [[ $u == --boot ]]; then
					skip=0
					continue
				fi
				skip=0
				printf '%s\t%s\n' "$a" "$u"
			done
		done <"$repo/$a/setup.sh"
	done
}

check() {
	local bad=0 out f pkgs a u state
	# an app with dot-entries but no .stow-local-ignore is never stowed, and stow then sees nothing to
	# compare: name it (copy any app's .stow-local-ignore into it)
	for a in $(apps); do
		[[ -e $repo/$a/.stow-local-ignore ]] && continue
		compgen -G "$repo/$a/.[!.]*" >/dev/null || continue
		for f in "$repo/$a"/.[!.]*; do
			case ${f##*/} in .gitignore | .stow-local-ignore) continue ;; esac
			echo "home: $a has ${f##*/} but no .stow-local-ignore, so install.sh --link skips it" && bad=1 && break
		done
	done
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
	if [[ $root == / && -d /run/systemd/system ]] && command -v systemctl >/dev/null; then
		while IFS=$'\t' read -r a u; do
			state=$(systemctl is-enabled "$u" 2>/dev/null || true)
			if [[ $state != enabled ]]; then
				echo "service: $u is ${state:-unknown} (install.sh --setup --only $a fixes it)"
				bad=1
			fi
		done < <(system_units)
	fi
	((bad)) || echo "ok: home and system files match the repo"
	return "$bad"
}

# ---------------------------------------------------------------- run log, summary, troubleshooting
# Every phase's output is also written to the run log, so a failure can be read after the terminal is
# gone. pacman and yay then write to a pipe, not a terminal: lines instead of progress bars, as in CI.
# Lines the summary adds start with "==>" or a space, never with a verb, so desktop-vm's check that a
# second run changes nothing (its CHANGED pattern) and the tests still read only the action lines.
order=(packages theme link system setup units)
declare -A fn=([packages]=install_packages [theme]=render_theme [link]=link [system]=install_system
	[setup]=run_setup [units]=enable_units)
declare -A status=() took=() changes=()
log_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/install
log='' trace=''

# Known failures, most specific first: PHASE (or *) @@ extended regex over the failed phase's last
# output lines @@ what to do. Every hint that matches is shown.
hints=(
	'packages@@unable to lock database@@another pacman is running, or one died: pgrep -a pacman; if none, sudo rm /var/lib/pacman/db.lck'
	'packages@@signature from .* is (unknown trust|invalid)|invalid or corrupted package \(PGP signature\)@@the keyring is older than the packages: sudo pacman -Sy archlinux-keyring, then run again'
	'packages@@One or more PGP signatures could not be verified|unknown public key@@a PKGBUILD source key is missing: keep it as <app>/keys/FINGERPRINT.asc (see the packages section of install.sh)'
	'packages@@[Cc]ould not resolve host|failed retrieving file|Operation too slow|Connection timed out|Failed to connect@@no network or a dead mirror: check the network, then /etc/pacman.d/mirrorlist'
	'packages@@exists in filesystem@@a file no package owns is in the way: pacman -Qo PATH; move it aside, then run again'
	'packages@@target not found|No AUR package found@@a package left the repos or the AUR: find its new name (pacman -Ss, yay -Ss) and fix that app'"'"'s packages file'
	'packages@@conflicting dependencies|are in conflict@@two packages conflict: pacman -Qi NAME shows Conflicts With; drop one from its packages file'
	'*@@No space left on device@@a disk is full: df -h (/tmp is RAM; builds go to ~/.cache)'
	'*@@a password is required|a terminal is required to read the password@@sudo needs a password: run install.sh from a terminal'
	'*@@command not found@@a program is missing: ./install.sh --packages first'
	'*@@Permission denied@@a path is not writable: ls -ld it; install.sh runs as your user and calls sudo only for root/'
	'link@@two apps provide@@two app folders ship the same file: keep it in one of them'
	'link@@cannot stow|existing target@@./install.sh --check lists what is in the way'
	'theme@@[Pp]alette|tmpl|KeyError|Traceback@@a template or palette is broken: theme lint names it'
	'units@@Failed to (enable|start)|not found@@systemctl --user status UNIT and journalctl --user -b -u UNIT show why'
)

now() { printf '%s' "${EPOCHREALTIME/[.,]/}"; } # microseconds
human() { # human MICROSECONDS
	local us=$1 s=$(($1 / 1000000))
	if ((s >= 60)); then printf '%dm%02ds' $((s / 60)) $((s % 60)); else printf '%d.%01ds' "$s" $((us / 100000 % 10)); fi
}

open_log() {
	mkdir -p "$log_dir"
	log=$log_dir/$(date -u +%Y-%m-%dT%H-%M-%SZ).log
	trace=$(mktemp)
	{
		printf 'install.sh %s\n' "${args[*]:-(all phases)}"
		printf 'repo %s (%s)\nhost %s, kernel %s\n' "$repo" "$(git -C "$repo" describe --always --dirty 2>/dev/null || echo 'no git')" \
			"$(uname -n)" "$(uname -r)"
	} >"$log"
	# keep the last 20 runs
	find "$log_dir" -maxdepth 1 -name '*.log' -printf '%f\n' | sort -r | tail -n +21 | sed "s|^|$log_dir/|" | xargs -r rm --
}

# action lines (a lowercase verb, then spaces): the ones every run prints aren't changes
# count_changes FILE: "install 2, enable 1". Only the repo's action verbs (the ones desktop-vm's
# second-run check counts): the rest is pacman, yay and npm talking.
count_changes() {
	grep -oE '^(install|backup|unlink|prune|enable|gsettings|render|linger|xdg|rebuild|config|link|mkdir) ' "$1" |
		sort | uniq -c | sort -rn | awk '{printf "%s%s %s", (NR > 1 ? ", " : ""), $2, $1}'
}

# packages: pacman's own output is too noisy to count, so compare what is installed before and after
package_delta() { # package_delta BEFORE AFTER: "installed 2, upgraded 5, removed 1"
	local new up gone
	new=$(join -v2 <(cut -d' ' -f1 "$1") <(cut -d' ' -f1 "$2") | wc -l)
	gone=$(join -v1 <(cut -d' ' -f1 "$1") <(cut -d' ' -f1 "$2") | wc -l)
	up=$(join "$1" "$2" | awk '$2 != $3' | wc -l)
	local out=()
	((new == 0)) || out+=("installed $new")
	((up == 0)) || out+=("upgraded $up")
	((gone == 0)) || out+=("removed $gone")
	local IFS=,
	printf '%s' "${out[*]}" | sed 's/,/, /g'
}

# link: stow is silent, so count the links into the repo before and after
repo_links() {
	{ find "$home" -maxdepth 1 -type l -print0 2>/dev/null
		find "$home/.config" "$home/.local" "$home/.claude" -type l -print0 2>/dev/null; } |
		xargs -0 -r realpath -m -- | grep -c "^$repo/" || true
}

troubleshoot() { # troubleshoot PHASE OUTPUT: the hints whose pattern is in the last 60 lines
	local h p re msg tail n=0
	tail=$(tail -n 60 -- "$2")
	for h in "${hints[@]}"; do
		p=${h%%@@*} re=${h#*@@} msg=${re#*@@} re=${re%%@@*}
		[[ $p == '*' || $p == "$1" ]] || continue
		grep -qE -- "$re" <<<"$tail" || continue
		printf '   hint: %s\n' "$msg"
		n=$((n + 1))
	done
	local app
	case $1 in
	setup)
		app=$(sed -n 's/^==> setup //p' "$2" | tail -1)
		printf '   hint: run %s alone to see each step: bash -x %s/setup.sh\n' "${app:-the app}" "${app:-<app>}" ;;
	*) ((n)) || printf '   hint: no known cause; the lines above and the log show the error\n' ;;
	esac
}

# ERR trap: the first failure wins (an inner one is the precise one; its callers fail after it)
on_err() {
	local rc=$?
	[[ -s $trace ]] || printf '%s\t%s\t%s\t%s\t%s\n' "$rc" "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" \
		"${FUNCNAME[1]:-main}" "$BASH_COMMAND" >"$trace"
}

# run_phase NAME N TOTAL: run the phase in a subshell with errexit and an ERR trap that records
# the first failing command, its exit code and where it ran; tee its output to the terminal and
# the log. Called with errexit off (main turns it off around the call).
run_phase() {
	local name=$1 out before after start rc first file line func cmd src
	out=$(mktemp)
	printf '==> [%d/%d] %s\n' "$2" "$3" "$name"
	local links=0
	# before is set here, not in the redirection: bash expands an external command's redirection
	# in the forked child, so an assignment there never reaches this shell
	[[ $name != packages ]] || { before=$(mktemp) && pacman -Q >"$before" 2>/dev/null; } || true
	[[ $name != link ]] || links=$(repo_links)
	start=$(now)
	(
		set -eE
		trap on_err ERR
		"${fn[$name]}"
	) 2>&1 | tee "$out"
	rc=${PIPESTATUS[0]}
	took[$name]=$(($(now) - start))
	{ printf '\n### %s (exit %s, %s)\n' "$name" "$rc" "$(human "${took[$name]}")" && cat -- "$out"; } >>"$log"
	if [[ $name == packages && -s ${before:-} ]]; then
		after=$(mktemp)
		pacman -Q >"$after" 2>/dev/null || true
		changes[$name]=$(package_delta "$before" "$after")
		rm -f -- "$before" "$after"
	else
		changes[$name]=$(count_changes "$out")
	fi
	if [[ $name == link ]]; then
		links=$(($(repo_links) - links))
		((links == 0)) || changes[$name]="$( ((links > 0)) && echo "linked $links" || echo "unlinked $((-links))")${changes[$name]:+, ${changes[$name]}}"
	fi
	if ((rc == 0)); then
		status[$name]=ok
		printf '   ok in %s%s\n' "$(human "${took[$name]}")" "${changes[$name]:+: ${changes[$name]}}"
		rm -f -- "$out"
		return 0
	fi
	if ((rc == 130)); then
		status[$name]=interrupted
	else
		status[$name]=failed
	fi
	{
		printf '\n==> %s %s (exit %s)\n' "$name" "${status[$name]}" "$rc"
		if [[ -s $trace ]]; then
			IFS=$'\t' read -r first file line func cmd <"$trace"
			# BASH_COMMAND is only `return 1` when a function failed; the source line names the call
			src=$(sed -n "${line}{s/^[[:space:]]*//;p}" "$file" 2>/dev/null)
			printf '   command: %s\n   at %s:%s, in %s (exit %s)\n' "${src:-$cmd}" "${file##*/}" "$line" "$func" "$first"
		fi
		((rc == 130)) || troubleshoot "$name" "$out"
	} | tee -a "$log" >&2
	rm -f -- "$out"
	return "$rc"
}

summary() { # summary START RC
	local p total=$(($(now) - $1)) state
	case $2 in 0) state=ok ;; 130) state=interrupted ;; *) state="failed (exit $2)" ;; esac
	printf '\n==> summary: %s in %s\n' "$state" "$(human "$total")"
	printf '   %-9s %-11s %7s  %s\n' phase status time changes
	for p in "${order[@]}"; do
		has "$p" || continue
		printf '   %-9s %-11s %7s  %s\n' "$p" "${status[$p]:-not run}" \
			"$([[ -n ${took[$p]:-} ]] && human "${took[$p]}" || echo -)" "${changes[$p]:-${status[$p]:+none}}"
	done
	printf '   log: %s\n' "$log"
}

main() {
	local p n=0 total=0 start rc=0
	if ((${#phases[@]})); then
		for p in "${order[@]}"; do has "$p" && total=$((total + 1)); done
		open_log
		start=$(now)
		# Ctrl+C: the phase's subshell resets the trap and dies (so retry() can't run yay again);
		# this shell waits for it, then reports the phase as interrupted and prints the summary
		trap : INT
		for p in "${order[@]}"; do
			has "$p" || continue
			n=$((n + 1))
			# not `run_phase || …`: bash ignores errexit in anything called from a condition, the
			# phase's own `set -e` included, so a failing step would not stop the phase
			set +e
			run_phase "$p" "$n" "$total"
			rc=$?
			set -e
			((rc == 0)) || break
		done
		summary "$start" "$rc" | tee -a "$log"
		rm -f -- "$trace"
		((rc == 0)) || exit "$rc"
	fi
	if [[ -n $check ]]; then check || exit 1; fi
	exit 0
}
main

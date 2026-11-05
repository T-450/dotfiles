#!/usr/bin/env bash
# firefox/setup.sh: palette-colored chrome in the profile Firefox uses (idempotent).
# The profile in use is the first install's Default= in installs.ini (profiles.ini's Default=1
# can be a stale one). Its path is per machine, so it is linked here, not by stow. A real
# user.js/userChrome.css there is moved to <name>.bak.<ts>, never deleted.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
ff=${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox
if [[ ! -e $ff/installs.ini && -e $HOME/.mozilla/firefox/installs.ini ]]; then
	echo "note    firefox profile is in ~/.mozilla (pre-XDG); theme it by hand or migrate the profile"
fi
prof=$(awk -F= '/^Default=/{print $2; exit}' "$ff/installs.ini" 2>/dev/null || true)
if [[ -z $prof || ! -d $ff/$prof ]]; then
	echo "skip    firefox: no profile yet (start Firefox once, then re-run install.sh --setup)"
	exit 0
fi
link_file() { # link_file SRC DST
	local src=$1 dst=$2
	[[ -L $dst && $(readlink -- "$dst") == "$src" ]] && return 0
	if [[ -L $dst ]]; then rm -- "$dst"; elif [[ -e $dst ]]; then mv -- "$dst" "$dst.bak.$(date +%s)" && echo "backup  $dst"; fi
	mkdir -p "$(dirname "$dst")"
	ln -s -- "$src" "$dst" && echo "linked  $dst"
}
link_file "$repo/firefox/chrome/userChrome.css" "$ff/$prof/chrome/userChrome.css"
link_file "$repo/firefox/user.js" "$ff/$prof/user.js"

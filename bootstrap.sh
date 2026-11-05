#!/usr/bin/env bash
# bootstrap.sh: a fresh Arch Linux install -> this desktop, in one command:
#   curl -fsSL https://raw.githubusercontent.com/T-450/dotfiles/main/bootstrap.sh | bash
# Clones the repo to ~/dotfiles (DOTFILES=dir to change it; a checkout it runs from is used as is),
# asks once for the GitHub sign-in that runner-up (CI) serves through, then runs install.sh.
# Run as your user (in wheel); sudo asks for your password.
set -euo pipefail
die() { echo "bootstrap: $*" >&2 && exit 1; }
[[ $EUID -ne 0 ]] || die "run as your user, not root"
command -v pacman >/dev/null || die "this is for Arch Linux"

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-/}")" 2>/dev/null && pwd -P || true)
if [[ -n $here && -x $here/install.sh && -d $here/.git ]]; then
	dir=$here # run from a checkout (CI, or a clone you made): use it as it is
else
	dir=${DOTFILES:-$HOME/dotfiles}
fi

sudo pacman -Syu --needed --noconfirm git github-cli
if [[ ! -d $dir/.git ]]; then
	git clone https://github.com/T-450/dotfiles.git "$dir"
elif [[ $dir != "$here" ]]; then
	git -C "$dir" pull --ff-only
fi

# runner-up.service serves CI jobs through gh's sign-in; it stays off until this is done
if ! gh auth status &>/dev/null && [[ -z ${CI:-} ]] && (: </dev/tty) 2>/dev/null; then
	gh auth login </dev/tty || echo "bootstrap: skipped GitHub sign-in (run gh auth login later)"
fi

exec "$dir/install.sh"

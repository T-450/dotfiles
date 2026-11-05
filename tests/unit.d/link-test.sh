#!/usr/bin/env bash
# install.sh --link on fixture packages: fresh home, re-run, conflicts, old-layout links, pruning.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_command stow
scratch_home

# a fake repo: install.sh + three packages shaped like the real ones
repo=$TEST_TMP/repo
mkdir -p "$repo"
cp "$ROOT/install.sh" "$repo/"
mk() { mkdir -p "$(dirname "$repo/$1")" && printf '%s\n' "${2:-$1}" >"$repo/$1"; }
for p in foot bar zsh; do cp "$ROOT/tests/fixtures/stow-local-ignore" "$repo/$p/.stow-local-ignore" 2>/dev/null ||
	{ mkdir -p "$repo/$p" && cp "$ROOT/tests/fixtures/stow-local-ignore" "$repo/$p/.stow-local-ignore"; }; done
mk foot/.config/foot/foot.ini
mk foot/.config/foot/colors.ini.tmpl
mk foot/.config/foot/colors.ini
mk foot/packages
mk foot/setup.sh
mk foot/files/user.js
mk foot/.gitignore
mk foot/agent-theme.sh
mk foot/etc/tlp.d/x.conf
mk foot/palettes/dark.toml
mk bar/.config/systemd/user/bar.service
mk bar/.local/bin/barcmd
mk zsh/.zshrc
view() { (cd "$HOME" && find . -mindepth 1 \( -type l -printf '%p -> %l\n' \) -o \( -type d -printf '%p/\n' \) -o -printf '%p FILE\n' | sort); }
run() { "$repo/install.sh" --home "$HOME"; }

out=$(run) || fail "fresh home links" "$out"
[[ -L $HOME/.config/foot/foot.ini && -d $HOME/.config/foot && ! -L $HOME/.config/foot ]] ||
	fail "app dir is a real dir, its files are links (--no-folding)" "$(view)"
[[ $(cat "$HOME/.config/foot/foot.ini") == foot/.config/foot/foot.ini ]] || fail "link resolves to the package file"
[[ -L $HOME/.zshrc && -L $HOME/.local/bin/barcmd && -L $HOME/.config/systemd/user/bar.service ]] ||
	fail "dot-entries, ~/.local/bin and units link" "$(view)"
[[ -L $HOME/.config/foot/colors.ini && ! -e $HOME/.config/foot/colors.ini.tmpl ]] ||
	fail "rendered output links, its template doesn't" "$(view)"
for x in packages setup.sh files .gitignore .stow-local-ignore agent-theme.sh etc palettes; do
	[[ ! -e $HOME/$x ]] || fail "package metadata stays out of the home: $x"
done
[[ $(readlink "$HOME/.zshrc") != /* ]] || fail "links are relative"
pass "fresh home: real dirs, file links, metadata and templates ignored"

before=$(view)
out=$(run) || fail "second run" "$out"
[[ $(view) == "$before" ]] || fail "second run changes nothing" "$(diff <(echo "$before") <(view))"
! grep -qE '^(backup|unlink|prune) ' <<<"$out" || fail "second run moves nothing" "$out"
pass "second run is a no-op"

rm "$HOME/.config/foot/foot.ini" && echo mine >"$HOME/.config/foot/foot.ini"
out=$(run) || fail "real file in the way" "$out"
[[ -L $HOME/.config/foot/foot.ini ]] || fail "link replaces the real file"
bak=$(compgen -G "$HOME/.config/foot/foot.ini.bak.*") && [[ $(cat "$bak") == mine ]] ||
	fail "real file kept as .bak.<ts>" "$(view)"
rm "$bak"
pass "a real file in the way is backed up, never deleted"

# today's layout: a whole-dir link into the repo (here: to a path that no longer exists)
rm -r "$HOME/.config/foot" && ln -s "$repo/oldlayout/foot" "$HOME/.config/foot"
out=$(run) || fail "old-layout dir link" "$out"
[[ -d $HOME/.config/foot && ! -L $HOME/.config/foot && -L $HOME/.config/foot/foot.ini ]] ||
	fail "old repo link replaced by a real dir" "$(view)"
! compgen -G "$HOME/.config/foot.bak.*" >/dev/null || fail "an old repo link is removed, not backed up"
pass "an old-layout link into the repo is replaced"

# today's layout, the other shape: an absolute link to an existing dir, here a package root
rm -r "$HOME/.config/foot" && ln -s "$repo/foot" "$HOME/.config/foot"
out=$(run) || fail "old-layout link to a package root" "$out"
[[ -d $HOME/.config/foot && ! -L $HOME/.config/foot && -L $HOME/.config/foot/foot.ini ]] ||
	fail "a link to a package root is replaced by a real dir" "$(view)"
[[ ! -e $HOME/.config/foot/packages && ! -e $HOME/.config/foot/.config ]] || fail "no package root content leaks in" "$(view)"
pass "an old-layout link to an existing package root is replaced"

ln -sfn /etc/hostname "$HOME/.config/foot/foot.ini"
out=$(run) || fail "foreign link in the way" "$out"
bak=$(compgen -G "$HOME/.config/foot/foot.ini.bak.*") && [[ $(readlink "$bak") == /etc/hostname ]] ||
	fail "a link to outside the repo is backed up" "$(view)"
rm "$bak"
pass "a foreign link in the way is backed up"

ln -s "$repo/foot/.config/foot/gone.ini" "$HOME/.config/foot/gone.ini"
ln -s /nonexistent "$HOME/.config/foreign-dangling"
rm "$repo/zsh/.zshrc"
out=$(run) || fail "pruning run" "$out"
[[ ! -L $HOME/.config/foot/gone.ini && ! -L $HOME/.zshrc ]] || fail "dangling repo links are pruned" "$(view)"
[[ -L $HOME/.config/foreign-dangling ]] || fail "dangling links outside the repo are left alone"
pass "dangling links into the repo are pruned, others kept"

mk zsh/.config/foot/foot.ini
if out=$(run 2>&1); then fail "two packages providing one file must fail" "$out"; fi
pass "two packages claiming one path fail the run"

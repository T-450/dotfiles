#!/usr/bin/env bash
# tests/lib.sh: sourced by every tests/unit.d/*-test.sh (the protocol Omarchy's test/shell.d uses).
#   pass DESC          ok - DESC
#   skip DESC          ok - DESC # SKIP   (say why; the file goes on)
#   fail DESC [DETAIL] DETAIL + `not ok - DESC` on stderr, then the file exits: later checks
#                      would only report against state the failure already broke
#   require_command C  fail the file when a tool is missing
#   require_session    skip the file (exit 0) unless a live mango session answers
#   scratch_home       export HOME=<fresh dir>; XDG_* are unset so nothing reaches the real home
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	echo "source tests/lib.sh from a test; don't run it" >&2
	exit 1
fi
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export ROOT
# a session exports these; unset, they follow HOME, so a scratch HOME can't leak into the real one
unset XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME CLAUDE_CONFIG_DIR

pass() { printf 'ok - %s\n' "$1"; }
skip() { printf 'ok - %s # SKIP\n' "$1"; }
fail() {
	[[ -n ${2:-} ]] && printf '%s\n' "$2" >&2
	printf 'not ok - %s\n' "$1" >&2
	exit 1
}
require_command() { command -v "$1" >/dev/null || fail "needs $1" "install it: $1 is missing"; }
require_session() {
	# WAYLAND_DISPLAY alone only proves the variable was inherited: ask mango itself
	if [[ -z ${MANGO_INSTANCE_SIGNATURE:-} ]] || ! timeout 3 mmsg get all-monitors >/dev/null 2>&1; then
		skip "${1:-needs a live mango session}"
		exit 0
	fi
}
scratch_home() {
	TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
	trap 'rm -rf -- "$TEST_TMP"' EXIT
	export HOME=$TEST_TMP/home
	mkdir -p "$HOME"
	# identity tags ({{git_name}} …) come from the environment here, never from a prompt
	export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
}

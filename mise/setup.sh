#!/usr/bin/env bash
# mise/setup.sh: install the tools ~/.config/mise/config.toml requests, at the exact versions and
# checksums mise.lock pins (--locked: no version lookups), then delete versions nothing uses.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
# global config only: mise loads config from the working directory upward, so a mise.toml or
# .nvmrc in $HOME or the caller's directory would join in; MISE_ENV would add mise.<env>.toml
cd /
unset MISE_ENV
missing=$(mise ls --global --missing --no-header | awk '{printf "%s@%s ", $1, $2}')
if [[ -n $missing ]]; then
	echo "install mise: ${missing% }"
	retry mise install --locked
fi
if ! mise prune --tools --dry-run-code >/dev/null 2>&1; then
	mise prune --tools --yes >/dev/null
	echo "prune   unused mise tool versions"
fi

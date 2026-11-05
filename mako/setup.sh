#!/usr/bin/env bash
# mako/setup.sh: mako replaces swaync; its packaged user unit is bound to graphical-session.target.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
remove_pkgs swaync
if user_bus && [[ $(systemctl --user is-enabled mako.service 2>/dev/null) != enabled ]]; then
	systemctl --user enable mako.service
fi

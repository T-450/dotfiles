#!/usr/bin/env bash
# opencode/setup.sh: install the palette theme and select it in cli.json, only while no theme was
# chosen there. cli.json stays opencode's own file (not linked): opencode rewrites it from /themes,
# and ~/.config/opencode also holds service.json (a password) that must never reach the repo.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
. "$root/theme/agent-theme.sh"
opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
have opencode "$opencode" || { echo "skip    opencode: not installed" && exit 0; }
"$root/opencode/reload.sh"
state=${XDG_STATE_HOME:-$HOME/.local/state}/opencode
if [[ ! -e $opencode/cli.json && ( -e $opencode/tui.json || -e $state/kv.json ) ]]; then
	# opencode 2.x migrates tui.json/kv.json only while cli.json doesn't exist yet;
	# creating it first would drop those settings. Let opencode migrate, then re-run.
	echo "skip    opencode theme: start opencode once (it migrates tui.json), then re-run install.sh --setup"
	exit 0
fi
# opencode 2.x cli.json holds {"theme": {"name": ..., "mode": ...}}; keep an existing mode
select_theme "$opencode/cli.json" 600 \
	'(.theme | if type == "object" then .name else null end) == null' \
	'.theme = ((.theme | objects) // {}) + {name: $v}' mango

#!/usr/bin/env bash
# claude/setup.sh: install the palette theme and select it, only where no theme was ever chosen
# ("theme" unset; "auto" is a real choice in Claude Code's /theme menu). Idempotent.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
. "$root/theme/agent-theme.sh"
claude=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
have claude "$claude" || { echo "skip    claude: not installed" && exit 0; }
"$root/claude/reload.sh"
select_theme "$claude/settings.json" 600 '.theme == null' '.theme = $v' custom:mango

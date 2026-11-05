#!/usr/bin/env bash
# claude/reload.sh: copy the palette's Claude Code theme into ~/.claude/themes (run by `theme set`).
# Running sessions hot-reload it. Skipped when Claude Code isn't installed or configured.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
. "$root/theme/agent-theme.sh"
claude=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
have claude "$claude" || exit 0
put "$root/claude/theme.json" "$claude/themes/mango.json"

#!/usr/bin/env bash
# agents.sh [--activate]: install the palette's Claude Code and opencode themes (run by `theme set`)
# Copied, not linked: Claude Code watches ~/.claude/themes and hot-reloads a changed file,
# which it would not see behind a symlink. opencode reads its theme at startup.
# --activate (link.sh) also selects them, but only where no theme was chosen yet:
# Claude Code's theme unset or "auto", opencode's unset.
set -euo pipefail
root=${THEME_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
claude=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode

put() { # put <src> <dst>: atomic copy
	mkdir -p "$(dirname "$2")"
	local tmp
	tmp=$(mktemp "$2.XXXXXX")
	cp "$1" "$tmp"
	chmod 644 "$tmp"
	mv "$tmp" "$2"
}
put "$root/theme/out/claude.json"   "$claude/themes/mango.json"
put "$root/theme/out/opencode.json" "$opencode/themes/mango.json"

[[ ${1:-} == --activate ]] || exit 0

select_theme() { # select_theme <json file> <jq condition: no theme chosen yet> <jq update> <value>
	local f=$1 cond=$2 update=$3 value=$4 tmp
	[[ -f $f ]] || echo '{}' >"$f"
	jq -e "$cond" "$f" >/dev/null || return 0
	tmp=$(mktemp "$f.XXXXXX")
	jq --arg v "$value" "$update" "$f" >"$tmp"
	chmod --reference="$f" "$tmp"
	mv "$tmp" "$f"
	echo "theme   $f -> $value"
}
select_theme "$claude/settings.json" '.theme == null or .theme == "auto"' '.theme = $v' custom:mango
# opencode 2.x: cli.json holds {"theme": {"name": ..., "mode": ...}} (migrated from
# tui.json's flat "theme"); keep an existing mode
select_theme "$opencode/cli.json" '(.theme | if type == "object" then .name else null end) == null' \
	'.theme = ((.theme | objects) // {}) + {name: $v}' mango

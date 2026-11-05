#!/usr/bin/env bash
# agents.sh [--activate]: install the palette's Claude Code and opencode themes (run by `theme set`)
# Copied, not linked: Claude Code watches ~/.claude/themes and hot-reloads a changed file,
# which it would not see behind a symlink. opencode reads its theme at startup.
# --activate (link.sh) also selects them, only where no theme was ever chosen:
# Claude Code's "theme" unset, opencode's unset. Apps that aren't installed are skipped.
set -euo pipefail
root=${THEME_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)}
claude=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
tmp=
trap '[[ -n $tmp ]] && rm -f -- "$tmp"' EXIT

have() { # have <command> <config dir>: installed or already configured
	command -v "$1" >/dev/null || [[ -d $2 ]]
}

put() { # put <src> <dst>: atomic copy
	mkdir -p "$(dirname "$2")"
	tmp=$(mktemp "$2.XXXXXX")
	cp "$1" "$tmp"
	chmod 644 "$tmp"
	mv "$tmp" "$2"
	tmp=
}

select_theme() { # select_theme <json file> <new-file mode> <jq: no theme chosen> <jq update> <value>
	local f=$1 mode=$2 cond=$3 update=$4 value=$5
	# write through a symlink (settings kept in a dotfiles repo) instead of replacing it
	[[ -e $f ]] && f=$(readlink -f -- "$f")
	if [[ ! -e $f ]]; then
		mkdir -p "$(dirname "$f")"
		(umask 077 && echo '{}' >"$f")
		chmod "$mode" "$f"
	fi
	# unreadable/invalid JSON: leave it alone
	jq -e "$cond" "$f" >/dev/null 2>&1 || return 0
	tmp=$(mktemp "$f.XXXXXX")
	jq --arg v "$value" "$update" "$f" >"$tmp"
	chmod --reference="$f" "$tmp"
	mv "$tmp" "$f"
	tmp=
	echo "theme   $f -> $value"
}

if have claude "$claude"; then
	put "$root/theme/out/claude.json" "$claude/themes/mango.json"
	if [[ ${1:-} == --activate ]]; then
		# null only: "auto" is a real choice in Claude Code's /theme menu
		select_theme "$claude/settings.json" 600 '.theme == null' '.theme = $v' custom:mango
	fi
fi

if have opencode "$opencode"; then
	put "$root/theme/out/opencode.json" "$opencode/themes/mango.json"
	if [[ ${1:-} == --activate ]]; then
		state=${XDG_STATE_HOME:-$HOME/.local/state}/opencode
		if [[ ! -e $opencode/cli.json && ( -e $opencode/tui.json || -e $state/kv.json ) ]]; then
			# opencode 2.x migrates tui.json/kv.json only while cli.json doesn't exist yet;
			# creating it first would drop those settings. Let opencode migrate, then re-run.
			echo "skip    opencode theme: start opencode once (it migrates tui.json), then re-run link.sh"
		else
			# opencode 2.x cli.json holds {"theme": {"name": ..., "mode": ...}}; keep an existing mode
			select_theme "$opencode/cli.json" 600 \
				'(.theme | if type == "object" then .name else null end) == null' \
				'.theme = ((.theme | objects) // {}) + {name: $v}' mango
		fi
	fi
fi

# theme/agent-theme.sh: helpers for apps whose theme is a file the app owns (Claude Code, opencode).
# Sourced by claude/{reload,setup}.sh and opencode/{reload,setup}.sh.
# Copied, not linked: Claude Code watches ~/.claude/themes and hot-reloads a changed file,
# which it would not see behind a symlink. opencode reads its theme at startup.
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

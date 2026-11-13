#!/usr/bin/env bash
# pi/setup.sh: Pi's extensions (the LazyPi catalog), its theme pair (the repo's palettes, rendered
# into ~/.pi/agent/themes) and its Anthropic key source. Pi writes settings.json and auth.json
# itself (/settings, /login, pi install), so the repo sets only these keys in them.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
agent=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
lazypi=@robzolkos/lazypi@0.6.6
mkdir -p "$agent"

# set_json FILE MODE [JQ_ARGS...] JQ_FILTER: rewrite FILE through jq when the filter changes it
# (created as {})
set_json() {
	local file=$1 mode=$2 new
	shift 2
	[[ -e $file ]] || (umask 077 && echo '{}' >"$file")
	new=$(jq --tab "$@" "$file")
	[[ $new == "$(jq --tab . "$file")" ]] && return 1
	printf '%s\n' "$new" >"$file.tmp" && chmod "$mode" "$file.tmp" && mv "$file.tmp" "$file"
}

# LazyPi installs every catalog package through `pi install` (it skips the ones Pi already has);
# it runs again only when the pinned version changes. Node is mise's (cd /: global config only).
catalog() { (cd / && unset MISE_ENV && mise exec node -- npx -y "$lazypi" --yes) && echo "lazypi  $lazypi catalog"; }
when_changed "$repo/pi/lazypi.stamp" catalog <<<"$lazypi"

# light-2026/dark-2026: Pi picks one by the terminal's background, which follows `theme set`
if set_json "$agent/settings.json" 644 '.theme = "light-2026/dark-2026"'; then
	echo "pi      theme light-2026/dark-2026"
fi
# the curated theme pack ships some palettes of its own (catppuccin-mocha): leave those to ours, so
# Pi loads one theme per name instead of reporting a collision at every start
curated=npm:@victor-software-house/pi-curated-themes
mine=$(for f in "$repo"/theme/palettes/*.toml; do f=${f##*/}; printf '!themes/%s.json\n' "${f%.toml}"; done | jq -R . | jq -sc .)
if set_json "$agent/settings.json" 644 --arg src "$curated" --argjson ex "$mine" \
	'.packages |= map(if (. == $src) or (type == "object" and .source == $src) then {source: $src, themes: $ex} else . end)'; then
	echo "pi      curated themes: ours take the palette names"
fi
# the key itself stays in ~/.config/zsh/private.zsh (exports $ANTHROPIC_API); Pi runs this command
# when it first needs the key. A key saved by /login is left alone.
if set_json "$agent/auth.json" 600 '.anthropic //= {"type": "api_key", "key": "!printenv ANTHROPIC_API"}'; then
	echo "pi      anthropic key from \$ANTHROPIC_API"
fi

#!/usr/bin/env bash
# btop/setup.sh: btop draws in mango.theme, the palette's render (color_theme in
# ~/.config/btop/btop.conf). btop rewrites the whole file when its options change or its version
# moves, so the repo can't link it: only color_theme is set, when it differs.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
conf=$HOME/.config/btop/btop.conf
want='color_theme = "mango"'
grep -qxF -- "$want" "$conf" 2>/dev/null && exit 0
mkdir -p "${conf%/*}"
if grep -q '^color_theme = ' "$conf" 2>/dev/null; then
	sed -i "s|^color_theme = .*|$want|" "$conf"
else
	printf '%s\n' "$want" >> "$conf"
fi
echo "config  btop color_theme"

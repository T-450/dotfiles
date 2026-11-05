#!/usr/bin/env bash
# opencode/reload.sh: copy the palette's opencode theme into ~/.config/opencode/themes (run by
# `theme set`); opencode reads it at its next start. Skipped when opencode isn't installed.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
. "$root/theme/agent-theme.sh"
opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
have opencode "$opencode" || exit 0
put "$root/opencode/theme.json" "$opencode/themes/mango.json"

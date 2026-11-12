#!/usr/bin/env bash
# thunar/reload.sh: restart the Thunar daemon so its windows get the new colors (run by `theme set`).
# GTK reads gtk.css once per process and every Thunar window belongs to the daemon, so only a
# restart recolors it. A restart closes Thunar's windows and stops their copies: with one open, or
# when mango can't say, the hook leaves the daemon alone and says so.
set -euo pipefail
systemctl --user -q is-active thunar.service || exit 0
open=$(mmsg get all-clients 2>/dev/null |
	jq '[.clients[] | select(.appid | test("^(org\\.xfce\\.)?[Tt]hunar$"))] | length') || open=
if [[ $open != 0 ]]; then
	exec notify-send -a theme "Theme: Thunar" "Close Thunar's windows and run theme set again to apply ${THEME_NAME}"
fi
exec systemctl --user try-restart thunar.service

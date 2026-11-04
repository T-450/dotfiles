#!/usr/bin/env bash
# units.sh: restart the user units whose colors are read at startup (run by `theme set`)
# try-restart leaves stopped units alone, so a bar hidden with hide_mangobar.sh stays hidden.
systemctl --user -q is-active graphical-session.target || exit 0
exec systemctl --user try-restart mangobar.service swaybg.service swayosd.service

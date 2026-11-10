#!/usr/bin/env bash
# mpv/setup.sh: mpv as the default player for every type its desktop file lists (audio and video).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
mapfile -t types < <(sed -n 's/^MimeType=//p' /usr/share/applications/mpv.desktop | tr ';' '\n' | sed '/^$/d')
default_app mpv.desktop "${types[@]}"

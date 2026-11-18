#!/usr/bin/env bash
# imv/setup.sh: imv as the default viewer for every image type its desktop file lists.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
mapfile -t types < <(sed -n 's/^MimeType=//p' /usr/share/applications/imv.desktop | tr ';' '\n' | sed '/^$/d')
default_app imv.desktop "${types[@]}"

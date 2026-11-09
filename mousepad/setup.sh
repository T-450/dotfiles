#!/usr/bin/env bash
# mousepad/setup.sh: syntax colors from the palette (the "mango" GtkSourceView scheme, rendered by
# theme). Mousepad keeps its settings in GSettings; needs a dbus session, skipped without one.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
if ! user_bus; then
	echo "skip    mousepad settings: no user session bus"
	exit 0
fi
schema=org.xfce.mousepad.preferences.view
if [[ $(gsettings get $schema color-scheme) != "'mango'" ]]; then
	gsettings set $schema color-scheme mango
	echo "gsettings mousepad color-scheme mango"
fi

#!/usr/bin/env bash
# bluetooth/setup.sh: the bluetooth daemon, and blueman-applet without its tray icon (its unit is
# linked and enabled by install.sh). The tray part needs a dbus session; skipped without one.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system bluetooth.service

# The bar's bluetooth button already opens blueman-manager, and a second bluetooth icon in the tray
# cost the bar's right half 21px it doesn't have. Without its StatusNotifierItem plugin the applet
# falls back to a GtkStatusIcon, which Wayland never shows; pairing prompts and notifications stay.
if ! user_bus; then
	echo "skip    blueman tray icon: no user session bus"
	exit 0
fi
if [[ $(gsettings get org.blueman.general plugin-list) != "['!StatusNotifierItem']" ]]; then
	gsettings set org.blueman.general plugin-list "['!StatusNotifierItem']"
	echo "gsettings blueman plugin-list !StatusNotifierItem"
fi

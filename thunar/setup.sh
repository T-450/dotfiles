#!/usr/bin/env bash
# thunar/setup.sh: Thunar's settings (xfconf, which saves by rename, so not a linked file),
# automount, and Thunar/xarchiver as the default folder and archive apps. xfconf needs a dbus
# session; skipped without one.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
default_app thunar.desktop inode/directory
mapfile -t archives < <(sed -n 's/^MimeType=//p' /usr/share/applications/xarchiver.desktop | tr ';' '\n' | sed '/^$/d')
default_app xarchiver.desktop "${archives[@]}"
if ! user_bus; then
	echo "skip    thunar settings: no user session bus"
	exit 0
fi
want() { # want CHANNEL PROPERTY TYPE VALUE
	[[ $(xfconf-query -c "$1" -p "$2" 2>/dev/null) == "$4" ]] && return
	xfconf-query -c "$1" -p "$2" -n -t "$3" -s "$4" && echo "xfconf  $1 $2 $4"
}
want thunar /misc-show-delete-action bool true
want thunar /misc-middle-click-in-tab bool true
want thunar /misc-date-style string THUNAR_DATE_STYLE_YYYYMMDD
want thunar /misc-folder-item-count string THUNAR_FOLDER_ITEM_COUNT_ONLY_LOCAL
want thunar /misc-thumbnail-mode string THUNAR_THUMBNAIL_MODE_ONLY_LOCAL
want thunar-volman /automount-drives/enabled bool true
want thunar-volman /automount-media/enabled bool true

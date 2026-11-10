#!/usr/bin/env bash
# gtk/setup.sh: icons (Tela-mango), cursor and fonts for GTK apps, and the palette's dark/light preference
# (gtk/reload.sh, also run by `theme set`). Needs a dbus session; skipped without one.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
if ! user_bus; then
	echo "skip    gtk settings: no user session bus"
	exit 0
fi
gs=org.gnome.desktop.interface
want() { [[ $(gsettings get $gs "$1") == "'$2'" ]] || { gsettings set $gs "$1" "$2" && echo "gsettings $1 $2"; }; }
want icon-theme Tela-mango # icons/render.sh: Tela in the palette's accent
want cursor-theme Adwaita
want font-name 'Inter 11'
want monospace-font-name 'JetBrainsMono Nerd Font 11'
THEME_VARIANT=$(. "${XDG_CONFIG_HOME:-$HOME/.config}/theme/colors.sh" && echo "$THEME_VARIANT") "$repo/gtk/reload.sh"

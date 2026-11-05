#!/usr/bin/env bash
# gtk/reload.sh: tell GTK/libadwaita, the settings portal and Firefox about the variant (run by `theme set`)
# GTK reads gtk.css (and its colors.css) once per process, so only apps started after
# a switch get the new colors; flipping gtk-theme does not reload it, it only flashes.
set -euo pipefail
gs=org.gnome.desktop.interface
if [[ $THEME_VARIANT == light ]]; then
	scheme=prefer-light theme=Adwaita
else
	scheme=prefer-dark theme=Adwaita-dark
fi
set_() { [[ $(gsettings get $gs "$1") == "'$2'" ]] || gsettings set $gs "$1" "$2"; }
set_ color-scheme "$scheme"
set_ gtk-theme "$theme"

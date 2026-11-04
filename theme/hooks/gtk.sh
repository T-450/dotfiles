#!/usr/bin/env bash
# gtk.sh: tell GTK/libadwaita, the settings portal and Firefox about the variant (run by `theme set`)
# Running GTK3 apps only re-read gtk.css when gtk-theme changes, so when the value
# stays the same (dark palette -> another dark palette) flip it once and back.
set -euo pipefail
gs=org.gnome.desktop.interface
if [[ $THEME_VARIANT == light ]]; then
	scheme=prefer-light theme=Adwaita other=Adwaita-dark
else
	scheme=prefer-dark theme=Adwaita-dark other=Adwaita
fi
gsettings set $gs color-scheme "$scheme"
[[ $(gsettings get $gs gtk-theme) == "'$theme'" ]] && gsettings set $gs gtk-theme "$other"
gsettings set $gs gtk-theme "$theme"

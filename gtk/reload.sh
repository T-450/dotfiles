#!/usr/bin/env bash
# gtk/reload.sh: tell GTK, the settings portal (Qt, Firefox) and GTK4 about the variant (run by `theme set`)
# gtk-theme stays Adwaita: GTK3 reads it from GSettings over settings.ini, and "Adwaita-dark" is not
# installed, so GTK3 fell back to light Adwaita. Its built-in dark variant comes from color-scheme.
# GTK reads gtk.css (and its colors.css) once per process, so only apps started after a switch
# get the new colors.
set -euo pipefail
gs=org.gnome.desktop.interface
if [[ $THEME_VARIANT == light ]]; then scheme=prefer-light; else scheme=prefer-dark; fi
set_() { [[ $(gsettings get $gs "$1") == "'$2'" ]] || gsettings set $gs "$1" "$2"; }
set_ color-scheme "$scheme"
set_ gtk-theme Adwaita

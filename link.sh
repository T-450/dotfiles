#!/usr/bin/env bash
# Symlink this repo's configs into ~/.config (idempotent).
# Existing real files/dirs are moved to <name>.bak.<timestamp>, never deleted.
set -euo pipefail

src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
mkdir -p "$cfg"

link() { # link <source-in-repo> <name-in-~/.config>
	local from=$1 to=$cfg/$2
	if [[ -L $to ]]; then
		[[ $(readlink -- "$to") == "$from" ]] && { echo "ok      $to"; return; }
		rm -- "$to"
	elif [[ -e $to ]]; then
		mv -- "$to" "$to.bak.$(date +%s)"
		echo "backup  $to"
	fi
	ln -s -- "$from" "$to"
	echo "linked  $to -> $from"
}

link "$src"          mango
link "$src/foot"     foot
link "$src/rofi"     rofi
link "$src/mako"     mako
link "$src/swaylock" swaylock
link "$src/wlogout"  wlogout
link "$src/mangobar" mangobar
link "$src/gtk-3.0"                gtk-3.0
link "$src/gtk-4.0"                gtk-4.0
link "$src/environment.d"          environment.d
link "$src/xdg-desktop-portal"     xdg-desktop-portal
link "$src/xdg-desktop-portal-wlr" xdg-desktop-portal-wlr

# colors: render the active palette (default dark-2026) before anything reads it.
# init only writes files; `theme set` would also restart units, which happens below.
"$src/theme/theme" init
# dark/light preference for GTK, the settings portal and Firefox (theme set runs this too)
THEME_VARIANT=$(. "$src/theme/colors.sh" && echo "$THEME_VARIANT") "$src/theme/hooks/gtk.sh"

# fastfetch: link only our files; ~/.config/fastfetch may hold other presets
mkdir -p "$cfg/fastfetch"
link "$src/fastfetch/config.jsonc" fastfetch/config.jsonc
link "$src/fastfetch/logo.png"     fastfetch/logo.png

# Firefox: palette-colored chrome. The profile in use is the Default= of the
# [Install*] section in installs.ini (profiles.ini's Default=1 can be a stale one).
ff=$cfg/mozilla/firefox
if prof=$(awk -F= '/^Default=/{print $2; exit}' "$ff/installs.ini" 2>/dev/null) && [[ -n $prof && -d $ff/$prof ]]; then
	mkdir -p "$ff/$prof/chrome"
	link "$src/firefox/userChrome.css" "mozilla/firefox/$prof/chrome/userChrome.css"
	link "$src/firefox/user.js"        "mozilla/firefox/$prof/user.js"
else
	echo "skip    firefox (no profile yet: start Firefox once, then re-run link.sh)"
fi

# GTK icons, cursor and fonts. The dark/light preference (color-scheme, gtk-theme)
# follows the palette and is set by theme/hooks/gtk.sh.
gsettings set org.gnome.desktop.interface icon-theme Adwaita
gsettings set org.gnome.desktop.interface cursor-theme Adwaita
gsettings set org.gnome.desktop.interface font-name 'Inter 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'

# systemd user units: link each file (the .wants/ dirs stay out of the repo)
mkdir -p "$cfg/systemd/user"
units=()
for u in "$src"/systemd/user/*.service; do
	link "$u" "systemd/user/$(basename "$u")"
	units+=("$(basename "$u")")
done
units+=(mako.service) # packaged unit, already bound to graphical-session.target

systemctl --user daemon-reload
systemctl --user enable "${units[@]}"
# start now if we are inside a running mango session
if systemctl --user -q is-active graphical-session.target; then
	systemctl --user start "${units[@]}"
fi

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

# dark preference for GTK apps and the settings portal (firefox follows it)
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
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

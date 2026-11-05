#!/usr/bin/env bash
# System-level setup for this mango config (needs sudo). Safe to re-run.
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

echo "==> packages"
sudo pacman -S --needed \
	inter-font ttf-jetbrains-mono-nerd \
	swaylock jq libnotify xdg-user-dirs wev qt6-wayland \
	python imagemagick \
	firefox fastfetch \
	github-cli stow qemu-base \
	rtkit   # realtime scheduling for PipeWire/WirePlumber (fixes "RTKit error")

echo "==> remove swaync (replaced by mako)"
if pacman -Q swaync &>/dev/null; then sudo pacman -Rns swaync; fi

echo "==> power: TLP only (mask power-profiles-daemon)"
state() { systemctl is-enabled "$1" 2>/dev/null || true; }
sudo install -Dm644 "$here/tlp.d/10-thinkpad.conf" /etc/tlp.d/10-thinkpad.conf
if [[ $(state power-profiles-daemon.service) != masked ]]; then
	sudo systemctl disable --now power-profiles-daemon.service
	sudo systemctl mask power-profiles-daemon.service
fi
# systemd-rfkill only conflicts with TLP's radio options (DEVICES_TO_*), which this
# config does not use; keep it so Wi-Fi/Bluetooth on/off survives reboots.
for u in systemd-rfkill.service systemd-rfkill.socket; do
	if [[ $(state "$u") == masked ]]; then sudo systemctl unmask "$u"; fi
done
[[ $(state tlp.service) == enabled ]] || sudo systemctl enable --now tlp.service
# thermald: not used. On this T14 firmware (thinkpad_acpi DYTC) handles thermals and
# thermald exits with "Thermald can't run on this platform".
if pacman -Q thermald &>/dev/null && [[ $(state thermald.service) == enabled ]]; then
	sudo systemctl disable --now thermald.service
fi

echo "==> greeter (sysc-greet): \"Mango\" theme from the active palette, ringed-planet header, Higgs Field animation"
g="$here/../greeter"
gh=/var/lib/greeter
# theme + wallpaper rendered from the active palette, installed into the greeter's own
# config dir (the greeter user cannot read /home). Re-run after `theme set` to follow it.
# install-greeter renders as the user and calls sudo itself, so under `sudo ./setup.sh`
# drop back to the invoking user for it.
if [[ $EUID -eq 0 && -n ${SUDO_USER:-} ]]; then
	sudo -u "$SUDO_USER" "$here/../theme/theme" install-greeter
else
	"$here/../theme/theme" install-greeter
fi
# mango ASCII profile with the planet first; package upgrades overwrite it, so a
# pacman hook restores it from /usr/local/share after every sysc-greet upgrade
sudo install -Dm644 "$g/ascii_configs/mango.conf" /usr/local/share/sysc-greet/mango.conf
sudo install -m644 "$g/ascii_configs/mango.conf" /usr/share/sysc-greet/ascii_configs/mango.conf
sudo install -Dm644 "$g/sysc-greet-mango-profile.hook" /etc/pacman.d/hooks/sysc-greet-mango-profile.hook
# starting preferences (theme, background, session, username) — only on first install;
# afterwards the greeter keeps its own (F1 choices, last successful username)
sudo install -d -m700 -o greeter -g greeter "$gh/.cache" "$gh/.cache/sysc-greet"
if ! sudo test -e "$gh/.cache/sysc-greet/preferences"; then
	jq --arg u "${SUDO_USER:-$USER}" '.username = $u' "$g/preferences.json" |
		sudo install -m600 -o greeter -g greeter /dev/stdin "$gh/.cache/sysc-greet/preferences"
fi

echo "==> user dirs (~/Pictures for screenshots, ~/Downloads for blueman)"
xdg-user-dirs-update

echo "==> done. Firmware updates (optional):"
echo "    fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update"

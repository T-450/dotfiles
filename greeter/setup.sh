#!/usr/bin/env bash
# greeter/setup.sh: greetd + sysc-greet with the "Mango" theme (idempotent; sudo).
# Theme + wallpaper are rendered from the active palette and installed into the greeter's
# own config dir (the greeter user cannot read /home); re-run `theme install-greeter` after
# `theme set` to follow it.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
g=$repo/greeter
gh=/var/lib/greeter
sys_file "$g/etc/greetd/config.toml" /etc/greetd/config.toml
"$repo/theme/.local/bin/theme" install-greeter
# mango ASCII profile with the planet first; package upgrades overwrite it, so a
# pacman hook restores it from /usr/local/share after every sysc-greet upgrade
sys_file "$g/ascii_configs/mango.conf" /usr/local/share/sysc-greet/mango.conf
sys_file "$g/ascii_configs/mango.conf" /usr/share/sysc-greet/ascii_configs/mango.conf
sys_file "$g/sysc-greet-mango-profile.hook" /etc/pacman.d/hooks/sysc-greet-mango-profile.hook
# starting preferences (theme, background, session, username), only on first install;
# afterwards the greeter keeps its own (F1 choices, last successful username)
sudo install -d -m700 -o greeter -g greeter "$gh/.cache" "$gh/.cache/sysc-greet"
if ! sudo test -e "$gh/.cache/sysc-greet/preferences"; then
	jq --arg u "$USER" '.username = $u' "$g/preferences.json" |
		sudo install -m600 -o greeter -g greeter /dev/stdin "$gh/.cache/sysc-greet/preferences"
	echo "install $gh/.cache/sysc-greet/preferences"
fi
enable_system greetd.service

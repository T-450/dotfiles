#!/usr/bin/env bash
# greeter/setup.sh: start greetd at boot (its files come from greeter/root/ via install.sh --system)
# and make /var/lib/greeter/.cache/viewport-greeter, owned by greeter:greeter, so greeter-ui can
# save the last user and session. A second run changes nothing.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system greetd.service

cache=/var/lib/greeter/.cache/viewport-greeter
owner=$(stat -c '%U:%G' -- "$cache" 2>/dev/null || true)
if [[ ! -d $cache || $owner != greeter:greeter ]]; then
	sudo install -d -o greeter -g greeter -m 755 \
		/var/lib/greeter \
		/var/lib/greeter/.cache \
		"$cache"
	echo 'mkdir   /var/lib/greeter/.cache/viewport-greeter'
fi

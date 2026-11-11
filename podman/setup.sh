#!/usr/bin/env bash
# podman/setup.sh: subordinate user and group IDs for rootless containers, and podman.socket (the
# Docker-compatible API) for every user.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"

# Rootless podman maps container IDs onto a range of subordinate IDs. useradd usually allocates
# one; add a free 65536-ID range (after every range in use) only where it didn't, then let podman
# pick it up.
if ! grep -q "^$USER:" /etc/subuid || ! grep -q "^$USER:" /etc/subgid; then
	start=$(cat /etc/subuid /etc/subgid 2>/dev/null | awk -F: '{e = $2 + $3; if (e > m) m = e} END {print (m > 100000 ? m : 100000)}')
	sudo usermod --add-subuids "$start-$((start + 65535))" --add-subgids "$start-$((start + 65535))" "$USER"
	podman system migrate
	echo "config  subuid/subgid $USER ($start-$((start + 65535)))"
fi

# podman.socket listens for Docker API clients (testcontainers, the devcontainer CLI); a
# connection starts podman.service. Enabled globally, so it works without a user bus (a bare VM
# or CI runs this before any session) and starts at every login.
if [[ $(systemctl --global is-enabled podman.socket 2>/dev/null) != enabled ]]; then
	sudo systemctl --global enable podman.socket
	echo "enable  podman.socket (every user)"
fi
# start it in a running session too, so it works before the next login
if user_bus && ! systemctl --user is-active -q podman.socket; then
	systemctl --user start podman.socket
	echo "start   podman.socket"
fi

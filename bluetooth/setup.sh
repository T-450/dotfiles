#!/usr/bin/env bash
# bluetooth/setup.sh: the bluetooth daemon (blueman-applet's unit is linked and enabled by install.sh).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system bluetooth.service

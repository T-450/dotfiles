#!/usr/bin/env bash
# greeter/setup.sh: start greetd at boot (its files come from greeter/root/ via install.sh --system).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system greetd.service

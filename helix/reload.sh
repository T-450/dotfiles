#!/usr/bin/env bash
# helix/reload.sh: running helix editors re-read config.toml and the rendered themes/palette.toml
# (run by `theme set`); helix reloads its config on SIGUSR1, as :config-reload does. The process is
# `helix` (the /usr/bin link's name), not `hx`, the binary it points to.
pkill -USR1 -x helix || true

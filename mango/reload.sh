#!/usr/bin/env bash
# mango/reload.sh: reload mango so colors.conf applies (run by `theme set`)
# Outside a mango session (no IPC socket) there is nothing to reload.
[[ -n ${MANGO_INSTANCE_SIGNATURE:-} ]] || exit 0
exec mmsg dispatch reload_config

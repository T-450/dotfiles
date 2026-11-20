#!/usr/bin/env bash
# mango/reload.sh: reload mango so colors.conf applies and signal mango-whichkey to reload CSS
# (run by `theme set`). Outside a mango session (no IPC socket) there is nothing to reload.
[[ -n ${MANGO_INSTANCE_SIGNATURE:-} ]] || exit 0
systemctl --user -q is-active mango-whichkey.service && systemctl --user kill -s USR1 mango-whichkey.service || true
exec mmsg dispatch reload_config

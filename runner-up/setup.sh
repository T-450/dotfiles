#!/usr/bin/env bash
# runner-up/setup.sh: keep your user manager (and so runner-up.service) running while logged out.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
[[ $(loginctl show-user "$USER" -p Linger --value 2>/dev/null) == yes ]] || { loginctl enable-linger "$USER" && echo "linger  $USER"; }

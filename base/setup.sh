#!/usr/bin/env bash
# base/setup.sh: system services this desktop relies on, and the XDG user dirs
# (~/Pictures for screenshots, ~/Downloads for blueman).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system NetworkManager.service systemd-timesyncd.service ufw.service fstrim.timer
[[ -f $HOME/.config/user-dirs.dirs ]] || { xdg-user-dirs-update && echo "xdg     user dirs"; }

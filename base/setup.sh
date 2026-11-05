#!/usr/bin/env bash
# base/setup.sh: system services and the few /etc files this setup relies on (idempotent).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
sys_file "$repo/base/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
sys_file "$repo/base/etc/NetworkManager/conf.d/wifi_backend.conf" /etc/NetworkManager/conf.d/wifi_backend.conf
enable_system NetworkManager.service systemd-timesyncd.service ufw.service fstrim.timer
xdg-user-dirs-update # ~/Pictures for screenshots, ~/Downloads for blueman

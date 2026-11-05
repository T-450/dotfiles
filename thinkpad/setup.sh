#!/usr/bin/env bash
# thinkpad/setup.sh: power management by TLP alone (idempotent).
# power-profiles-daemon conflicts with TLP; thermald exits on this T14 ("can't run on this
# platform": firmware (thinkpad_acpi DYTC) handles thermals), so both are removed.
# systemd-rfkill only conflicts with TLP's radio options (DEVICES_TO_*), unused here: kept so
# Wi-Fi/Bluetooth on/off survives reboots.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
sys_file "$repo/thinkpad/etc/tlp.d/10-thinkpad.conf" /etc/tlp.d/10-thinkpad.conf
remove_pkgs power-profiles-daemon thermald
for u in systemd-rfkill.service systemd-rfkill.socket; do
	if [[ $(systemctl is-enabled "$u" 2>/dev/null) == masked ]]; then sudo systemctl unmask "$u"; fi
done
enable_system tlp.service

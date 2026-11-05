#!/usr/bin/env bash
# thinkpad/setup.sh: TLP manages power (its config comes from thinkpad/root/ via install.sh --system).
# Not installed on purpose: power-profiles-daemon (conflicts with TLP) and thermald (exits on this
# T14: "can't run on this platform"; the firmware, thinkpad_acpi DYTC, handles thermals).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system tlp.service

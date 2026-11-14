#!/usr/bin/env bash
# thinkpad/setup.sh: TLP manages power (its config comes from thinkpad/root/ via install.sh --system).
# Not installed on purpose: power-profiles-daemon (conflicts with TLP) and thermald (exits on this
# T14: "can't run on this platform"; the firmware, thinkpad_acpi DYTC, handles thermals).
# BIOS settings go through thinklmi (Lenovo WMI, no BIOS admin password set): VT-d and Kernel DMA
# Protection on, so the kernel turns the IOMMU on (platform opt-in) and a Thunderbolt device can't
# read memory over DMA. A change takes effect at the next boot. No thinklmi (a VM): nothing to do.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system tlp.service

# bios NAME VALUE: set a BIOS setting through thinklmi when it differs (reads need root too)
bios() {
	local a=/sys/class/firmware-attributes/thinklmi/attributes/$1
	[[ -d $a ]] || return 0
	[[ $(sudo cat "$a/current_value") == "$2" ]] && return 0
	echo "$2" | sudo tee "$a/current_value" >/dev/null
	echo "bios    $1=$2 (at the next boot)"
}
bios VTdFeature Enable
bios KernelDMAProtection Enable

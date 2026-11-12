#!/usr/bin/env bash
# plymouth/setup.sh: rebuild the initramfs images (mkinitcpio -P) when what goes into them changed:
# the mkinitcpio config (root/ adds the plymouth hook), plymouthd.conf (the theme), vconsole.conf
# (the keymap and consolefont hooks embed it; base/root/), the kernel command line a UKI embeds
# (/etc/kernel/cmdline, root/ adds splash in /etc/cmdline.d) or the plymouth and theme packages.
# pacman's mkinitcpio hook misses a theme upgrade (/usr/share/plymouth/themes).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
pkgs=(plymouth plymouth-i_use_arch_btw-git)
if ! pacman -Q "${pkgs[@]}" &>/dev/null; then
	echo "skip    initramfs: ${pkgs[*]} not installed"
	exit 0
fi
# A UKI's command line is /etc/kernel/cmdline plus /etc/cmdline.d. Without the first, mkinitcpio would
# embed root/'s splash line alone, no root=, and the image would not boot.
if grep -qs '^[^#]*_uki=' /etc/mkinitcpio.d/*.preset && [[ ! -e /etc/kernel/cmdline && ! -e /usr/lib/kernel/cmdline ]]; then
	echo "plymouth: the presets build UKIs but there is no /etc/kernel/cmdline (root=...); write it, then rerun" >&2
	exit 1
fi
rebuild() { sudo mkinitcpio -P && echo "rebuild initramfs (plymouth, theme i_use_arch_btw)"; }
# each file under its name, so moving a line between files counts as a change; /etc/kernel/cmdline
# exists only where the presets build UKIs
inputs=$(
	for f in /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf /etc/plymouth/plymouthd.conf /etc/vconsole.conf /etc/kernel/cmdline /etc/cmdline.d/*.conf; do
		[[ -e $f ]] || continue
		echo "== $f" && cat -- "$f" || exit # $(...) ignores set -e: a failed read must not hash
	done
	pacman -Q "${pkgs[@]}"
)
when_changed "$repo/plymouth/initramfs.stamp" rebuild <<<"$inputs"

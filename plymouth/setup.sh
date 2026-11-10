#!/usr/bin/env bash
# plymouth/setup.sh: rebuild the initramfs images (mkinitcpio -P) when what goes into them changed:
# the mkinitcpio config (root/ adds the plymouth hook), plymouthd.conf (the theme) or the plymouth
# and theme packages. pacman's mkinitcpio hook misses a theme upgrade (/usr/share/plymouth/themes).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
pkgs=(plymouth plymouth-i_use_arch_btw-git)
if ! pacman -Q "${pkgs[@]}" &>/dev/null; then
	echo "skip    initramfs: ${pkgs[*]} not installed"
	exit 0
fi
rebuild() { sudo mkinitcpio -P && echo "rebuild initramfs (plymouth, theme i_use_arch_btw)"; }
inputs=$(cat /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/*.conf /etc/plymouth/plymouthd.conf && pacman -Q "${pkgs[@]}")
when_changed "$repo/plymouth/initramfs.stamp" rebuild <<<"$inputs"

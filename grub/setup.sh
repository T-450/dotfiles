#!/usr/bin/env bash
# grub/setup.sh: regenerate /boot/grub/grub.cfg (grub-mkconfig) when /etc/default/grub (root/) or
# the theme package changed. grub-mkconfig checks the new file before it replaces the old one. A
# machine with no grub.cfg (another boot loader) is left alone.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
pkg=grub-theme-lenovo-thinkpad-efi
if ! pacman -Q "$pkg" &>/dev/null; then
	echo "skip    grub.cfg: $pkg not installed"
	exit 0
fi
regenerate() {
	sudo true || return # a failed password must not pass for "no grub.cfg" below
	if ! sudo test -f /boot/grub/grub.cfg; then # /boot/grub may be readable only by root (ESP)
		echo "skip    grub.cfg: none in /boot/grub (GRUB isn't the boot loader)"
		return 0
	fi
	sudo grub-mkconfig -o /boot/grub/grub.cfg && echo "rebuild grub.cfg (/etc/default/grub, theme)"
}
inputs=$(cat /etc/default/grub && pacman -Q "$pkg")
when_changed "$repo/grub/grub-cfg.stamp" regenerate <<<"$inputs"

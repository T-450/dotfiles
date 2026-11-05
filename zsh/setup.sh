#!/usr/bin/env bash
# zsh/setup.sh: zsh as the login shell (~/.zshrc is linked, oh-my-zsh comes from zsh/packages).
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
	sudo chsh -s /usr/bin/zsh "$USER"
fi

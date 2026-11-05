#!/usr/bin/env bash
# zsh/setup.sh: oh-my-zsh in ~/.oh-my-zsh (only if missing; it updates itself afterwards) and
# zsh as the login shell. Idempotent. ~/.zshrc itself is linked by install.sh.
set -euo pipefail
if [[ ! -d $HOME/.oh-my-zsh ]]; then
	git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
	sudo chsh -s /usr/bin/zsh "$USER"
fi

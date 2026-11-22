# dotfiles: Arch + mangowm (ThinkPad T14)

An Arch Linux desktop on mangowm, themed from one switchable palette (default:
**Moonfly**, `bluz71/vim-moonfly-colors` / terminalcolors.com). Each app has its own folder; GNU stow links them into `~/.config` and `~/.local`.

```bash
git clone https://github.com/T-450/dotfiles ~/dotfiles
~/dotfiles/install.sh            # packages, theme, links, setup, units; safe to re-run
theme set solarized-light        # recolor everything (or super+shift+t)
```

New here? Follow [Get started](docs/onboarding.md). Documentation: [docs/](docs/README.md): install, every app, session, theming, keybindings,
testing. Started from [DreamMaoMao/mango-config](https://github.com/DreamMaoMao/mango-config).

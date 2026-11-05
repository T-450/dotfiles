# Install

On a clean Arch install (archinstall with a user in `wheel` is enough):

```bash
sudo pacman -S --needed git
git clone https://github.com/T-450/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` is idempotent: run it again any time; a second run changes nothing. It runs as your
user and calls sudo itself. Phases, in order (pick some with flags, e.g. `--link --setup`):

| phase | does |
|---|---|
| `--packages` | every `<app>/packages`: repo packages with `pacman -Syu --needed`, the rest from the AUR with yay (installs `yay-bin` first if needed) |
| `--theme` | `theme init`: renders the active palette into every `*.tmpl`'s output |
| `--link` | GNU stow links every app folder into `$HOME` (one link per file). Something in the way is moved to `<name>.bak.<timestamp>`; old links into the repo are replaced; links to removed files are pruned |
| `--setup` | `base/setup.sh`, then every `<app>/setup.sh`: /etc files, services, gsettings, Firefox profile, greeter, Claude Code/opencode themes |
| `--units` | enables every app's user units; starts them inside a running session |

`--only APP...` limits any phase to some apps. `--home DIR` links into another directory (tests).

## Manual steps

These can't be scripted, or need you once:

- **GitHub CLI**: `gh auth login`. Needed by runner-up (CI); `runner-up/setup.sh` skips until then.
- **Firefox**: start it once so it creates its profile, then `./install.sh --setup --only firefox`.
- **opencode 1.x settings**: if `~/.config/opencode/tui.json` exists and `cli.json` doesn't, start
  opencode once (it migrates them), then `./install.sh --setup --only opencode`.
- **Greeter after a theme change**: `theme install-greeter` (sudo). The greeter user can't read your home.
- **Firmware**: `fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update`.

## What it changes outside your home

`base`: `/etc/systemd/zram-generator.conf`, NetworkManager's iwd backend, NetworkManager,
timesyncd, ufw, fstrim. `thinkpad`: TLP config; removes power-profiles-daemon and thermald.
`bluetooth`: bluetooth.service. `greeter`: greetd config, sysc-greet theme and profile, a pacman
hook. `zsh`: login shell. `mako`, `mango`, `waybar`: remove swaync, xorg-xrdb, mangobar-git.
Each app's page lists its exact files.

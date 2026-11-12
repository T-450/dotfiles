# Install

On a fresh Arch Linux install (archinstall, a user in `wheel`, network up), as that user:

```bash
curl -fsSL https://raw.githubusercontent.com/T-450/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` installs git and the GitHub CLI, clones this repo to `~/dotfiles`, asks once for
the GitHub sign-in (runner-up, the CI coordinator, serves jobs through it; skip it and runner-up
stays off), then runs `install.sh`. Log out and back in (or reboot into greetd) and the desktop is
there. One sign-in is left for when you want it: `sbx login` (your Docker account) before the
first AI-agent sandbox, with its one-time `sbx policy init` ([sbx](apps/sbx.md)). Nothing else is manual.

## install.sh

Idempotent: run it again any time; a second run changes nothing. It runs as your user and calls
sudo only where something must change. Every app folder goes through the same phases:

| phase | does |
|---|---|
| `--packages` | `<app>/packages`: repo packages with pacman (after a full `-Syu`), AUR ones with yay (yay-bin built first if missing); `<app>/pkg/*/PKGBUILD`: built with makepkg when that version isn't installed (build-only dependencies are removed again, as yay's for the AUR) |
| `--theme` | `theme init`: renders every `*.tmpl` from the active palette, runs every `render.sh` |
| `--link` | GNU stow links each app's dot-entries (`.config/`, `.local/`, `.zshrc` …) into `$HOME`, one link per file. A real file in the way is moved to `<name>.bak.<timestamp>`; old links into the repo are replaced; links to removed files are pruned |
| `--system` | copies each `<app>/root/**` to `/**` when it differs (sudo); owner = owner of the nearest existing directory |
| `--setup` | each `<app>/setup.sh`: state that isn't a file (services, gsettings, login shell, linger) |
| `--units` | enables each app's user units and starts the new ones |
| `--check` | changes nothing; reports links missing or replaced by real files and system files that differ; exit 1 on any |

`--only APP...` limits any phase to some apps. `--home DIR` and `--root DIR` link and copy into
another directory (tests).

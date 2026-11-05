# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

## What this is

Personal dotfiles for an Arch Linux desktop on **mangowm** 0.18.x (Wayland) on a ThinkPad T14
(single panel `eDP-1`, 1920x1080, scale 1). `docs/` is the reference: read `docs/README.md` (layout,
app index), `docs/session.md`, `docs/theming.md`, `docs/testing.md` before changing things.

## Layout (details: docs/README.md#layout)

**One model for every app; no special cases.** An app folder uses only these parts:
`packages` (pacman/AUR), `pkg/<name>/PKGBUILD` (unpackaged programs), dot-entries (`.config/`,
`.local/`, `.zshrc` …: linked into `$HOME` by GNU stow, one link per file), `root/` (system files,
copied to `/` by `install.sh --system`), `*.tmpl` (rendered in place by `theme`), `render.sh`
(generated art), `reload.sh` (after `theme set`), `setup.sh` (only state that isn't a file:
services, gsettings, login shell, linger), `.config/systemd/user/*.service` (enabled by install.sh).
A new need either fits one of these or extends install.sh/theme for **every** app, never one.

- `bootstrap.sh` (fresh Arch → this desktop) clones the repo and runs `install.sh`.
- Paths in configs, binds, units and scripts use the **installed** locations: `~/.local/bin/<cmd>`,
  `~/.config/<app>/…`, `%h/.config/…` in units, `/usr/...` for packaged files. Never repo paths.
- A new file in an app folder goes live only after `./install.sh --link` (or `--system`).
- The repo owns every file it links or copies; `install.sh --check` reports drift.

## Rules

- **Every install and configuration, new or updated, goes through the repo**: programs in
  `<app>/packages` or `<app>/pkg/`, files as dot-entries or under `root/`, the rest in `setup.sh`.
  No one-off manual steps, no migration code: a one-time fix on this machine is done by hand
  once, not kept in a script. Scripts stay idempotent (act only on a difference; a second `install.sh` run changes
  nothing) and reproducible: a clean Arch VM running `install.sh` must end up with the same desktop
  (CI runs bootstrap.sh on a fresh VM on every push).
- **Docs move with the code.** A new or changed app means, in the same commit: its folder, its
  `packages`, its `docs/apps/<app>.md` (hand-written part), `tools/docs` (regenerates the reference
  blocks), and `tools/docs --snapshot` when packages changed. `tools/docs --check` must pass.
- **Never write a color literal in a config.** Colors come from `theme/palettes/*.toml` through
  `<app>/**/NAME.tmpl` templates (`{{role|filter}}`) rendered in place to `NAME`; list `NAME` in the
  app's `.gitignore`. Scripts read `THEME_*` from `~/.config/theme/colors.sh`. `theme lint` must pass.
- **Never commit secrets** (opencode's `service.json`, tokens, keys). `theme lint` flags known names.
- **Session daemons are user units** with `PartOf=`/`After=`/`Requisite=graphical-session.target`
  and `WantedBy=graphical-session.target`, in the app's `.config/systemd/user/`. No `exec_once`,
  no `dbus-update-activation-environment`. swaylock stays guarded by `pidof -q swaylock ||` and
  swayidle keeps `KillMode=process`.
- Env vars: `mango/.config/mango/env.conf` for mango's children, `mango/.config/environment.d/` for
  units; a variable both need goes in both.
- Git: work on a branch, merge to `main`, push to `origin` (github.com/T-450/dotfiles, public:
  never commit secrets). `upstream` is
  DreamMaoMao's repo and is never pushed to. No PRs.

## Validating changes

```bash
tests/run                                   # all tests (tests/unit.d/*-test.sh)
theme lint                                  # colors, gitignored renders, secrets
tools/docs --check                          # docs in step with the repo
theme set "$(theme current)"                # re-render + reload after editing a template
./install.sh --check                        # home and system files match the repo
./install.sh --link                         # after adding a file to an app folder
mango -c ~/.config/mango/config.conf -p && echo ok
systemctl --user --failed; journalctl --user -b -u <unit>
```

## Conventions

- Shell scripts: `#!/usr/bin/env bash` (or `/usr/bin/bash`), tabs, a header comment with the usage
  line. Commands in `.local/bin/` have no `.sh` suffix.
- `osd-brightness` has two verb pairs on purpose: `up`/`down` (keys) show the OSD, `bup`/`bdown`
  (bar scroll) use plain brightnessctl at 1% steps.
- Comments explain *why* (hardware quirks, e.g. thermald unsupported on this T14). Keep that style.

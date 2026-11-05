# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

## What this is

Personal dotfiles for an Arch Linux desktop on **mangowm** 0.18.x (Wayland) on a ThinkPad T14
(single panel `eDP-1`, 1920x1080, scale 1). `docs/` is the reference: read `docs/README.md` (layout,
app index), `docs/session.md`, `docs/theming.md`, `docs/testing.md` before changing things.

## Layout (details: docs/README.md#layout)

- One folder per app. Its `.config/`, `.local/` and dot-entries mirror `$HOME` and are linked by
  GNU stow (`install.sh --link`, `--no-folding`: one link per file). `.stow-local-ignore` marks a
  linked app and keeps `packages`, `setup.sh`, `reload.sh`, `*.tmpl`, `etc/` out of `$HOME`.
- Paths in configs, binds, units and scripts use the **installed** locations: `~/.local/bin/<cmd>`,
  `~/.config/<app>/…`, `%h/.config/…` in units. Never repo-relative paths.
- A new file in an app folder goes live only after `./install.sh --link`.
- System files live in `<app>/etc/` and are installed by that app's `setup.sh` (sudo).

## Rules

- **Every install and configuration, new or updated, goes through the scripts**: packages in
  `<app>/packages`, everything else in `<app>/setup.sh` (or the app's linked files). No one-off
  manual steps. Scripts stay idempotent (act only on a difference; a second `install.sh` run changes
  nothing) and reproducible: a clean Arch VM running `install.sh` must end up with the same desktop
  (CI proves it on every push). What truly can't be scripted goes in `docs/install.md` → Manual steps.
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
- Git: work on a branch, merge to `main`, push to `origin` (the private repo). `upstream` is
  DreamMaoMao's repo and is never pushed to. No PRs.

## Validating changes

```bash
tests/run                                   # all tests (tests/unit.d/*-test.sh)
theme lint                                  # colors, gitignored renders, secrets
tools/docs --check                          # docs in step with the repo
theme set "$(theme current)"                # re-render + reload after editing a template
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

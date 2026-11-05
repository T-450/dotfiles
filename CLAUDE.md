# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for the **mangowm** (0.18.x) Wayland compositor on Arch, on a ThinkPad T14 (single panel `eDP-1`, 1920x1080, scale 1). Derived from DreamMaoMao/mango-config, cut down and themed with VS Code **Dark 2026**. There is no build or test suite; "verifying" means validating configs and checking systemd user units (see below). `README.md` is the user-facing reference (stack table, keybindings, greeter files) and should be kept in sync when behaviour changes.

## Deployment model

- `link.sh` (idempotent) symlinks the **repo root itself** to `~/.config/mango`, plus `foot rofi mako swaylock wlogout mangobar gtk-3.0 gtk-4.0 environment.d xdg-desktop-portal xdg-desktop-portal-wlr` to `~/.config/<name>`, and each `systemd/user/*.service` file to `~/.config/systemd/user/`. It also links `fastfetch/{config.jsonc,logo.png}` into `~/.config/fastfetch/` (other presets there stay) and `firefox/{user.js,userChrome.css}` into the Firefox profile named in `installs.ini`, runs `theme/theme init`, the GTK variant hook and `theme/hooks/agents.sh --activate` (Claude Code/opencode themes, selected only where unset). It then enables the units (plus the packaged `mako.service`) and sets GTK gsettings. Existing real files get moved to `*.bak.<ts>`.
- So edits in the repo go live right away. Keybindings, unit files and bar config all point at `~/.config/mango/...` paths, for example `~/.config/mango/scripts/*.sh` and `%h/.config/mango/mangobar/...` in `mangobar.service`. Use those paths, not repo-relative ones, when wiring up new scripts.
- A new top-level config dir only takes effect once it has a `link` line in `link.sh`. A new unit in `systemd/user/` gets picked up by the glob automatically.
- `system/setup.sh` does the sudo-level work: pacman packages, removing swaync, TLP config and masking power-profiles-daemon, installing the greeter files into `/var/lib/greeter`, `/usr/share/sysc-greet` and `/etc/pacman.d/hooks`. Anything outside `$HOME` belongs here, not in `link.sh`.
- `installed.txt` is a snapshot of installed packages (`pacman -Q` format: `name version`, sorted), for reference only.
- **When any new component is installed and configured, add it to `README.md` (Stack table, plus keybindings or a section if it has any) and to `installed.txt` (its `pacman -Q` line, kept sorted) in the same change.**
- **Every install and configuration, new or updated, goes through the install scripts (`system/setup.sh` for packages and anything outside `$HOME`, `link.sh` for user config), never as a one-off manual step.** The scripts must stay idempotent (safe to re-run, no duplicate edits, existing state checked before changing it) and reproducible: a clean Arch VM running `system/setup.sh` then `link.sh` must end up with the same working setup. If a step can't be scripted (e.g. an interactive login), document it in `README.md` under Install.

## Session architecture (spread across several files)

- `config.conf` is the mango entry point. It `source=`s `colors.conf` (rendered by `theme/theme`) and `env.conf bind.conf rule.conf monitor.conf tag.conf`. `bind.conf` defines `var=` shortcuts (`$term`, `$launcher`, `$locker`, `$browser`). They must be defined before use and are shared across the sourced files.
- **There is no `exec_once` autostart, on purpose.** Mango imports `WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_* MANGO_INSTANCE_SIGNATURE` into systemd/dbus and starts `mango-session.target` → `graphical-session.target`. Every daemon (bar, wallpaper, idle, OSD, polkit, clipboard, wlsunset, blueman) is a user unit with `PartOf=`/`After=`/`Requisite=graphical-session.target` and `WantedBy=graphical-session.target`. Follow this pattern for new daemons, and don't add `dbus-update-activation-environment` or `exec_once` lines.
- Environment comes in two layers. `env.conf` (`env=` lines) applies to mango's own children and is reset on reload. `environment.d/10-wayland.conf` applies to systemd units and needs a relogin. A variable that both need goes in both files.
- Logout goes through `scripts/session-quit.sh`, which stops `graphical-session.target` *before* `mmsg dispatch quit` so units don't die with display errors.
- `swayidle.service` handles dim/lock/DPMS (dimland at 4m, swaylock at 5m, `mmsg dispatch sleep_monitor` at 10m). swaylock is always guarded with `pidof -q swaylock ||`, and the unit uses `KillMode=process` so a restart doesn't unlock the screen. Keep both properties.
- The bar toggle (`scripts/hide_mangobar.sh`) starts and stops `mangobar.service`. It doesn't kill the process.
- `mmsg` is mango's IPC CLI (`mmsg dispatch <action>`, `mmsg get all-monitors|all-devices`). Scripts and units use it to control the compositor.

## Theming

**Never write a color literal in a config.** Every color comes from a palette in `theme/palettes/*.toml` (semantic roles such as `bg_widget`, `accent`, `fg_secondary`) and reaches apps through `theme/theme`, which renders `theme/templates/*` into gitignored colors-only files listed in `theme/targets.toml` (`colors.conf`, `foot/colors.ini`, `mako/colors`, `*/colors.css`, `rofi/themes/colors.rasi`, `swaylock/config`, `gtk-*/settings.ini`, `theme/colors.sh`, `greeter/themes/mango.toml`, `firefox/userChrome.css`, `fastfetch/config.jsonc`, `theme/out/*` for Claude Code/opencode), then runs `theme/hooks/*.sh` to reload apps. To color something new: use an existing role in a template (filters `|bare`, `|0x`, `|0x:33`, `|hex:88`, `|rgba:0.9`, `|mix:<role>:<t>`), or read `THEME_*` from `~/.config/mango/theme/colors.sh` in scripts and units. `THEME.md` documents the roles, their consumers (keep its "used in" column current) and how to add an app or a theme. `theme/theme lint` must stay clean. The greeter gets the active palette as a stable theme named "Mango" via `theme/theme install-greeter` (sudo), because the `greeter` user can't read `/home`. Fonts are Inter (UI) and JetBrains Mono Nerd Font (mono).

## Validating changes

```bash
theme/theme lint                                     # no color literals outside theme/
theme/theme set "$(theme/theme current)"             # re-render + reload after editing a template
mango -c ~/.config/mango/config.conf -p && echo ok   # parse-check (passes even if colors.conf is missing: run theme init)
foot --check-config
makoctl reload
systemctl --user daemon-reload                       # after editing a unit
systemctl --user --failed
journalctl --user -b -u <unit>                       # e.g. mangobar, swayidle
systemctl --user show-environment | grep -E 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|MANGO_INSTANCE'
```

Mango auto-reloads config on save (also `super+r`). `env.conf` changes need a relogin.

## Conventions

- Shell scripts use `#!/usr/bin/bash` or `#!/usr/bin/env bash`, tabs for indentation, and a header comment with the usage line.
- `brightness.sh` takes two pairs of verbs on purpose. `up`/`down` (keys) show the swayosd OSD. `bup`/`bdown` (bar scroll) use plain brightnessctl at 1% steps.
- Comments in config files explain *why*, e.g. hardware quirks like thermald being unsupported on this T14. Keep that style.

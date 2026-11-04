# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for the **mangowm** (0.18.x) Wayland compositor on Arch, on a ThinkPad T14 (single panel `eDP-1`, 1920x1080, scale 1). Derived from DreamMaoMao/mango-config, cut down and themed with VS Code **Dark 2026**. There is no build or test suite; "verifying" means validating configs and checking systemd user units (see below). `README.md` is the user-facing reference (stack table, keybindings, greeter files) and should be kept in sync when behaviour changes.

## Deployment model

- `link.sh` (idempotent) symlinks the **repo root itself** to `~/.config/mango`, plus `foot rofi mako swaylock wlogout mangobar gtk-3.0 gtk-4.0 environment.d xdg-desktop-portal xdg-desktop-portal-wlr` to `~/.config/<name>`, and each `systemd/user/*.service` file to `~/.config/systemd/user/`. It then enables the units (plus the packaged `mako.service`) and sets GTK gsettings. Existing real files get moved to `*.bak.<ts>`.
- So edits in the repo go live right away. Keybindings, unit files and bar config all point at `~/.config/mango/...` paths, for example `~/.config/mango/scripts/*.sh` and `%h/.config/mango/mangobar/...` in `mangobar.service`. Use those paths, not repo-relative ones, when wiring up new scripts.
- A new top-level config dir only takes effect once it has a `link` line in `link.sh`. A new unit in `systemd/user/` gets picked up by the glob automatically.
- `system/setup.sh` does the sudo-level work: pacman packages, removing swaync, TLP config and masking power-profiles-daemon, installing the greeter files into `/var/lib/greeter`, `/usr/share/sysc-greet` and `/etc/pacman.d/hooks`. Anything outside `$HOME` belongs here, not in `link.sh`.
- `installed.txt` is a snapshot of installed packages, for reference only.

## Session architecture (spread across several files)

- `config.conf` is the mango entry point. It `source=`s `env.conf bind.conf rule.conf monitor.conf tag.conf`. `bind.conf` defines `var=` shortcuts (`$term`, `$launcher`, `$locker`, `$browser`). They must be defined before use and are shared across the sourced files.
- **There is no `exec_once` autostart, on purpose.** Mango imports `WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_* MANGO_INSTANCE_SIGNATURE` into systemd/dbus and starts `mango-session.target` → `graphical-session.target`. Every daemon (bar, wallpaper, idle, OSD, polkit, clipboard, wlsunset, blueman) is a user unit with `PartOf=`/`After=`/`Requisite=graphical-session.target` and `WantedBy=graphical-session.target`. Follow this pattern for new daemons, and don't add `dbus-update-activation-environment` or `exec_once` lines.
- Environment comes in two layers. `env.conf` (`env=` lines) applies to mango's own children and is reset on reload. `environment.d/10-wayland.conf` applies to systemd units and needs a relogin. A variable that both need goes in both files.
- Logout goes through `scripts/session-quit.sh`, which stops `graphical-session.target` *before* `mmsg dispatch quit` so units don't die with display errors.
- `swayidle.service` handles dim/lock/DPMS (dimland at 4m, swaylock at 5m, `mmsg dispatch sleep_monitor` at 10m). swaylock is always guarded with `pidof -q swaylock ||`, and the unit uses `KillMode=process` so a restart doesn't unlock the screen. Keep both properties.
- The bar toggle (`scripts/hide_mangobar.sh`) starts and stops `mangobar.service`. It doesn't kill the process.
- `mmsg` is mango's IPC CLI (`mmsg dispatch <action>`, `mmsg get all-monitors|all-devices`). Scripts and units use it to control the compositor.

## Theming

All colors come from `THEME.md`, a role → VS Code key → hex table, plus foot's ANSI palette. Reuse those exact hex values, and update the table's "used in" column when a color gets a new consumer. Mango colors are written as `0xRRGGBBAA`. Fonts are Inter (UI) and JetBrains Mono Nerd Font (mono). The greeter has its own copy of the theme (`greeter/themes/dark-2026.toml`) because the `greeter` user can't read `/home`. Its art is regenerated with `greeter/make-planet.py` and `greeter/make-wallpaper.sh`.

## Validating changes

```bash
mango -c ~/.config/mango/config.conf -p && echo ok   # parse-check mango config
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

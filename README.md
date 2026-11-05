# mango config — VS Code Dark 2026 (ThinkPad T14)

Based on [DreamMaoMao/mango-config](https://github.com/DreamMaoMao/mango-config), reduced to a
basic setup for mangowm 0.18.4 on Arch, themed with VS Code's **Dark 2026** colors (neutral greys,
one blue accent). Colors come from one switchable palette: `theme/theme set <name>`, see `THEME.md`. Every config lives in this directory; `./link.sh` symlinks it into `~/.config`.

## Stack

| role | package | config |
|---|---|---|
| compositor | `mangowm` (extra) | `config.conf` + `env.conf bind.conf rule.conf monitor.conf tag.conf` |
| login | `greetd` + `sysc-greet-mango` | `greeter/` (installed by `system/setup.sh`) |
| bar | `mangobar-git` (AUR) | `mangobar/` |
| terminal | `foot` | `foot/foot.ini` |
| system info | `fastfetch` | `theme/templates/fastfetch.jsonc` (rendered to `fastfetch/config.jsonc`), `fastfetch/logo.png` |
| launcher | `rofi` | `rofi/config.rasi`, `rofi/themes/quickinput.rasi` |
| colors | `theme/theme` (`python`; `jq` for the Claude/opencode hook, `imagemagick` for greeter art) | `theme/palettes/*.toml` → every app, see `THEME.md` |
| notifications | `mako` | `mako/config` |
| lock / idle | `swaylock`, `swayidle`, `dimland-git` | `theme/templates/swaylock`, `systemd/user/swayidle.service` |
| power menu | `wlogout` | `wlogout/` |
| wallpaper | `swaybg` (solid palette `bg_desktop`) | `systemd/user/swaybg.service` |
| OSD | `swayosd` | `swayosd/style.css`, `scripts/volume.sh`, `scripts/brightness.sh` |
| clipboard | `wl-clipboard cliphist wl-clip-persist` | units |
| polkit | `polkit-gnome` | unit |
| portals | `xdg-desktop-portal-{wlr,gtk}`, `gnome-keyring` | `xdg-desktop-portal/`, `xdg-desktop-portal-wlr/` |
| browser | `firefox` | default in `~/.config/mimeapps.list`; palette chrome via `firefox/user.js` + rendered `userChrome.css` |
| power | `tlp` (power-profiles-daemon masked), `thermald` | `system/tlp.d/10-thinkpad.conf` |
| fonts | `inter-font`, `ttf-jetbrains-mono-nerd` | |
| GTK apps | Adwaita(-dark) + color-scheme from the palette (portal) | `gtk-3.0/`, `gtk-4.0/`, `theme/hooks/gtk.sh` |

## Themes

```bash
theme/theme list                 # dark-2026 (default), light-2026, tokyo-night, catppuccin-mocha
theme/theme set tokyo-night      # recolor everything at once (or super+shift+t)
theme/theme import-vscode <theme.json file or URL> <name>   # also import-omarchy, import-base24
theme/theme install-greeter      # login screen follows the active palette (sudo)
```

Running apps that can reload pick the new colors up at once (mango, bar, mako, wallpaper, OSD);
foot, GTK apps and Firefox use them from their next start. Details: `THEME.md`.

## Install

```bash
git clone <this repo> ~/dotfiles/mango
~/dotfiles/mango/system/setup.sh   # packages, remove swaync, TLP, xdg-user-dirs (sudo)
~/dotfiles/mango/link.sh           # symlinks + enables user units (idempotent)
```

`link.sh` links: `.`→`~/.config/mango`, `foot rofi mako swaylock wlogout mangobar gtk-3.0 gtk-4.0 environment.d
xdg-desktop-portal xdg-desktop-portal-wlr` → `~/.config/<name>`, and each `systemd/user/*.service`
→ `~/.config/systemd/user/`. It also links `fastfetch/config.jsonc` + `logo.png` into `~/.config/fastfetch/`
and `firefox/user.js` + `userChrome.css` into the active Firefox profile, renders the palette (`theme init`),
and installs the Claude Code/opencode themes, selecting them in `~/.claude/settings.json` and
`~/.config/opencode/cli.json` only if no theme was chosen there. Existing real files are moved to
`*.bak.<ts>`, never deleted.

## fastfetch

`fastfetch` shows a perler-bead Godzilla (sixel, drawn by foot) next to a short system summary in
the palette's colors. `fastfetch/logo.png` was made from a photo of the beadwork: cropped to the
beads, box-downsampled to one pixel per bead (72x110), reduced to 6 colors, scaled up 6x with
nearest-neighbour. Your other presets in `~/.config/fastfetch/` are left alone (link.sh links only
`config.jsonc` and `logo.png`). Run it from an open terminal: started in the same instant a window
opens, it can read the size before mango tiles the window and stretch the logo.

## Session startup

Mango imports `WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_* MANGO_INSTANCE_SIGNATURE`
into systemd/dbus, then starts `mango-session.target` → `graphical-session.target`. All daemons are
user units `WantedBy=graphical-session.target` with `Requisite=` so they never start outside a
session: `mangobar swaybg mako swayidle swayosd polkit-agent wlsunset wl-clip-persist cliphist
blueman-applet`. There is no `exec_once` autostart.

- env for mango children: `env.conf` (reset on reload, relogin to change)
- env for units: `environment.d/10-wayland.conf` (relogin)
- debug: `systemctl --user --failed`, `journalctl --user -b -u mangobar`

## Keybindings

| keys | action |
|---|---|
| alt+return | foot |
| alt+space / super+d | rofi launcher |
| super+return | firefox |
| super+v | clipboard history |
| alt+q / super+shift+q | close window |
| alt+arrows | focus |
| super+left/right | previous/next tag |
| ctrl+1..9 / alt+1..9 | view tag / move window to tag |
| super+n | next layout |
| ctrl+alt+a / Print | screenshot region / full (clipboard + ~/Pictures/Screenshots) |
| super+j | toggle screen recording (~/video) |
| super+l | lock |
| super+escape | power menu |
| super+shift+t | theme picker (rofi) |
| ctrl+alt+\\ / ctrl+alt+backspace | restore last / dismiss all notifications |
| ctrl+alt+shift+\\ | toggle do-not-disturb |
| super+h | toggle bar |
| super+r | reload config (also auto-reloads on save) |
| super+m | log out (stops session services, then quits mango) |
| media / brightness / mic-mute keys | swayosd + playerctl (`bindl`, work while locked) |

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

## Greeter (sysc-greet)

`greeter/` holds everything the login screen uses; `system/setup.sh` installs it (sudo):

| file | installed to | purpose |
|---|---|---|
| `themes/mango.toml` (rendered) | `/var/lib/greeter/.config/sysc-greet/themes/` | theme "Mango" = the active palette's colors (greeter runs as `greeter`, can't read `/home`) |
| `ascii_configs/mango.conf` | `/usr/share/sysc-greet/ascii_configs/` + copy in `/usr/local/share/sysc-greet/` | stock mango profile with a ringed planet as variant 1 (Page Up/Down cycles) |
| `sysc-greet-mango-profile.hook` | `/etc/pacman.d/hooks/` | restores the profile after sysc-greet upgrades |
| `wallpapers/sysc-greet-mango.png` (rendered) | `/usr/share/sysc-greet/wallpapers/` | theme wallpaper in the palette's colors (shown while the greeter starts) |
| `preferences.json` | `/var/lib/greeter/.cache/sysc-greet/preferences` | starting choice: theme Mango, Higgs Field background, Mango session |

`theme/theme install-greeter` renders the theme and the wallpaper (`greeter/make-wallpaper.sh`,
ImageMagick) from the active palette and installs both; re-run it after `theme set` to follow.
The ASCII art comes from `greeter/make-planet.py` (theme-mapped SGR colors). Change background
or theme any time with **F1** at the greeter.

## Idle

dim at 4 min → lock at 5 min → panel off at 10 min; lock before suspend and on `loginctl lock-session`.
swaylock starts only if not already running, and `KillMode=process` keeps it alive if swayidle restarts.

## Verify

```bash
theme/theme lint
mango -c ~/.config/mango/config.conf -p && echo ok
foot --check-config
makoctl reload
systemctl --user status mango-session.target graphical-session.target
systemctl --user show-environment | grep -E 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|MANGO_INSTANCE'
busctl --user list | grep -iE 'portal|Notifications'
systemctl --user --failed
wpctl status
```

# Session

**greetd** starts sysc-greet (see [greeter](apps/greeter.md)); logging in starts mango.

Mango imports `WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_* MANGO_INSTANCE_SIGNATURE`
into systemd and dbus, then starts `mango-session.target` → `graphical-session.target`. Every daemon is
a user unit with `PartOf=`/`After=`/`Requisite=graphical-session.target` and
`WantedBy=graphical-session.target`, so none starts outside a session: waybar, swaybg, mako,
swayidle, swayosd, polkit-agent, wlsunset, wl-clip-persist, cliphist, blueman-applet.
There is **no `exec_once` autostart**, on purpose; add new daemons as units the same way.

- Environment for mango's children: `mango/.config/mango/env.conf` (reset on reload; relogin to change).
- Environment for units: `mango/.config/environment.d/10-wayland.conf` (relogin). A variable both
  need goes in both files.
- Wayland is the only session (`/usr/share/wayland-sessions/mango.desktop`; no X sessions) and the
  default backend: GTK, SDL 3 (and SDL 2 through sdl2-compat), Firefox and Electron pick it on
  their own; Qt gets `QT_QPA_PLATFORM=wayland;xcb`. XWayland stays for X-only programs; Java
  AWT/Swing is one, and `_JAVA_AWT_WM_NONREPARENTING=1` keeps its windows from staying blank.
- Logout (super+m) runs `mango-quit`: it stops `graphical-session.target` *before*
  `mmsg dispatch quit`, so units don't die with display errors.
- The bar toggle (super+h, `waybar-toggle`) starts and stops `waybar.service`.
- The repo's units are links in `~/.config/systemd/user/`. systemd treats a linked unit file as
  "linked", and `systemctl --user disable` (or `reenable`) **deletes that link**. Stop units with
  `systemctl --user stop`; to change which units run, change the repo and run `./install.sh`. It
  restarts a running unit whose file changed, so the change applies at once.
  If a link went missing, `./install.sh --check` reports it and `./install.sh --link` restores it.
- `mmsg` is mango's IPC: `mmsg dispatch <action>`, `mmsg get all-monitors|all-devices`.

## Idle

swayidle (`swayidle/.config/systemd/user/swayidle.service`): dim at 4 min (dimland) → lock at 5 min
(swaylock) → panel off at 10 min (`mmsg dispatch sleep_monitor`); lock before suspend and on
`loginctl lock-session`. swaylock starts only if not already running (`pidof -q swaylock ||`), and
`KillMode=process` keeps it alive if swayidle restarts. Keep both.

## Debugging

```bash
systemctl --user --failed
journalctl --user -b -u waybar        # any unit
systemctl --user status mango-session.target graphical-session.target
systemctl --user show-environment | grep -E 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|MANGO_INSTANCE'
busctl --user list | grep -iE 'portal|Notifications'
mango -c ~/.config/mango/config.conf -p && echo ok
```

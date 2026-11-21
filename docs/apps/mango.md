# mango

The compositor (mangowm 0.18): config, keybindings, window rules, the session environment and its helper commands.

`config.conf` sources `colors.conf` (rendered) and `env.conf bind.conf rule.conf monitor.conf tag.conf`; `bind.conf` defines `var=` shortcuts (`$term $launcher $locker $browser`) before use. Mango re-reads its config on save (also super+esc r). Tiled windows meet edge to edge (`gap_inner_*=0` in `config.conf`), like tmux or Neovim panes; the outer gaps are 7px all round: under the status bar at the top, over the media bar at the bottom (waybar, both full width) and at the sides. There are no gap keybindings.

Borders are drawn like tmux's pane lines: 2px, square corners (mango rounds every corner off the screen edge, so a radius would leave a hole where touching windows meet), a muted Viewport cyan line (`vp_cyan` mixed 55% toward `vp_bar`) on inactive windows and `vp_signal` on the focused one. No other state takes `vp_signal`, and none takes a hue it has not earned: descriptive window states (maximized, on top, scratchpad) share `vp_text`; a pinned window, which shows on every tag until unpinned, is `vp_warn` (like its chip on the bar), so a pin is never a surprise; a window asking for you now (urgent) is `vp_crit` (like its tag on the bar). A lone window has no border (`no_border_when_single=1`). Every window is fully opaque (`unfocused_opacity=1.0`): the border alone marks focus. The tab bar follows the same Viewport rule (2px, square, `vp_bar` background, `vp_signal` focused tab). mango colors a pinned window's border only while it has focus, and a lone window has no border, so a pin also shows on the bar. So do windows kept on top and minimized ones, which nothing else shows: their binds go through `mango-state` (pin, on top, minimize, restore, the minimized scratchpad), which signals waybar's window-state chip (pinned n · on top n · minimized n; click: unpin all, nothing on top).

No hidden triggers: no hot corner (`enable_hotarea=0`; it opened the overview at the bottom-left corner, where the bar's launcher button is), and an app asking for focus turns urgent (`vp_crit` border, its tag marked) instead of taking focus mid-typing (`focus_on_activate=0`). `mango-quit` is the logout (see [Session](../session.md)); `mango-monitor` is the glue for what mango does differently from sway: `sync` mirrors the laptop panel's off state into a rule mango keeps across reloads, `toggle` is super+m p, and `sleep`/`wake` power displays off at idle without way-displays undoing it or logind suspending a closed laptop (`hold-lid` is the inhibitor's internal holder, `stop-hook` way-displays.service's `ExecStopPost`) (see [way-displays](way-displays.md) and the [design](../designs/displays.md)). Caps Lock is Escape.

Keybindings: the modifier names the group (super go/open, +shift carry, +alt window state, +ctrl layout), and three rare groups are two-step mango key modes (super+esc session, super+n notifications, super+m monitor); super+r opens a resize mode that stays open (niri's keys: [ ] width, - = height, through `mango-resize`, which picks the sign that grows the focused window: on a tiled window mango's `resizewin` moves a shared edge, so one sign grows a window and shrinks its neighbor); see [Keybindings](../keybindings.md) and the [design](../designs/keybindings.md). `mango-keys` (super+/) toggles `mango-keys-ui`: a centered LuaJIT (`lua51-lgi` + `gtk-layer-shell`) GTK3 Viewport overlay (`keys.css`) over every bind in `bind.conf`, ranking in-process on each keystroke (whole words, prefixes, missing letters, typos, synonyms, key names) with square `0px` CAD keycaps, Walker-matched selected rows (`2px` `vp_signal` rail + `vp_cyan` 14% fill + `1px` cyan bottom edge), and the selected row's group card beside it. In `bind.conf`, a `## ` line starts a group, a `#: ` line describes the bind below it, and words after ` ~ ` are extra search terms. `mango-whichkey.service` is a LuaJIT (`lua51-lgi` + `gtk-layer-shell`) GTK3 layer-shell daemon that follows `mmsg watch keymode` asynchronously and renders the open group's keys (`mango-keys --pango`) with matching square CAD keycaps in a bottom-center non-focusable (`KeyboardMode.NONE`) Viewport overlay until the mode ends; `mango/reload.sh` sends `SIGUSR1` to hot-reload its CSS on `theme set`, and waybar's `mango/keymode` shows the armed mode's name.

Input: the touchpad is on (`disable_trackpad=0`) with tap-to-click and tap-and-drag but no drag lock, which held a tap-drag after the finger lifted. The TrackPoint (Elan, behind the touchpad's RMI4 pass-through) sometimes loses sync (`psmouse serio2: TrackPoint ... lost synchronization`, kernel bug 209167) and the driver reconnects it, which can drop a held button; if the pointer sticks in scroll or drag, capture `sudo libinput debug-events --device /dev/input/event14` while it happens.

Every animation lasts 150 ms (9 frames at 60 Hz) on one curve, a quadratic ease-out with no overshoot (`0.5,1,0.89,1`). Fades start at 0.5 (opening) and 0.6 (closing) opacity; zooms grow from 0.1 and shrink to 0.6 of full size. Both blur (`blur=0`, `blur_layer=0`) and shadows (`shadows=0`) are off: every Viewport overlay (`walker`, `mango-keys`, `swaync-control-center`, `swaync-notification-window`, `mango-whichkey`, `swayosd`, `logout_dialog`) is a 100% opaque `vp_bar` panel framed by a `1px` cyan ring, so layer blur does zero visual work and staying off saves GPU passes. `rule.conf` sets per-layer open/close animations (`zoom` for `walker` and `mango-keys`, `fade` for `swaync-*`, `mango-whichkey`, `swayosd`, and `logout_dialog`). On a busy test workload, 150 ms durations alone halved mango's CPU time (2.51 to 1.24 percent) and the GPU's busy time (11.4 to 6.5 percent); why these values: [design](../designs/mango-animations.md).

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`mango/packages`): `mangowm`, `wlr-randr` (mango-monitor), `wev` (key names for bind.conf), `xorg-xrdb` (monitor.conf: Xft.dpi for XWayland apps (exec_once)), `luajit` (mango-whichkey Lua runtime), `lua51-lgi` (mango-whichkey GTK3/GtkLayerShell GObject bindings), `gtk-layer-shell` (mango-whichkey Wayland layer-shell overlay)

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/environment.d/10-wayland.conf`
- `~/.config/mango/bind.conf`
- `~/.config/mango/colors.conf`
- `~/.config/mango/config.conf`
- `~/.config/mango/env.conf`
- `~/.config/mango/keys.css`
- `~/.config/mango/monitor.conf`
- `~/.config/mango/rule.conf`
- `~/.config/mango/tag.conf`
- `~/.config/mango/whichkey-colors.css`
- `~/.config/mango/whichkey.css`
- `~/.config/systemd/user/mango-whichkey.service`
- `~/.config/user-tmpfiles.d/mango-monitor.conf`
- `~/.local/bin/mango-keys`
- `~/.local/bin/mango-keys-ui`
- `~/.local/bin/mango-monitor`
- `~/.local/bin/mango-quit`
- `~/.local/bin/mango-resize`
- `~/.local/bin/mango-state`
- `~/.local/bin/mango-whichkey`

**Rendered from the palette** (`theme`):

- `mango/.config/mango/colors.conf.tmpl` → `mango/.config/mango/colors.conf`: `bg_desktop`, `name`, `shadow`, `slug`, `vp_bar`, `vp_crit`, `vp_cyan`, `vp_dim`, `vp_signal`, `vp_text`, `vp_warn`
- `mango/.config/mango/whichkey-colors.css.tmpl` → `mango/.config/mango/whichkey-colors.css`: `name`, `slug`, `vp_bar`, `vp_cyan`, `vp_dim`, `vp_magenta`, `vp_orange`, `vp_signal`, `vp_text`

**User units** (enabled by `install.sh --units`): `mango-whichkey.service`

**`reload.sh`** (run by `theme set`): reload mango so colors.conf applies and signal mango-whichkey to reload CSS. Outside a mango session (no IPC socket) there is nothing to reload.
<!-- end generated -->

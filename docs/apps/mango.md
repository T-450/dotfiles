# mango

The compositor (mangowm 0.18): config, keybindings, window rules, the session environment and its helper commands.

`config.conf` sources `colors.conf` (rendered) and `env.conf bind.conf rule.conf monitor.conf tag.conf`; `bind.conf` defines `var=` shortcuts (`$term $launcher $locker $browser`) before use. Mango re-reads its config on save (also super+esc r). Tiled windows meet edge to edge (`gap_inner_*=0` in `config.conf`), like tmux or Neovim panes; the outer gaps are 7px all round: under the full-width bar at the top, at the sides and above the screen's bottom edge. There are no gap keybindings.

Borders are drawn like tmux's pane lines: 2px, square corners (mango rounds every corner off the screen edge, so a radius would leave a hole where touching windows meet), a grey line (`border_inactive` mixed toward `fg_muted`) on every window and the `accent` on the focused one: after the NuPhy Air60 HE, where color is rare and marks the keys you act on, the accent is the one thing that says "here". No other state takes the accent, and none takes a hue it has not earned: the states that only describe a window (maximized, on top, scratchpad) share `fg_bright` (the aluminium white); a pinned window, which shows on every tag until unpinned, is `warning` (amber, like its chip on the bar), so a pin is never a surprise; a window asking for you now (urgent) is `error` (rose, like its tag on the bar); `success` is for outcomes only. A lone window has no border (`no_border_when_single=1`). Every window is fully opaque (`unfocused_opacity=1.0`): the border alone marks focus. The tab bar follows the same rule (2px, square); its focused tab is the focused row (`selection_bg`/`selection_fg`), as in every list. mango colors a pinned window's border only while it has focus, and a lone window has no border, so a pin also shows on the bar. So do windows kept on top and minimized ones, which nothing else shows: their binds go through `mango-state` (pin, on top, minimize, restore, the minimized scratchpad), which signals waybar's window-state chip (pinned n · on top n · minimized n; click: unpin all, nothing on top).

No hidden triggers: no hot corner (`enable_hotarea=0`; it opened the overview at the bottom-left corner, where the bar's launcher button is), and an app asking for focus turns urgent (rose border, its tag marked) instead of taking focus mid-typing (`focus_on_activate=0`). A lone window has no border (`no_border_when_single=1`). Every window is fully opaque (`unfocused_opacity=1.0`): the border alone marks focus. The tab bar follows the same rule (2px, square, green focused tab). `mango-quit` is the logout (see [Session](../session.md)); `mango-monitor` is the glue for what mango does differently from sway: `sync` mirrors the laptop panel's off state into a rule mango keeps across reloads, `toggle` is super+m p, and `sleep`/`wake` power displays off at idle without way-displays undoing it or logind suspending a closed laptop (`hold-lid` is the inhibitor's internal holder, `stop-hook` way-displays.service's `ExecStopPost`) (see [way-displays](way-displays.md) and the [design](../designs/displays.md)). Caps Lock is Escape.

Keybindings: the modifier names the group (super go/open, +shift carry, +alt window state, +ctrl layout), and three rare groups are two-step mango key modes (super+esc session, super+n notifications, super+m monitor); super+r opens a resize mode that stays open (niri's keys: [ ] width, - = height, through `mango-resize`, which picks the sign that grows the focused window: on a tiled window mango's `resizewin` moves a shared edge, so one sign grows a window and shrinks its neighbor); see [Keybindings](../keybindings.md) and the [design](../designs/keybindings.md). `mango-keys` (super+/) is the cheatsheet: a floating Ghostty (`com.mitchellh.ghostty-keys`) running fzf over every bind in `bind.conf`, searched on each key press by `mango-keys --rank` (whole words, prefixes, missing letters, one typo, synonyms, key names), with the selected row's group drawn as keycaps in the preview pane. In `bind.conf`, a `## ` line starts a group, a `#: ` line describes the bind below it, and words after ` ~ ` are extra search terms. Group names are muted lowercase labels and the keycaps are the keyboard's neutrals (the palette's `[keycaps]`, `THEME_KEY_*`); color marks only the selection (the `accent` pointer and mark, the selected row's action key on `key_accent`) and the letters a search matched (`link`). `mango-whichkey.service` follows `mmsg watch keymode` and shows the open group's keys as a mako popup (`mango-keys --pango`) until the mode ends; waybar's `mango/keymode` shows the mode's name.

Input: the touchpad is on (`disable_trackpad=0`) with tap-to-click and tap-and-drag but no drag lock, which held a tap-drag after the finger lifted. The TrackPoint (Elan, behind the touchpad's RMI4 pass-through) sometimes loses sync (`psmouse serio2: TrackPoint ... lost synchronization`, kernel bug 209167) and the driver reconnects it, which can drop a held button; if the pointer sticks in scroll or drag, capture `sudo libinput debug-events --device /dev/input/event14` while it happens.

Every animation lasts 150 ms (9 frames at 60 Hz) on one curve, a quadratic ease-out with no overshoot (`0.5,1,0.89,1`). Fades start at 0.5 (opening) and 0.6 (closing) opacity; zooms grow from 0.1 and shrink to 0.6 of full size. Blur is on only under the few translucent surfaces, like the keyboard's few translucent keys: the launcher and menus (rofi), notifications and the which-key popup (mako), all 85% opaque, and the cheatsheet; the blur halves the brightness behind them (`blur_params_brightness=0.5`), so text keeps AA even over a white page, and its noise dither keeps the gradients from banding. Everything else is opaque, and `rule.conf` turns blur off for the bar, OSD, power menu and the screenshot selection. There are no shadows (`shadows=0`): after the Quiet Instrument philosophy behind Anodized Keylight, overlays float as raised panels on the same dark ground, told apart by tone, and the blur behind the translucent ones deepens the darkness around them instead. (A layer shadow would also outline a layer's whole surface, not what it draws: rofi's spans the screen above the bar.) `blur` and `shadows` are master switches: `blur_layer` and `layer_shadows` do nothing without them. On a busy test workload, 150 ms durations alone halved mango's CPU time (2.51 to 1.24 percent) and the GPU's busy time (11.4 to 6.5 percent), measured before shadows were turned on; the full change was not measured. Why these values: [design](../designs/mango-animations.md).

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`mango/packages`): `mangowm`, `wlr-randr` (mango-monitor), `wev` (key names for bind.conf), `xorg-xrdb` (monitor.conf: Xft.dpi for XWayland apps (exec_once))

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/environment.d/10-wayland.conf`
- `~/.config/mango/bind.conf`
- `~/.config/mango/colors.conf`
- `~/.config/mango/config.conf`
- `~/.config/mango/env.conf`
- `~/.config/mango/monitor.conf`
- `~/.config/mango/rule.conf`
- `~/.config/mango/tag.conf`
- `~/.config/systemd/user/mango-whichkey.service`
- `~/.config/user-tmpfiles.d/mango-monitor.conf`
- `~/.local/bin/mango-keys`
- `~/.local/bin/mango-monitor`
- `~/.local/bin/mango-quit`
- `~/.local/bin/mango-resize`
- `~/.local/bin/mango-state`
- `~/.local/bin/mango-whichkey`

**Rendered from the palette** (`theme`):

- `mango/.config/mango/colors.conf.tmpl` → `mango/.config/mango/colors.conf`: `accent`, `bg_desktop`, `bg_surface`, `border_inactive`, `error`, `fg_bright`, `fg_secondary`, `name`, `selection_bg`, `selection_fg`, `shadow`, `slug`, `warning`

**User units** (enabled by `install.sh --units`): `mango-whichkey.service`

**`reload.sh`** (run by `theme set`): reload mango so colors.conf applies. Outside a mango session (no IPC socket) there is nothing to reload.
<!-- end generated -->

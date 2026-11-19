# waybar

Two 30px bars frame the screen like an SGI CAD viewport: a status line at the top with a ruler on its edge, and a media bar at the bottom, the viewport's floor, with the axis triad, cava ribbons around the player, and the CLUT key. Both use the same bar color, the same pixel face, and the same hues with the same jobs.

## Look

- The top bar is 30px, full width, in `bar`: near-black on a dark palette (the desktop 60% toward black), the desktop itself on a light one, where a darker bar would sit under type made legible on the desktop. `colors.css.tmpl` picks with GTK's `mix()` and the palette's `prefer_dark` (1 or 0).
  - Its bottom edge is a ruler: a 1px `cyan` 45% rule, ticks every 8px (2px tall, 25%) and every 32px (4px tall, 55%), in step with the desktop's 32px dot grid. These are two `linear-gradient` layers and an inset shadow on `window#waybar.top > box` (waybar puts the bar's position on its window as a class; a bar `name` would also rename its layer, which mango's `layer_name:waybar` rule matches).
  - Mango's 7px outer gaps keep windows 7px from it and from the sides.
- Type, not keys: Terminess Nerd Font throughout (`fonts/packages`).
  - Values are 14px bold, the time and the λ 16px bold.
  - Labels are 12px capitals spaced 1px (`NET`, `VOL`, `WED`, `18 NOV`) in the value's color: they differ by size and weight, not by tone.
  - Values use tabular figures.
- Status chips are a label and a value, 20px tall, with a 7px registration cross (`cyan` 70%) in front of every chip after the first.
- Tags are 24x20 keys of type:
  - occupied: `text` bold
  - empty: `dim` regular
  - the viewed tag: a `signal` block with its number in `bar` and a 7px glow
  - an urgent tag: `crit` in a 1px `crit` outline with a glow
- Dividers are 1x12 rules (`cyan` 70%). The clock is centered: day and date as `cyan` labels around the time, in `text` with a `cyan` phosphor glow.
- Roles come from `colors.css.tmpl`, each kept legible on the desktop (`|legible`). No color literal lives in `style.css`. The roles: `bar`, `text`, `dim`, `cyan`, `magenta`, `orange`, `green`, `warn`, `crit`, `signal`, `grid`, `clut0`..`clut15`, `sel`, `selfg`.
- Hover, on everything clickable, is a 14% `cyan` fill with a 1px `cyan` bottom edge, the type in `text`.
  - Power under the pointer is `crit`, with a 16% `crit` fill and a `crit` edge.
  - Custom modules match hover on their wrapping box (`box:hover > #custom-…`): waybar puts the hover state on the box, and GTK3 doesn't pass it down to the label.
- Tooltips open 6px under the bar, square, `bar` with a 1px `cyan` 45% ring, and stay 7px from the screen's ends. GTK places the tooltip window itself and ignores CSS margins on it, so the window is transparent and the visible box is its inner box, whose margins are the offsets.

## Color

Each hue has one job across both bars:

| color | role | job | where |
|---|---|---|---|
| `cyan` | `ansi6` | chrome and telemetry | chip labels and values, the ruler and rules, the layout glyph, day and date, bluetooth while connected; on the media bar the rule, prev/next and the track time |
| `text` | `fg_editor` toward `fg_bright` | the one fact in focus | occupied tags, the focused window, the time, power; the track title |
| `dim` | `fg_editor` toward `fg_muted` | empty, off or in the background | empty tags, other windows, icons at rest, muted, offline |
| `orange` | `warning` toward `error` (0.4) | action | the λ, an armed key mode, night light held warm; play |
| `magenta` | `ansi5` | someone else's state | window states, held notifications; the artist |
| `signal` | `accent` | the one place you are | the viewed tag, the focused window's underline |
| `warn` block | `warning`, `bar` type | high, or a standing exception | cpu from 85%; memory and disk from 80%; temperature from 80 C; battery at 20% and below on battery; the window-state chip while a window is pinned |
| `crit` | `error` | critical, irreversible, or asking now | a crit block: memory and disk from 90%, temperature from 95 C, battery at 10% and below on battery; an urgent tag; a held critical notification (bell, count and dot); recording in progress; power under the pointer |
| `green` | `success` | being fixed | the battery chip while charging, plugged in or full; the triad's Y axis |
| `clut0`..`clut15` | `ansi4` to `error` through `ansi6`, `success`, `warning`, orange | energy | the ribbons and the CLUT key |

Cpu has no critical tier: full load is work, not a failure. The battery label says which state it is in: `BAT` on battery, `CHG` charging, `AC` plugged in or full. A chip fades between states over 150 ms, mango's animation time. The key-mode and window-state chips exist only while their state does, so their presence is the message: bold type in a 1px outline of their color. The exception is a pinned window: it shows on every tag until unpinned, so its chip is a `warn` block.

All roles assume a dark palette, and every palette here is one. The bar is the desktop mixed 60% toward black.

## Modules

Left: `custom/start` (the λ, the shell prompt's, set in type; click: `rofi -show drun`), mango's four tags (`mango/workspaces`, `tag_num=4`; click views, right-click toggles), tag 0, mango's special tag (`custom/special`: `.active` while it is shown over the view, occupied while it holds windows; click toggles it), a rule, the layout glyph (`custom/layout`, fed by `waybar-layout`; click: `mmsg dispatch switch_layout`), the key-mode and window-state chips while they exist, and the windows in view (`custom/win#1..6`): every visible window's title, oldest first, cut at 32 characters, the focused one in `text` bold on a 1px `signal` underline, the rest `dim`. Mango has no wlr-foreign-toplevel-management, so waybar's taskbar can't run: `waybar-windows` follows `mmsg watch all-clients` and signals the slots; a click focuses that window and the wheel moves focus.

Center: the clock (`group/datetime`): day (`custom/day`, `date '+%^a'`: waybar's clock can't upper-case), time (its tooltip is the CALENDAR line with the month calendar below it), date (`custom/date`, `date '+%-d %^b'`, because waybar's clock zero-pads the day).

Right: recording (`custom/record`, only while `gpurecord` prints), then the status chips: network (`NET` and the SSID, ellipsized after 16 characters; `OFFLINE`; click: download and upload speeds), volume (`VOL`, `MUTE`; click, right, middle: mute; scroll 5%), cpu (`CPU`), memory (`MEM`), temperature (`TMP`), disk (`DSK`, `/`), battery (`BAT`/`CHG`/`AC`; click: wlogout). Values are percent, temperature degrees C. Then a rule and the icons, 14px, `dim` at rest and `text` under the pointer: night light (`custom/nightlight`; automatic rests, warm is `orange`, off is faded; click toggles, right-click menu; see [wlsunset](wlsunset.md)), wallpaper (`custom/wallpaper`; click: waypaper), bluetooth (`bt-off` glyph when off; the icon and count in `cyan` while connected; click: blueman-manager), the tray, the notification bell (`custom/notifications`; the bell and count in `magenta` while notifications are held), and power (`custom/power`; click: wlogout) in the corner.

Power is the one control that ends the session, so it reads apart by place: the corner, 7px further in than the rest, in `text`; under the pointer it turns `crit`. Do-not-disturb is the bell's right-click only.

## The media bar

The second bar in `config.jsonc`: `"position": "bottom"`, 30px, `"layer": "top"`, the status bar's layer. `style.css` scopes it by waybar's position class, `window#waybar.bottom`: the same `bar` fill, with a 1px `cyan` 45% rule on its top edge facing the status bar's ruler. Every output gets one, like the status bar, so each screen runs two cava (passive: see Ribbons).

Left to right:

- `custom/triad`: the XYZ axis triad, 40px (the λ's width above it), drawn by `icons/triad-symbolic.svg` with its axes in palette slots: X `orange`, Y `green`, Z `cyan`, the origin `text`.
- `cffi/ribbons#left`: the left channel's ribbon, lows toward the player (`"channel": "left"`, `"expand": true`). With `expand-left`/`expand-right` on the bar, both ribbons fill the room the centered player leaves.
- The player: waybar's `mpris` module once per part (`mpris#prev`, `#play`, `#next`, `#title`, `#artist`, `#time`), each instance id a CSS class, so each part has its own color. Prev and next are `cyan` 70% (chrome), play `orange` (the action); a button shows its action, so play shows pause while playing (`#mpris.play.playing`). The title is `text` (20 characters), the artist `magenta` (14) after a 5x1 `cyan` 55% dash (a CSS gradient in its left padding), the time `cyan`. A click on prev or next runs `playerctl previous`/`next`; on any other part waybar's default plays or pauses. The parts hide while no player runs.
- `cffi/ribbons#right`: the right channel's ribbon.
- `custom/clut`: the CLUT key, the ribbons' 16 colors as a 5x16 strip, low at the bottom (one CSS gradient over `clut0`..`clut15`).

The triad and the CLUT key are zero-width labels with no tooltip, like the icon buttons.

## Tooltips

Every module but the tags (`mango/workspaces` sets none and offers no option) and the day label has a tooltip: one row of NAME, two spaces, VALUE and optionally two spaces and the KEYS, then an optional HINT row. They are Pango markup, written with single quotes so the JSON needs no escaping. The tooltip label is `text`; the dimmer tones are `fgalpha` over the tooltip's `bar` background, without a color literal:

- NAME: `<span font_desc='Terminess Nerd Font 12px' letter_spacing='768' fgalpha='60%'>CPU</span>`. On the bar the same span has no `fgalpha`: `<span font_desc='Terminess Nerd Font 12px' letter_spacing='768'>CPU</span>`.
- VALUE: plain text (14px).
- KEYS: `<span font_desc='Terminess Nerd Font 12px' letter_spacing='768' fgalpha='80%'>SUPER D</span>`: this machine's binds (`mango/.config/mango/bind.conf`), space separated.
- HINT: `\n<span font_desc='Terminess Nerd Font 12px' fgalpha='60%'>Scroll ±5</span>`.

Scripts that print a tooltip (`waybar-temperature`, `waybar-notifications`, `waybar-layout`, `waybar-winstate`, `nightlight status`) build the same markup; text that can hold `& < >` is escaped there (waybar escapes its own placeholders such as `{essid}`).

## Thresholds

Waybar's `states` give a chip one class at a time: cpu `warning` from 85; memory and disk `warning` from 80 and `critical` from 90; battery `warning` at 20 and `critical` at 10 (battery states count down). Waybar's temperature module ignores `states`, so the chip is `custom/temperature`: `waybar-temperature` prints `high` from 80 C or `critical` from 95 C (the package throttles at 100). `style.css` turns `warning`/`high` into the `warn` block and `critical` into the `crit` block, and turns the battery `green` while it charges or is plugged in.

The registration cross sits in a 19px transparent left border of each chip after the first. The cross layer paints the border box (`background-origin`/`background-clip: border-box`) and the fill layer only the padding box, so a block never fills behind its cross. The cross is a palette-slot path (`class="success"`, `-gtk-icon-palette: success alpha(@cyan, 0.7)`), so it stays `cyan` 70% whatever the chip's color.

## Icons

Icons are `-gtk-recolor()` background layers (`icons/*-symbolic.svg`, `layouts/<symbol>-symbolic.svg`). GTK's symbolic loader fills every shape, so a stroked path needs `class="stroke"` in the SVG; `class="success"` puts a path in the `success` palette slot, which `-gtk-icon-palette` colors apart from the label (the registration cross, bluetooth's mark, which follows `currentColor`).

Icon-only buttons carry a zero-width space (`​`) as their label: waybar hides a module whose format is empty, so the label stays non-empty and invisible while the SVG is the background.

## Ribbons

The media bar's visualizer is `waybar-ribbons` (`waybar/pkg/waybar-ribbons`), a waybar CFFI module in C installed to `/usr/lib/waybar-ribbons/ribbons.so`.

- Each instance (`cffi/ribbons#left`, `#right`) draws one channel as a twisted wireframe ribbon in a `GtkGLArea`. One fragment shader (`ribbons.frag`, embedded at build time) measures each pixel's distance to 9 strands. Per frame, only the spectrum goes to the GPU.
- The look comes from SGI CAD viewports:
  - the width follows the energy
  - depth-cued strands, with a stippled far side
  - rungs every 15px and a 10% surface
  - a specular edge in `text` where the ribbon faces you
  - a phosphor glow on its edges
  - a dotted floor in `grid`
- Color by energy comes from `clut0`..`clut15`. The module reads them, `grid` and `text` from the GTK style context, and again on every style change, so `theme set` recolors the ribbons with the rest of the bar.
- Its one key is `channel` (`left` or `right`). Left is drawn mirrored, so the lows meet at the player.
- Data: each instance runs its own `cava`. The config is written to `$XDG_RUNTIME_DIR/waybar-ribbons/<channel>.conf`: pipewire input, raw binary 16-bit mono output, 48 bars, 30 fps, `sleep_timer = 1`.
- cava's capture node is passive (`active = 0`), so it never keeps the sink awake by itself. Its first-run files go under `$XDG_RUNTIME_DIR/waybar-ribbons` (its `XDG_CONFIG_HOME`), not `~/.config/cava`. It dies with waybar (`PR_SET_PDEATHSIG`).
- A frame equal to the one on screen is not drawn, so silence costs no GPU time.
- If cava exits, the ribbon goes flat and cava starts again after 1s. The delay doubles up to 30s while it keeps failing.
- Waybar's reload stops each instance's cava. Stopping waybar stops them all, since cava runs in waybar.service's cgroup.
- Any change under `waybar/pkg/waybar-ribbons/` bumps `pkgrel`: `install.sh` rebuilds a `pkg/` package only when its version changes.

## Helper scripts

- `waybar-toggle` (super+esc b): stops or starts `waybar.service`.
- `waybar-temperature`: reads the coretemp `Package id 0` sensor (`/sys/devices/platform/coretemp.0/hwmon/hwmon*`) and prints one JSON line: the `TMP` label and the degrees, `high` or `critical`, and a tooltip. Polled every 5s.
- `waybar-notifications`: counts notifications held by mako (`makoctl list -j`) and reads `makoctl mode`; prints the count ("99+" above 99, a zero-width space at 0 so the bell stays) with classes `unread`, `dnd` (do-not-disturb on) and `critical` (a held critical notification). Polled every 2s and refreshed by `pkill -RTMIN+10 waybar` after a click. Bell clicks: restore, middle dismisses all, right toggles do-not-disturb.
- `waybar-winstate`: the window-state chip (custom/winstate): how many windows are pinned to every tag, kept on top or minimized (the alt+esc dropdown isn't counted), their titles in the tooltip, hidden when none is. mango sends no IPC event for these states, so `mango-state` signals it (`RTMIN+11`) and it rechecks every 10s; a click runs `mango-state --clear`.
- `waybar-layout`: streams `mmsg watch monitor $WAYBAR_OUTPUT_NAME` (the first active monitor when unset) through `jq` and prints one JSON line per event: the layout symbol as the class (`style.css` draws the glyph from `#custom-layout.T` etc.) and the LAYOUT tooltip (design name, and the super+ctrl+space hint). It replaces `mango/layout`, which has no tooltip support; waybar restarts it after 1s if mmsg exits.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`waybar/packages`): `waybar`, `pamixer` (volume click/scroll), `cava` (audio spectrum for the media bar's ribbons (pkg/waybar-ribbons))

**Built here** (`waybar/pkg/*/PKGBUILD`, makepkg): `waybar-ribbons`

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/systemd/user/waybar.service`
- `~/.config/waybar/colors.css`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/icons/bell-off-symbolic.svg`
- `~/.config/waybar/icons/bell-symbolic.svg`
- `~/.config/waybar/icons/bt-off-symbolic.svg`
- `~/.config/waybar/icons/bt-symbolic.svg`
- `~/.config/waybar/icons/cross-symbolic.svg`
- `~/.config/waybar/icons/dot-symbolic.svg`
- `~/.config/waybar/icons/moon-symbolic.svg`
- `~/.config/waybar/icons/next-symbolic.svg`
- `~/.config/waybar/icons/pause-symbolic.svg`
- `~/.config/waybar/icons/play-symbolic.svg`
- `~/.config/waybar/icons/power-symbolic.svg`
- `~/.config/waybar/icons/prev-symbolic.svg`
- `~/.config/waybar/icons/record-symbolic.svg`
- `~/.config/waybar/icons/triad-symbolic.svg`
- `~/.config/waybar/icons/wallpaper-symbolic.svg`
- `~/.config/waybar/layouts/center_tile-symbolic.svg`
- `~/.config/waybar/layouts/deck-symbolic.svg`
- `~/.config/waybar/layouts/dwindle-symbolic.svg`
- `~/.config/waybar/layouts/fair-symbolic.svg`
- `~/.config/waybar/layouts/grid-symbolic.svg`
- `~/.config/waybar/layouts/monocle-symbolic.svg`
- `~/.config/waybar/layouts/right_tile-symbolic.svg`
- `~/.config/waybar/layouts/scroller-symbolic.svg`
- `~/.config/waybar/layouts/tile-symbolic.svg`
- `~/.config/waybar/layouts/vertical_deck-symbolic.svg`
- `~/.config/waybar/layouts/vertical_fair-symbolic.svg`
- `~/.config/waybar/layouts/vertical_grid-symbolic.svg`
- `~/.config/waybar/layouts/vertical_scroller-symbolic.svg`
- `~/.config/waybar/layouts/vertical_tile-symbolic.svg`
- `~/.config/waybar/style.css`
- `~/.local/bin/waybar-layout`
- `~/.local/bin/waybar-notifications`
- `~/.local/bin/waybar-temperature`
- `~/.local/bin/waybar-toggle`
- `~/.local/bin/waybar-windows`
- `~/.local/bin/waybar-winstate`

**Rendered from the palette** (`theme`):

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `accent`, `ansi4`, `ansi5`, `ansi6`, `bg_desktop`, `error`, `fg_editor`, `name`, `prefer_dark`, `selection_bg`, `selection_fg`, `slug`, `success`, `warning`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

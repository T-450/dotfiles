# waybar

The bar, at the top: one black strip after a cassette J-card, the card's paired teal and cobalt stripes on its top edge, then a row of type: labels and values with a ★ between them, neutral unless a color has something to say.

## Look

- One 34px strip across the top of the screen, full width: a 2px `stripe_a` line over a 2px `stripe_b` line on its top edge (two inset shadows on `window#waybar > box`), then a 30px row (`padding-top: 4px`). Mango's 7px outer gaps keep windows 7px below it and from the sides.
- Type, not keys: Inter throughout (`inter-font`, `fonts/packages`). Facts are bold (values 12px 600, the time 13px 800, the λ 15px 800); labels are 9px capitals spaced 2px at 55% (`NET`, `VOL`, `WED`, `18 NOV`), the silkscreen of a cassette card. Values use tabular figures.
- Status chips are a label and a value, 20px tall, with a ★ in front of every chip after the first (the card's "★ LOW NOISE ★ HIGH OUTPUT ★").
- Tags are 24x20 keys of type: occupied `text`, empty `dim`, the viewed tag a `signal` block with its number in `bar`, an urgent tag `crit` with a 2px `crit` underline.
- Dividers are 1x12 rules (`rule`). The clock is centered: day and date as labels around the time.
- Roles come from `colors.css.tmpl` (`bar`, `stripe_a`, `stripe_b`, `text`, `dim`, `rule`, `signal`, `held`, `crit`, `tipline`, `sel`, `selfg`), each kept legible on the bar (`|legible`). No color literal lives in `style.css`.
- Hover is a 6% `text` overlay. Custom modules match it on their wrapping box (`box:hover > #custom-…`): waybar puts the hover state on the box, and GTK3 doesn't pass it down to the label.
- Tooltips open 6px under the bar, square, `bar` with a 1px `tipline` ring, and stay 7px from the screen's ends. GTK places the tooltip window itself and ignores CSS margins on it, so the window is transparent and the visible box is its inner box, whose margins are the offsets.

## Color

Color appears only where it carries meaning; a module has no hue of its own. Everything else is `text` (facts: values, occupied tags, the λ, the focused window, the time, power) or `dim` (what is empty, off or in the background: empty tags, other windows, icons at rest, muted, offline). Labels are `text` at 55% (Pango `fgalpha`), so they need no role.

| color | role | means | where |
|---|---|---|---|
| `stripe_a`, `stripe_b` | `accent`, `badge` | the card's stripes | the bar's top edge (one band on a palette whose badge is its accent, like Colibri) |
| `signal` | `accent` | the one thing that matters now | the viewed tag |
| inverted | `text` block, `bar` type | high, or a standing exception | cpu from 85%; memory and disk from 80%; temperature from 80 C; battery at 20% and below on battery; the window-state chip while a window is pinned |
| `crit` | `error` | critical, irreversible, or asking now | a crit block: memory and disk from 90%, temperature from 95 C, battery at 10% and below on battery; an urgent tag; a held critical notification (bell, count and dot); recording in progress; power under the pointer |
| `held` | `badge` | time held by hand | night light forced warm ("warm now"): the screen's colors are not true |

A warning has no hue: the pin has no warm color, and an inverted chip reads on every palette. Cpu has no critical tier (full load is work, not a failure). Charging, plugged in or full, the battery chip stays neutral whatever the charge (low charge is already being fixed); its label says which: `BAT` on battery, `CHG` charging, `AC` plugged in or full. A chip fades between states over 150 ms (mango's animation time). The key-mode and window-state chips exist only while their state does, so their presence is the message: bold type in a 1px `text` outline, except a pinned window, which shows on every tag until unpinned, so its chip is inverted like a warning.

The palette made for this bar is **Cassette** (`theme set cassette`): black card, silver paper, the teal and cobalt stripes. On other palettes the same roles apply.

## Modules

Left: `custom/start` (the λ, the shell prompt's, set in type; click: `rofi -show drun`), mango's four tags (`mango/workspaces`, `tag_num=4`; click views, right-click toggles), tag 0, mango's special tag (`custom/special`: `.active` while it is shown over the view, occupied while it holds windows; click toggles it), a rule, the layout glyph (`custom/layout`, fed by `waybar-layout`; click: `mmsg dispatch switch_layout`), the key-mode and window-state chips while they exist, and the windows in view (`custom/win#1..6`): every visible window's title, oldest first, cut at 32 characters, the focused one in `text`, the rest `dim`. Mango has no wlr-foreign-toplevel-management, so waybar's taskbar can't run: `waybar-windows` follows `mmsg watch all-clients` and signals the slots; a click focuses that window and the wheel moves focus.

Center: the clock (`group/datetime`): day (`custom/day`, `date '+%^a'`: waybar's clock can't upper-case), time (its tooltip is the CALENDAR line with the month calendar below it), date (`custom/date`, `date '+%-d %^b'`, because waybar's clock zero-pads the day).

Right: recording (`custom/record`, only while `gpurecord` prints), then the status chips: network (`NET` and the SSID, ellipsized after 16 characters; `OFFLINE`; click: download and upload speeds), volume (`VOL`, `MUTE`; click, right, middle: mute; scroll 5%), cpu (`CPU`), memory (`MEM`), temperature (`TMP`), disk (`DSK`, `/`), battery (`BAT`/`CHG`/`AC`; click: wlogout). Values are percent, temperature degrees C. Then a rule and the icons, 14px, `dim` at rest and `text` under the pointer: night light (`custom/nightlight`; automatic rests, warm is `held`, off is faded; click toggles, right-click menu; see [wlsunset](wlsunset.md)), wallpaper (`custom/wallpaper`; click: waypaper), bluetooth (`bt-off` glyph when off; the icon and count in `text` while connected; click: blueman-manager), the tray, the notification bell (`custom/notifications`), and power (`custom/power`; click: wlogout) in the corner.

Power is the one control that ends the session, so it reads apart by place: the corner, 7px further in than the rest, in `text`; under the pointer it turns `crit`. Do-not-disturb is the bell's right-click only.

## Tooltips

Every module but the tags (`mango/workspaces` sets none and offers no option) and the day label has a tooltip: one row of NAME, two spaces, VALUE and optionally two spaces and the KEYS, then an optional HINT row. They are Pango markup, written with single quotes so the JSON needs no escaping. The tooltip label is `text`; the dimmer tones are `fgalpha` over the tooltip's `bar` background, without a color literal:

- NAME: `<span font_desc='Inter SemiBold 9px' letter_spacing='2048' fgalpha='55%'>CPU</span>` (the same span is every label on the bar).
- VALUE: plain text (12px).
- KEYS: `<span font_desc='Inter SemiBold 9px' letter_spacing='1024' fgalpha='80%'>SUPER D</span>`: this machine's binds (`mango/.config/mango/bind.conf`), space separated.
- HINT: `\n<span font_desc='Inter 10px' fgalpha='60%'>Scroll ±5</span>`.

Scripts that print a tooltip (`waybar-temperature`, `waybar-notifications`, `waybar-layout`, `waybar-winstate`, `nightlight status`) build the same markup; text that can hold `& < >` is escaped there (waybar escapes its own placeholders such as `{essid}`).

## Thresholds

Waybar's `states` give a chip one class at a time: cpu `warning` from 85; memory and disk `warning` from 80 and `critical` from 90; battery `warning` at 20 and `critical` at 10 (battery states count down). Waybar's temperature module ignores `states`, so the chip is `custom/temperature`: `waybar-temperature` prints `high` from 80 C or `critical` from 95 C (the package throttles at 100). `style.css` turns `warning`/`high` into the inverted chip and `critical` into the crit block, and puts the battery back to neutral while it charges or is plugged in.

The ★ sits in a 19px transparent left border of each chip after the first: the star layer paints the border box (`background-origin`/`background-clip: border-box`) and the fill layer only the padding box, so an inverted or crit chip never fills behind its star. The star is a palette-slot path (`class="success"`, `-gtk-icon-palette: success @dim`), so it stays `dim` whatever the chip's color.

## Icons

Icons are `-gtk-recolor()` background layers (`icons/*-symbolic.svg`, `layouts/<symbol>-symbolic.svg`). GTK's symbolic loader fills every shape, so a stroked path needs `class="stroke"` in the SVG; `class="success"` puts a path in the `success` palette slot, which `-gtk-icon-palette` colors apart from the label (the ★, bluetooth's mark, which follows `currentColor`).

Icon-only buttons carry a zero-width space (`​`) as their label: waybar hides a module whose format is empty, so the label stays non-empty and invisible while the SVG is the background.

## Helper scripts

- `waybar-toggle` (super+esc b): stops or starts `waybar.service`.
- `waybar-temperature`: reads the coretemp `Package id 0` sensor (`/sys/devices/platform/coretemp.0/hwmon/hwmon*`) and prints one JSON line: the `TMP` label and the degrees, `high` or `critical`, and a tooltip. Polled every 5s.
- `waybar-notifications`: counts notifications held by mako (`makoctl list -j`) and reads `makoctl mode`; prints the count ("99+" above 99, a zero-width space at 0 so the bell stays) with classes `unread`, `dnd` (do-not-disturb on) and `critical` (a held critical notification). Polled every 2s and refreshed by `pkill -RTMIN+10 waybar` after a click. Bell clicks: restore, middle dismisses all, right toggles do-not-disturb.
- `waybar-winstate`: the window-state chip (custom/winstate): how many windows are pinned to every tag, kept on top or minimized (the alt+esc dropdown isn't counted), their titles in the tooltip, hidden when none is. mango sends no IPC event for these states, so `mango-state` signals it (`RTMIN+11`) and it rechecks every 10s; a click runs `mango-state --clear`.
- `waybar-layout`: streams `mmsg watch monitor $WAYBAR_OUTPUT_NAME` (the first active monitor when unset) through `jq` and prints one JSON line per event: the layout symbol as the class (`style.css` draws the glyph from `#custom-layout.T` etc.) and the LAYOUT tooltip (design name, and the super+ctrl+space hint). It replaces `mango/layout`, which has no tooltip support; waybar restarts it after 1s if mmsg exits.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`waybar/packages`): `waybar`, `pamixer` (volume click/scroll)

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/systemd/user/waybar.service`
- `~/.config/waybar/colors.css`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/icons/bell-off-symbolic.svg`
- `~/.config/waybar/icons/bell-symbolic.svg`
- `~/.config/waybar/icons/bt-off-symbolic.svg`
- `~/.config/waybar/icons/bt-symbolic.svg`
- `~/.config/waybar/icons/dot-symbolic.svg`
- `~/.config/waybar/icons/moon-symbolic.svg`
- `~/.config/waybar/icons/power-symbolic.svg`
- `~/.config/waybar/icons/record-symbolic.svg`
- `~/.config/waybar/icons/star-symbolic.svg`
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

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `accent`, `badge`, `bg_desktop`, `border_hairline`, `error`, `fg_disabled`, `fg_editor`, `name`, `selection_bg`, `selection_fg`, `slug`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

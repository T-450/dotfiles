# waybar

The bar, at the bottom: one flat "instrument" panel after Teenage Engineering's hardware (OP-1, OP-Z): outlined 28px keys, segmented meters and spaced-capital labels, neutral unless a color has something to say.

## Look

- One square-cornered 44px panel on the bottom edge, 7px in from the sides, with a 1px inset ring (`bar`, `edge`); mango's 7px outer gaps line the windows up with its ends.
- Every control is a 28px key, 4px apart (`spacing`), radius 2, drawn as a 1px `editor` outline at 22% rather than a filled pill. The type is IBM Plex Mono 13 throughout; labels are the silkscreen of a device: 10px capitals spaced 2px (the day and the date) and spaced capitals in every tooltip's NAME.
- Tags are a row of keys: occupied ones carry a 4x4 LED in the top-right corner, empty ones are unlit (a faint outline, a dim number), the viewed tag is the lit key (filled with `signal`, its number in the bar color).
- A chip's meter is a segmented 2px strip (2px on, 1px off) along its bottom edge; the chip icons wear the four OP-1 encoder hues (see Color). Dividers are dotted rules. The clock is the panel's display: one recessed strip with the day and date as spaced capitals around a 15px time.
- Roles come from `colors.css.tmpl` (`bar`, `edge`, `text`, `dim`, `editor`, `signal`, `live`, `held`, `ok`, `warn`, `crit`, `tipline`, `sel`, `selfg`), each kept legible on the bar (`|legible`). No color literal lives in `style.css`.
- Hover is a translucent `editor` overlay. Custom modules match it on their wrapping box (`box:hover > #custom-…`): waybar puts the hover state on the box, and GTK3 doesn't pass it down to the label. Only the tags (real buttons) get the pressed overlay; waybar never sets `:active` on a label.
- Tooltips are a 30px box (bar color, `tipline` ring, radius 2), 8px above the bar and never past its ends. GTK places the tooltip window itself and ignores CSS margins on it, so the window is transparent and the visible box is its inner box, whose margins are the offsets. The clock labels and the tray items carry their own 8px inset (not the group or the tray) because each anchors its tooltip to its own allocation, and GTK3 counts a CSS margin inside it.

## Color

Color appears only where it carries meaning (the Quiet Instrument rule behind Anodized Keylight); a module has no hue of its own. Everything is one of three neutrals: `text` for primary facts (the time, occupied tags, the layout glyph, the window-state and key-mode chips), `editor` for secondary facts and controls (every chip's value, meter and outline), `dim` for labels and whatever is off or empty (day, date, window title, empty tags, muted, disconnected, night light off). The six colors, and every place they appear:

| color | role | means | where |
|---|---|---|---|
| `signal` | `accent` | the one thing that matters now | the viewed tag (the lit key); the focused window's 2px underline |
| `live` | `link` | real time, a live connection | the clock's time; network while connected (icon, name, signal bar); bluetooth while a device is connected |
| `held` | `badge` | time held by hand | night light forced warm ("warm now"): the screen's colors are not true |
| `ok` | `success` | a good outcome in progress | battery while charging |
| `warn` | `warning` | high, or a standing exception | cpu from 85%; memory and disk from 80%; temperature from 80 C; battery at 20% and below on battery; the window-state chip while a window is pinned |
| `crit` | `error` | critical, irreversible, or asking now | an urgent tag; memory and disk from 90%; temperature from 95 C; battery at 10% and below; a held critical notification (count and dot); recording in progress; power under the pointer |

A threshold skin tints the chip 12% and turns its outline to its color. A chip fades between states over 150 ms (mango's animation time) instead of snapping. Cpu has no critical tier (full load is work, not a failure). Plugged in without charging (full, or held at the charge threshold) keeps the bolt and stays neutral. Chips that mark a state get no hue unless the state needs attention: the window-state chip and the key-mode chip exist only while their state does, so their presence is the message; they are `text` at weight 600 in a `text` outline, except a pinned window: it shows on every tag until unpinned, so the chip and its outline turn `warn`, like the pinned window's amber border. Recording keeps `crit` because a capture you forgot is the one state a glance must never miss. Power is a neutral key at rest and set apart by its place; it turns `crit` only under the pointer, where the color says what the click would do.

Each status chip's icon wears one of the four encoder hues of the OP-1 (blue, green, white, orange), cycled so the chips read apart at a glance: audio blue (`ansi4`), cpu green (`ansi10`), memory white (`fg_bright`), temperature orange (`ansi3`, honey on Colibri), disk blue, bluetooth green (`i_*` in `colors.css.tmpl`). A threshold or state color takes the icon over.

## Modules

Left: `custom/start` (a brush λ at 20px in bright green, `lambda`: the shell prompt's λ, mint on Colibri; click: `rofi -show drun`), mango's four tags (`mango/workspaces`, `tag_num=4`; click views, right-click toggles; `.empty` an unlit key, occupied an outlined key with an LED, `.active` the lit key, `.urgent` `crit` ring and LED, the ring pulsing `warn` twice), tag 0, mango's special tag (`custom/special`, one more tag button: `.active` while it is shown over the view, occupied while it holds windows; click toggles it), a divider, the layout button (`custom/layout`, fed by `waybar-layout`; click: `mmsg dispatch switch_layout`), and the windows in view (`custom/windows`): every visible window's title, oldest first, cut at 32 characters, the focused one bright with a 2px `signal` underline, the rest `dim`. Mango has no wlr-foreign-toplevel-management, so waybar's taskbar can't run: `waybar-windows` follows `mmsg watch all-clients` and prints Pango spans, and one module takes one click, so a click opens alt+tab's hints and the wheel moves focus.

Center: the clock display (`group/datetime`): day (`custom/day`, `date '+%^a'`: waybar's clock can't upper-case), time (its tooltip is the design's CALENDAR line with the month calendar kept below it, because the design's calendar is a click popover waybar can't open), date (`custom/date`, `date '+%-d %^b'`, because waybar's clock zero-pads the day).

Right: recording (`custom/record`, only while `gpurecord` prints), then the live chips: network (SSID, max 16 chars; click: speeds), volume (click, right, middle: mute; scroll 5%), cpu, memory, temperature, disk (`/`), battery (click: wlogout). Then a divider and the tray area: night light (`custom/nightlight`; click toggles, right-click menu; see [wlsunset](wlsunset.md)), wallpaper (`custom/wallpaper`; click: waypaper), bluetooth (click: blueman-manager; the count shows while connected) and the tray. Then a divider, the notification bell (`custom/notifications`), a divider, and power (`custom/power`; click: wlogout) in the corner.

Power is the one control that ends the session, so it reads apart by placement: 8px from its divider and 4px further from the bar's end than other modules. It is a neutral key at rest; under the pointer its icon and a 1px ring turn `crit`. Do-not-disturb is the bell's right-click only.

Kept beyond the mockup: recording before the chips, night light and the tray in the tray area, and the power chip's dividers.

## Tooltips

Every module but the tags (`mango/workspaces` sets none and offers no option) and the day label has the design's tooltip: one row of NAME, two spaces, VALUE and optionally two spaces and the KEYS, then an optional HINT row. They are Pango markup, written with single quotes so the JSON needs no escaping. The tooltip label is `@text`; the dimmer tones are `fgalpha` over the tooltip's `bar` background, which reproduces the design's greys without a color literal:

- NAME: `<span font_desc='IBM Plex Mono 10px' letter_spacing='1536' fgalpha='66%'>CPU</span>` (spaced capitals, muted: a device's silkscreen).
- VALUE: plain text (12px).
- KEYS: `<span font_desc='IBM Plex Mono Medium 10px' letter_spacing='1024' fgalpha='82%'>SUPER D</span>`. The design's keycap boxes can't be drawn in Pango, so the keys are plain text, space separated; they are this machine's binds (`mango/.config/mango/bind.conf`).
- HINT: `\n<span font_desc='IBM Plex Mono 10px' fgalpha='66%'>Scroll ±5</span>`.

Scripts that print a tooltip (`waybar-temperature`, `waybar-notifications`, `waybar-layout`, `nightlight status`) build the same markup; text that can hold `& < >` is escaped there (waybar escapes its own placeholders such as `{essid}`).

## Level bars

A chip draws its 2px meter as its first background layer, a segmented `currentColor` pattern (`repeating-linear-gradient`: 2px on, 1px off). Waybar exposes a value only as a `states` class, and a module has one class at a time, so `levels.json` gives each level module one `states` entry per integer (`l0`..`l100`; included by `config.jsonc`, merged into each module) and `levels.css` turns each `.lN` into that layer's `background-size` width. Volume and battery use waybar's `<= value` states, the rest `>= value`. Both files are generated data (one entry per integer): regenerate them rather than edit single lines. `levels.css` also holds the icon ranges and the threshold skins (`warn`, `crit`).

Specificity matters: an `#id` rule outranks a `.lN` class rule, so the shared chip rule in `style.css` sets no `background-size`. The fallback `label { background-size: 0% 2px, ... }` (no level class, no bar) is a bare type selector for the same reason. Rules that must beat a range (`.muted`, `.disconnected`, `.ethernet`, `.charging`, `.critical`) sit after the `@import` at the same id+class specificity.

Waybar's temperature module ignores `states` (its chip never gets an `lN` class), so the chip is `custom/temperature`: `waybar-temperature` prints the class itself, `min(100, C)`, plus `high` from 80 C or `critical` from 95 C (the package throttles at 100).

## Icons

Icons are `-gtk-recolor()` background layers (`icons/*-symbolic.svg`, `layouts/<symbol>-symbolic.svg`). GTK's symbolic loader fills every shape, so a stroked path needs `class="stroke"` in the SVG; `class="success stroke"` puts it in the `success` palette slot, which `-gtk-icon-palette` colors separately (the layout chevron, the bell).

Icon-only buttons carry a zero-width space (`\u200b`) as their label: waybar hides a module whose format is empty, so the label stays non-empty and invisible while the SVG is the background.

## Helper scripts

- `waybar-toggle` (super+esc b): stops or starts `waybar.service`.
- `waybar-temperature`: reads the coretemp `Package id 0` sensor (`/sys/devices/platform/coretemp.0/hwmon/hwmon*`) and prints one JSON line with text, the `lN` class, `high` or `critical`, and a tooltip. Polled every 5s.
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
- `~/.config/waybar/icons/audio-0-symbolic.svg`
- `~/.config/waybar/icons/audio-1-symbolic.svg`
- `~/.config/waybar/icons/audio-2-symbolic.svg`
- `~/.config/waybar/icons/audio-muted-symbolic.svg`
- `~/.config/waybar/icons/battery-symbolic.svg`
- `~/.config/waybar/icons/bell-off-symbolic.svg`
- `~/.config/waybar/icons/bell-symbolic.svg`
- `~/.config/waybar/icons/bolt-symbolic.svg`
- `~/.config/waybar/icons/bt-off-symbolic.svg`
- `~/.config/waybar/icons/bt-symbolic.svg`
- `~/.config/waybar/icons/chevron-up-symbolic.svg`
- `~/.config/waybar/icons/cpu-symbolic.svg`
- `~/.config/waybar/icons/disk-symbolic.svg`
- `~/.config/waybar/icons/dot-symbolic.svg`
- `~/.config/waybar/icons/ethernet-symbolic.svg`
- `~/.config/waybar/icons/mem-symbolic.svg`
- `~/.config/waybar/icons/moon-symbolic.svg`
- `~/.config/waybar/icons/power-symbolic.svg`
- `~/.config/waybar/icons/record-symbolic.svg`
- `~/.config/waybar/icons/start-symbolic.svg`
- `~/.config/waybar/icons/sun-symbolic.svg`
- `~/.config/waybar/icons/temp-symbolic.svg`
- `~/.config/waybar/icons/wallpaper-symbolic.svg`
- `~/.config/waybar/icons/wifi-0-symbolic.svg`
- `~/.config/waybar/icons/wifi-1-symbolic.svg`
- `~/.config/waybar/icons/wifi-2-symbolic.svg`
- `~/.config/waybar/icons/wifi-3-symbolic.svg`
- `~/.config/waybar/icons/wifi-off-symbolic.svg`
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
- `~/.config/waybar/levels.css`
- `~/.config/waybar/levels.json`
- `~/.config/waybar/style.css`
- `~/.local/bin/waybar-layout`
- `~/.local/bin/waybar-notifications`
- `~/.local/bin/waybar-temperature`
- `~/.local/bin/waybar-toggle`
- `~/.local/bin/waybar-windows`
- `~/.local/bin/waybar-winstate`

**Rendered from the palette** (`theme`):

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `accent`, `ansi10`, `ansi3`, `ansi4`, `badge`, `bg_desktop`, `border_hairline`, `error`, `fg_bright`, `fg_disabled`, `fg_editor`, `link`, `name`, `selection_bg`, `selection_fg`, `slug`, `success`, `warning`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

# waybar

The bar, at the bottom: one flat "taskbar" surface of 24px controls and quiet chips with 2px level bars, colored from the palette.

## Look

- One 36px surface 8px off the bottom and side edges, drawn as a 38px window (1px ring on each side, 7px margins) with radius 9px on the top-left and bottom-right corners. The mockup asks for `corner-shape: bevel`; GTK3 has none, so the corners are rounded, as Firefox renders the mockup. Fill, ring and 5% top sheen are `bar`, `edge` and `sheen`. The ring is listed after the sheen in `box-shadow` because GTK paints inset shadows in list order, the later one on top.
- Every control is 24px tall, 4px apart (`spacing`), radius 4, Inter 13. Roles come from `colors.css.tmpl` (`bar`, `edge`, `text`, `dim`, `editor`, `blue`, `sky`, `teal`, `orange`, `purple`, `green`, `amber`, `red`, `tipline`, `sel`, `selfg`); every accent is kept legible on the bar (`|legible`). No color literal lives in `style.css`.
- Hover is a translucent `editor` overlay under the chip's own tint. Custom modules match it on their wrapping box (`box:hover > #custom-…`): waybar puts the hover state on the box, and GTK3 doesn't pass it down to the label. Only the tags (real buttons) get the pressed overlay; waybar never sets `:active` on a label.
- Tooltips are the design's 30px box (bar color, `tipline` ring, radius 4), 8px above the bar and never past its ends. GTK places the tooltip window itself and ignores CSS margins on it, so the window is transparent and the visible box is its inner box, whose margins are the offsets. The clock labels and the tray items carry their own 7px inset (not the group or the tray) because each anchors its tooltip to its own allocation, and GTK3 counts a CSS margin inside it.

## Modules

Left: `custom/start` (click: `rofi -show drun`), the nine mango tags (`mango/workspaces`; click views, right-click toggles; `.empty` dim, occupied bright with a 4x2 mark, `.active` blue underline and tint, `.urgent` amber with a ring that pulses twice), a divider, the layout button (`custom/layout`, fed by `waybar-layout`; click: `mmsg dispatch switch_layout`), the focused window title (`mango/window`, 64 chars).

Center: one clock pill (`group/datetime`): day, time (its tooltip is the design's CALENDAR line with the month calendar kept below it, because the design's calendar is a click popover waybar can't open), date (`custom/date`, because waybar's clock zero-pads the day).

Right: tray, recording (`custom/record`, only while `gpurecord` prints), brightness (scroll: `osd-brightness bup/bdown`), night light (`custom/nightlight`; click toggles, right-click menu; see [wlsunset](wlsunset.md)), power (`custom/power`; click: wlogout, right-click: do-not-disturb), wallpaper (`custom/wallpaper`; click: waypaper), bluetooth (click: blueman-manager; the count shows while connected), a divider, then the live chips: network (SSID, max 16 chars; click: speeds), volume (click, right, middle: mute; scroll 5%), cpu, memory, temperature, disk (`/`), battery (click: wlogout), and the notification bell (`custom/notifications`).

Kept beyond the mockup, left of the wallpaper button: the tray, recording, brightness, night light and power.

## Tooltips

Every module but the tags (`mango/workspaces` sets none and offers no option) and the day label has the design's tooltip: one row of NAME, two spaces, VALUE and optionally two spaces and the KEYS, then an optional HINT row. They are Pango markup, written with single quotes so the JSON needs no escaping. The tooltip label is `@text`; the dimmer tones are `fgalpha` over the tooltip's `bar` background, which reproduces the design's greys without a color literal:

- NAME: `<span font_desc='Inter Semi-Bold 11px' letter_spacing='507' fgalpha='66%'>CPU</span>` (uppercase, +.06em tracking).
- VALUE: plain text (13px).
- KEYS: `<span font_desc='Inter Medium 11px' fgalpha='82%'>Super D</span>`. The design's keycap boxes can't be drawn in Pango, so the keys are plain text, space separated; they are this machine's binds (`mango/.config/mango/bind.conf`).
- HINT: `\n<span font_desc='Inter 11px' fgalpha='66%'>Scroll ±5</span>`.

Scripts that print a tooltip (`waybar-temperature`, `waybar-notifications`, `waybar-layout`, `nightlight status`) build the same markup; text that can hold `& < >` is escaped there (waybar escapes its own placeholders such as `{essid}`).

## Level bars

A chip draws the design's 2px level bar as its first background layer, a `currentColor` gradient. Waybar exposes a value only as a `states` class, and a module has one class at a time, so `levels.json` gives each level module one `states` entry per integer (`l0`..`l100`; included by `config.jsonc`, merged into each module) and `levels.css` turns each `.lN` into that layer's `background-size` width. Volume and battery use waybar's `<= value` states, the rest `>= value`. Both files are generated data (one entry per integer): regenerate them rather than edit single lines. `levels.css` also holds the icon ranges and the hot/low skins.

Specificity matters: an `#id` rule outranks a `.lN` class rule, so the shared chip rule in `style.css` sets no `background-size`. The fallback `label { background-size: 0% 2px, ... }` (no level class, no bar) is a bare type selector for the same reason. Rules that must beat a range (`.muted`, `.disconnected`, `.ethernet`, `.charging`, `.critical`) sit after the `@import` at the same id+class specificity.

Waybar's temperature module ignores `states` (its chip never gets an `lN` class), so the chip is `custom/temperature`: `waybar-temperature` prints the class itself, `min(100, C)`, plus `critical` from 80 C.

## Icons

Icons are `-gtk-recolor()` background layers (`icons/*-symbolic.svg`, `layouts/<symbol>-symbolic.svg`). GTK's symbolic loader fills every shape, so a stroked path needs `class="stroke"` in the SVG; `class="success stroke"` puts it in the `success` palette slot, which `-gtk-icon-palette` colors separately (the layout chevron, the bell).

Icon-only buttons carry a zero-width space (`\u200b`) as their label: waybar hides a module whose format is empty, so the label stays non-empty and invisible while the SVG is the background.

## Helper scripts

- `waybar-toggle` (super+b): stops or starts `waybar.service`.
- `waybar-temperature`: reads the coretemp `Package id 0` sensor (`/sys/devices/platform/coretemp.0/hwmon/hwmon*`) and prints one JSON line with text, the `lN` and `critical` classes and a tooltip. Polled every 5s.
- `waybar-notifications`: counts notifications held by mako (`makoctl list -j`) and reads `makoctl mode`; prints the count ("99+" above 99, a zero-width space at 0 so the bell stays) with classes `unread`, `dnd` (do-not-disturb on) and `critical` (a held critical notification). Polled every 2s and refreshed by `pkill -RTMIN+10 waybar` after a click. Bell clicks: restore, middle dismisses all, right toggles do-not-disturb.

- `waybar-layout`: streams `mmsg watch monitor $WAYBAR_OUTPUT_NAME` (the first active monitor when unset) through `jq` and prints one JSON line per event: the layout symbol as the class (`style.css` draws the glyph from `#custom-layout.T` etc.) and the LAYOUT tooltip (design name, and the super+n hint). It replaces `mango/layout`, which has no tooltip support; waybar restarts it after 1s if mmsg exits.

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

**Rendered from the palette** (`theme`):

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `ansi1`, `ansi11`, `ansi12`, `ansi2`, `ansi3`, `ansi4`, `ansi5`, `ansi6`, `bg_desktop`, `border_hairline`, `fg_disabled`, `fg_editor`, `name`, `selection_bg`, `selection_fg`, `slug`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

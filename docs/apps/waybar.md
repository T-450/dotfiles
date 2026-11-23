# waybar

The shell's top bar, Material 3 pill pieces around a fixed clock, each opening its component under it, and the media bar at the bottom, with cava ribbons around the player. Both run in one waybar process. The top bar follows [SPEC-bar](../designs/material-shapeshifter/SPEC-bar.md): a transparent row of pieces, the components being rofi, mako, swayosd and wlogout. The media bar is the "Viewport" floor: the axis triad, the ribbons, the player and the CLUT key, in its own pixel face.

## The top bar

- 48px tall with an 8px margin on top and at the sides (`margin-*` in `config.jsonc`), so it reserves 56px; mango's 7px outer gaps keep windows 7px below that. Pieces sit 8px apart (`spacing`).
- The bar itself is transparent. A piece is an M3 pill: `surface_container_high`, corner full, the bar's height. A single module is its own pill; a group is one pill around its modules, which stay transparent and take the state layer under the pointer.
- Type is IBM Plex Sans from the type tokens: label large (14px, 500) for labels and window titles, title medium (16px) for the time, label medium (12px) for the date, label small (11px) for the count badge. Type is `on_surface`, icons and dimmer text `on_surface_variant`.
- Hover is the state layer: the piece's color mixed 8% toward `on_surface` (`piece_hover`, `state_hover`); a pressed tag 10% (`piece_press`). The template mixes them, so `style.css` names roles only. Custom modules match hover on their wrapping box (`box:hover > #custom-…`): waybar puts the hover state on the box, and GTK3 doesn't pass it down to the label.
- The selected state (the viewed tag) is `secondary` with `on_secondary`, not `secondary_container`: on a light palette the container is as light as the pill (Space Light 1.1:1) and the fill is the tag's only edge.
- Tooltips are M3 plain tooltips: `inverse_surface`, corner extra small, body small, 8px under the piece. GTK places the tooltip window itself and ignores CSS margins on it, so the window is transparent and the visible box is its inner box, whose margins are the offsets.
- Colors come from `colors.css.tmpl` as `m3_*` roles and state layers (the block at its end); no color literal lives in `style.css`. Every text pair reads at least 4.5:1 in `space` and `space-light`; the low-battery text is `badge_text`, `error` pushed to 4.5:1 on the pill (`|legible`).

## Pieces

Left to right:

| piece | modules | face | click |
|---|---|---|---|
| launcher | `custom/launcher` | search icon and "Search" | rofi (`-theme launcher`: opens under the piece) |
| tags | `group/tags`: `mango/workspaces` (tags 1-4), `custom/special` (tag 0), `custom/layout`, `mango/keymode`, `custom/winstate`, `custom/win#1..6` | a connected button group: tags as 32px circles (the viewed one `secondary`, an urgent one `error`), the layout glyph, the chips while their state holds, then the windows in view | a tag views it (right-click toggles); tag 0 toggles the special tag; the glyph switches layout; a window focuses it, the wheel moves focus |
| media | `group/media`: `mpris`, `cava` | the play state (pause icon while playing) and the track, then 14 spectrum bars in `primary` | waybar's mpris defaults: play/pause, middle previous, right next |
| core | `group/core`: `clock`, `custom/date` | the time and the date on `primary_container` | none; the calendar is its tooltip |
| status | `group/status`: `custom/record`, `network`, `bluetooth`, `custom/nightlight`, `battery`, `tray` | icons, the bluetooth count, the battery icon and charge | record stops; bluetooth opens blueman; night light toggles (right-click: options) |
| notifications | `group/notifications`: `custom/notifications`, `custom/unread` | the bell (bell-off under do-not-disturb, `error` while a critical one is held) and an `error` count badge | restore; middle dismisses all; right toggles do-not-disturb |
| volume | `pulseaudio` | speaker icon (crossed while muted) | mute; scroll 5% |
| brightness | `group/brightness`: `backlight`, `backlight/slider` | a sun icon; a drawer that widens in place into a 120px slider on hover (250 ms, medium1) | the slider sets it; scroll steps it |
| power | `custom/power` | power icon, `error` under the pointer | wlogout as a menu under the piece |

- The core is the only centre module and its width changes only with the date, so it never moves. waybar's clock zero-pads the day, so the date is `custom/date` (`date '+%a %-d %b'`).
- The media piece hides while nothing plays: the fill is on the group, which has no size when both of its modules are hidden (mpris without a player, cava silent with `hide_on_silence`). The spectrum is waybar's own `cava` module, so it can never draw outside the piece. If this waybar build has no cava module, waybar logs it and the piece shows the track alone; the media bar's ribbons are the fallback the spec names.
- The key-mode and window-state chips exist only while their state does: an armed key mode is a `tertiary_container` chip, window states an outlined one, a pinned window (it shows on every tag until unpinned) an `error_container` one.
- Battery warns on battery only, in `error` text at 20% and an `error_container` chip at 10%; charging, plugged in or full it is `primary`.
- The badge is 16px (`48 - 8 - 24`) on the bell's upper right; at 0 `waybar-notifications` prints an empty text, which hides it, while the bell's own format keeps the bell.
- The spec's selected state for a piece whose component is open is not built: waybar gets no signal when rofi, mako's history or wlogout opens.

Mango has no wlr-foreign-toplevel-management, so waybar's taskbar can't run: `waybar-windows` follows `mmsg watch all-clients` and signals the window slots.

## Tooltips

Every piece has a tooltip but the tags (`mango/workspaces` sets none and offers no option) and those `config.jsonc` sets to `"tooltip": false`: one row of NAME, two spaces, VALUE and optionally the KEYS, then an optional HINT row, in Pango markup with single quotes so the JSON needs no escaping. NAME and HINT are `<span fgalpha='60%'>…</span>`, KEYS `<span fgalpha='80%'>…</span>`: the dimmer tones are alpha over the tooltip's color, without a color literal. Scripts that print a tooltip (`waybar-notifications`, `waybar-layout`, `waybar-winstate`, `nightlight status`) build the same markup; text that can hold `& < >` is escaped there.

## Icons

Icons are `-gtk-recolor()` background layers (`icons/*-symbolic.svg`, `layouts/<symbol>-symbolic.svg`), 16px stroked drawings shown at 20px. GTK's symbolic loader fills every shape, so a stroked path needs `class="stroke"` in the SVG; `class="success"` puts a path in the `success` palette slot, which `-gtk-icon-palette` colors apart from the label (bluetooth's mark, which follows `currentColor`).

Icon-only modules carry a zero-width space (`​`) as their label: waybar hides a module whose format is empty, so the label stays non-empty and invisible while the SVG is the background.

## The media bar

The second bar in `config.jsonc`: `"position": "bottom"`, 30px, `"layer": "top"`, the top bar's layer. `style.css` scopes it by waybar's position class, `window#waybar.bottom` (and the top bar's player rules by `.top`, since both use mpris): `bar` fill (near-black on a dark palette, the desktop itself on a light one), with a 1px `cyan` 45% rule on its top edge. Every output gets one, like the top bar, so each screen runs two cava (passive: see Ribbons).

It keeps the "Viewport" face: Terminess Nerd Font (`fonts/packages`) with 1px letter spacing (Terminess draws 14px from its 8x14 bitmap strike but advances 7px, so without it glyphs overlap) and its own roles from the first block of `colors.css.tmpl`, each legible on the desktop: `bar`, `text`, `cyan` (chrome), `orange` (action), `magenta` (the artist), `green`, `grid`, `clut0`..`clut15`.

Left to right:

- `custom/triad`: the XYZ axis triad, 40px, drawn by `icons/triad-symbolic.svg` with its axes in palette slots: X `orange`, Y `green`, Z `cyan`, the origin `text`.
- `cffi/ribbons#left`: the left channel's ribbon, lows toward the player (`"channel": "left"`, `"expand": true`). With `expand-left`/`expand-right` on the bar, both ribbons fill the room the centered player leaves.
- The player: waybar's `mpris` module once per part (`mpris#prev`, `#play`, `#next`, `#title`, `#artist`, `#time`), each instance id a CSS class, so each part has its own color. Prev and next are `cyan` 70% (chrome), play `orange` (the action); a button shows its action, so play shows pause while playing (`#mpris.play.playing`). The title is `text` bold (20 characters), the artist `magenta` (14) after a 5x1 `cyan` 55% dash (a CSS gradient in its left padding), the time `cyan`. A click on prev or next runs `playerctl previous`/`next`; on any other part waybar's default plays or pauses. The parts hide while no player runs.
- `cffi/ribbons#right`: the right channel's ribbon.
- `custom/clut`: the CLUT key, the ribbons' 16 colors as a 5x16 strip, low at the bottom (one CSS gradient over `clut0`..`clut15`).

The triad and the CLUT key are zero-width labels, like the icon buttons; each has a tooltip (AXES, CLUT) with a one-line note, its NAME and HINT spans in 12px Terminess (`font_desc='Terminess Nerd Font 12px'`, with `letter_spacing` stated, since `style.css` gives all its text 1px). A part under the pointer takes a 14% `cyan` fill with a 1px `cyan` bottom edge.

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
- Color by energy comes from `clut0`..`clut15`. All strands at one x share one color, so where their summed intensity takes that color past 1, it is scaled down by its brightest channel: where they bunch (silence, the tapered ends), the ribbon keeps its hue instead of clipping to white.
- The module reads the CLUT, `grid` and `text` from the GTK style context, and again when waybar re-creates its modules: `theme set` runs `waybar/reload.sh`, which sends waybar SIGUSR2, so the ribbons recolor with the rest of the bar.
- Its one key is `channel` (`left` or `right`). Left is drawn mirrored, so the lows meet at the player.
- Data: each instance runs its own `cava`. The config is written to `$XDG_RUNTIME_DIR/waybar-ribbons/<channel>.conf`: pipewire input, raw binary 16-bit mono output, 48 bars, 30 fps, `sleep_timer = 1`.
- cava's capture node is passive (`active = 0`), so it never keeps the sink awake by itself. Its first-run files go under `$XDG_RUNTIME_DIR/waybar-ribbons` (its `XDG_CONFIG_HOME`), not `~/.config/cava`. It dies with waybar (`PR_SET_PDEATHSIG`).
- A frame equal to the one on screen is not drawn, so silence costs no GPU time.
- If cava exits, the ribbon goes flat and cava starts again after 1s. The delay doubles up to 30s while it keeps failing.
- Waybar's reload stops each instance's cava. Stopping waybar stops them all, since cava runs in waybar.service's cgroup.
- Any change under `waybar/pkg/waybar-ribbons/` bumps `pkgrel`: `install.sh` rebuilds a `pkg/` package only when its version changes.

## Helper scripts

- `waybar-toggle` (super+esc b): stops or starts `waybar.service`.
- `waybar-notifications`: counts notifications held by mako (`makoctl list -j`) and reads `makoctl mode`; prints the count ("99+" above 99, empty at 0, which hides the badge) with classes `unread`, `dnd` (do-not-disturb on) and `critical` (a held critical notification). Both halves of the notifications piece read it (the bell's format ignores the text), polled every 2s and refreshed by `pkill -RTMIN+10 waybar` after a click. Clicks: restore, middle dismisses all, right toggles do-not-disturb.
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
- `~/.config/waybar/icons/battery-symbolic.svg`
- `~/.config/waybar/icons/bell-off-symbolic.svg`
- `~/.config/waybar/icons/bell-symbolic.svg`
- `~/.config/waybar/icons/brightness-symbolic.svg`
- `~/.config/waybar/icons/bt-off-symbolic.svg`
- `~/.config/waybar/icons/bt-symbolic.svg`
- `~/.config/waybar/icons/ethernet-symbolic.svg`
- `~/.config/waybar/icons/moon-symbolic.svg`
- `~/.config/waybar/icons/next-symbolic.svg`
- `~/.config/waybar/icons/pause-symbolic.svg`
- `~/.config/waybar/icons/play-symbolic.svg`
- `~/.config/waybar/icons/power-symbolic.svg`
- `~/.config/waybar/icons/prev-symbolic.svg`
- `~/.config/waybar/icons/record-symbolic.svg`
- `~/.config/waybar/icons/search-symbolic.svg`
- `~/.config/waybar/icons/triad-symbolic.svg`
- `~/.config/waybar/icons/volume-off-symbolic.svg`
- `~/.config/waybar/icons/volume-symbolic.svg`
- `~/.config/waybar/icons/wifi-off-symbolic.svg`
- `~/.config/waybar/icons/wifi-symbolic.svg`
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
- `~/.local/bin/waybar-toggle`
- `~/.local/bin/waybar-windows`
- `~/.local/bin/waybar-winstate`

**Rendered from the palette** (`theme`):

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `ansi4`, `ansi5`, `ansi6`, `bg_desktop`, `error`, `fg_editor`, `m3_error`, `m3_error_container`, `m3_inverse_on_surface`, `m3_inverse_surface`, `m3_on_error`, `m3_on_error_container`, `m3_on_primary_container`, `m3_on_secondary`, `m3_on_surface`, `m3_on_surface_variant`, `m3_on_tertiary_container`, `m3_outline`, `m3_primary`, `m3_primary_container`, `m3_secondary`, `m3_surface_container_high`, `m3_surface_container_highest`, `m3_tertiary_container`, `name`, `prefer_dark`, `slug`, `success`, `warning`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

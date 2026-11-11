# waybar

The bar, at the bottom: cjbassi's layout ([cjbassi/config](https://github.com/cjbassi/config/tree/master/.config/waybar)) as pills and a powerline ribbon, colored from the palette.

The bar is 36px tall (`config.jsonc`) and everything on it is a 26px shape floating 5px off its top and bottom edges, with 13px text: base weight normal, emphasis (the selected tag, the clock's time) extra bold (800). The look is "split chevrons", after Dusky's `17_boxy_h` (every module a block of its own with the bar showing between them; here the blocks stay one ribbon). The Arch logo, the layout icon and the clock are fully rounded pills with no arrows; the right-hand modules are one agnoster-style powerline ribbon of the same height, which starts with an arrow tip and ends in the pills' rounded cap, as far from the screen edge as the logo. Modules showing a live value keep colored segments: network, volume, brightness, battery, memory, disk, cpu and night light use the palette's accents (`accent`, `link`, `badge`, `success`, `warning`, `error`) and its purple (`ansi13`), and change with their state. Blue backgrounds (`link`, `badge`, `accent`) carry white text (`selection_fg`), each blue darkened only as far as white needs (`|legible`); disk's accent is mixed toward `bg_desktop` first so it stays distinct from memory's badge beside it. The static modules use neutrals: the clock a raised surface (`bg_hover`), and the tray, recording dot and power a grey (`fg_disabled`). Other text comes from `|ink`, so it reads at 4.5:1 on any palette; dimmed text (muted, night light off) and the recording dot's red are moved only as far as 4.5:1 needs (`|legible`). No two neighbors share a color in Dark 2026 (Light 2026 defines accent, badge and link as one blue, so memory and disk merge there).

The left corner starts with the Arch logo (`arch-symbolic.svg`, the official silhouette without its notches, tinted `accent` through `-gtk-recolor`). The tags follow on the bar itself, with no pill: an occupied tag is dim text (`fg_secondary`) 8px from the next, the selected one bright extra-bold text (`strong`: `fg_bright`, legible on the bar) over a 3px dotted line, and an urgent one an `error` pill. The line is 3px dots 3px apart in one solid color (`dots`: `accent`, legible on the bar), drawn by a `repeating-linear-gradient` whose gaps are transparent, so the bar shows through them. Every tag carries it at zero width; hovering a tag grows it to 3 dots (15px) and selecting to 7 (39px), from the center (`background-size`, 200ms), always in whole dots so no line ends in a sliver, and the selected tag widens to 40px through `min-width`, since GTK3 CSS has no transforms. The layout icon is in the palette's text color. Hovering the logo or the layout icon raises a `bg_hover` pill with a 2px ring (`glow`: `accent` mixed into the bar, opaque) inside its own margin, and state changes fade over 150ms. The clock is three modules (day, time, date) drawn as one pill in one color, the day and the date carrying its rounded ends; only the bold weight sets the time apart.

The arrows of the ribbon are 13x26 chevrons (45 degrees) behind a 3px slit, in 16px edge columns painted by `edges/<name>-symbolic.svg` (viewBox 16x26). The slit is a part of the column the SVG leaves unpainted, so the opaque bar shows through it: no fourth color and no alpha. The edges are recolored through `-gtk-icon-palette` (`error` is the segment's color, `warning` and `success` its left and right neighbors'). Each boundary is one column owned by one segment, which paints both colors: waybar repaints only the module that changed, so a column shared by two overlapping modules loses half its arrow whenever the other updates. A segment that changes color with its state (offline, battery or disk low, warm night light) owns both of its arrows, and `config.jsonc` keeps those four apart, so no state ever leaves a stale arrow. The tray, the recording dot (red, since it only shows while recording) and power form one grey block, so the arrow before it fits whichever of them shows. Dimmed text (muted, night light off) is a mixed color, never `alpha()`: GTK3 applies the text color's alpha to the recolored edges too. Only a column's owner may change a segment's background, so hovering a clickable segment (network, volume, night light, recording, power) draws a 3px underline in its own text color instead (the tags' line), which holds in every state. Every arrow points left, so a segment's color reaches further on its left than on its right at text height; a smaller left padding evens the two sides out. Each value has an icon rather than a word, and percentages are padded to two digits, so a segment keeps its width as its value crosses 10%.

Left: the Arch logo (`custom/arch`; click opens the launcher, `rofi -show drun`, as super+d does), mango tags (`ext/workspaces`; empty tags stay hidden, click to view) and the current layout as an AwesomeWM-style icon (`mango/layout`; `layouts/<name>-symbolic.svg`, one per mango layout, tinted through `-gtk-recolor`; click for the next layout). Center: day, time (calendar tooltip), date (`Tue 14:32 10 Nov`). Right: network (click: speeds), volume (click mutes, scroll ±2%), brightness (scroll), battery, memory, disk, cpu, night light ([wlsunset](wlsunset.md)), tray (16px icons), recording indicator, power menu (right-click: do-not-disturb). At 1920px the ribbon fits beside the centered clock with every value at 100%, four tray icons and recording on: the network name is capped at 24 characters (`max-length`; past it, it ends in an ellipsis, so the ribbon never reaches the clock) and the recording indicator is its icon alone (the word "recording" would cost 78px). super+h hides it (`waybar-toggle` stops the unit). It replaced mangobar.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`waybar/packages`): `waybar`, `pamixer` (volume click/scroll)

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/systemd/user/waybar.service`
- `~/.config/waybar/arch-symbolic.svg`
- `~/.config/waybar/colors.css`
- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/edges/host-right-symbolic.svg`
- `~/.config/waybar/edges/own-left-symbolic.svg`
- `~/.config/waybar/edges/tip-left-symbolic.svg`
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
- `~/.local/bin/waybar-toggle`

**Rendered from the palette** (`theme`):

- `waybar/.config/waybar/colors.css.tmpl` → `waybar/.config/waybar/colors.css`: `accent`, `ansi13`, `badge`, `bg_hover`, `bg_surface`, `bg_widget`, `border_hairline`, `error`, `fg_bright`, `fg_disabled`, `fg_secondary`, `fg_text`, `link`, `name`, `selection_bg`, `selection_fg`, `slug`, `success`, `warning`

**User units** (enabled by `install.sh --units`): `waybar.service`

**`reload.sh`** (run by `theme set`): reload waybar's config and CSS (colors.css changed) in place. A stopped bar (hidden with waybar-toggle) stays stopped.
<!-- end generated -->

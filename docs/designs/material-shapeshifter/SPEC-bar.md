# SPEC-bar: the shell on waybar and the apps we have

Module `bar` of the [Material shapeshifter map](README.md). Status: draft (revision 4), awaiting
approval. Date: 2026-11-23. Depends on [SPEC-theme](SPEC-theme.md) (built: `m3_*` roles and the
system tokens). The design canvas board "Chosen: the shell redesigned on waybar and the existing
apps" is the visual reference; where this text and the board differ, this text wins.

## Goal

Redesign the whole shell in Material 3 with no new renderer. Waybar draws a fixed core and one
pill piece per shell component; each component is the app that already does the job, reshaped to
M3 and placed under its piece. Pieces do not travel or become their component: a piece opens its
component beneath it with the motion mango gives layer surfaces, and a waybar drawer widens a
piece in place. Every motion in this spec is one mango 0.18.5 or waybar 0.16 can produce.

## Non-goals

- A new renderer (Quickshell or any other): ruled out by the user.
- Pieces that move, morph into their component, or spend mass (they need a renderer the stack
  lacks; see open question 1).
- The bottom media bar (the always-on instrument panel, outside the map).

## The bar (waybar)

| piece | waybar module | face | opens |
|---|---|---|---|
| core | clock, centred | time (title medium) and date (label medium) on `primary_container` | nothing; never moves or morphs |
| workspaces | mango tags plus window titles, as one group | connected button group, each tag naming its windows, the active tag `secondary_container` | stays as it is |
| launcher | custom | search icon and "Search" | rofi |
| media | mpris with a spectrum | play icon and track; 14 bars inside the piece while playing | nothing |
| notifications | custom (makoctl count) | bell with an `error` / `on_error` count badge | mako's history |
| volume | pulseaudio | icon | swayosd on keys |
| brightness | group drawer: backlight and backlight/slider | icon | widens in place into a slider on hover |
| power | custom | icon | wlogout |

- The bar is transparent; pieces are M3 pill buttons: 48 px, corner full, `surface_container_high`,
  8 px apart, either side of the core. Icons and labels `on_surface_variant` / `on_surface`.
- A piece whose component is open takes the selected state (`secondary_container` with
  `on_secondary_container`); hover and pressed are the state-layer tokens (0.08, 0.10) in
  `style.css`.
- Type from the type tokens in IBM Plex Sans. Colors from `m3_*` roles through the waybar
  templates; no literal.
- The spectrum stays inside the media piece: waybar cannot draw outside its surface. It uses
  waybar's `cava` module if this build has it, else the repo's ribbons module (`pkg/waybar-ribbons`).

## The components (session apps, M3-shaped, placed under their pieces)

| component | app | M3 shape | placement | motion (mango layer rule) |
|---|---|---|---|---|
| launcher | rofi | search view: field, list rows with supporting text, selected row `secondary_container`; corner extra-large, elevation 3 | top centre, under the launcher piece | zoom (from 10%) |
| notifications | mako | card: title medium, body medium, text-button actions; corner large | top right, under the bell | fade |
| volume, brightness keys | swayosd | slider pill: icon, track `surface_container_highest`, active `primary`; corner full | top, under the volume piece | fade |
| power | wlogout | menu: four rows, power off in `error`; corner large | top right, under the power piece | fade |
| lock, greeter, key overlay | hyprlock, the greeter, mango-keys | as their own specs (SPEC-greeter, SPEC-session) | | |

Placement uses each app's own options (rofi `location` and offsets, mako `anchor` and margins,
swayosd's top margin, wlogout's margins), set from the bar's geometry so a component sits 8 px
under its piece.

## Motion

- Layer surfaces open and close with mango's durations and curve, shared with windows: 150 ms,
  ease-out quad today ([mango-animations](../mango-animations.md) design). Proposal: keep them;
  moving them to M3's short4 (200 ms) and emphasized decelerate would change every window too.
- Drawers use waybar's transition, set to 250 ms (medium1).
- No springs and no container transform: the stack has neither.
- Reduced motion: `layer_animations=0` in mango; drawers change state without the slide.

## External screens

Waybar runs per output, so every screen has the core and all pieces (the list stays up
everywhere). rofi, mako, swayosd and wlogout open on the focused output, as they do today.

## Acceptance

1. In desktop-vm, shots of the bar at rest and of rofi, mako, swayosd, wlogout and the brightness
   drawer open, in `space` and `space-light`; each component sits under its piece.
2. Every color in waybar, rofi, mako, swayosd and wlogout comes from a template (`theme lint`).
3. Text pairs at least 4.5:1, piece and component edges at least 3:1 (the palette floors).
4. The spectrum never draws outside the media piece; the bar's height never changes.
5. `tools/docs --check`, `tests/run`; the keybindings cheatsheet unchanged unless a key changes.

## Open questions

1. **The map**: its bar row says "visible morph, any direction, any form; each morph spends mass".
   This design keeps the look and drops the morph and the mass. Reword the row, or keep it as a
   goal for later?
2. **The spectrum on an empty workspace**: your rule had it extend below the bar there; waybar
   cannot. Drop it, or move the large spectrum to the bottom media bar's ribbons?
3. **Layer motion**: keep mango's 150 ms ease-out quad (proposed), or move layers and windows to
   M3 timings together?
4. **Waybar's current top bar** (the CAD viewport status line) is replaced by this bar; the bottom
   media bar stays. Confirm.

# SPEC-bar: the shell on waybar and the apps we have

Module `bar` of the [Material shapeshifter map](README.md). Status: revision 4, approved and built
2026-11-23 (what the build changed is under "As built"). Date: 2026-11-23. Depends on [SPEC-theme](SPEC-theme.md) (built: `m3_*` roles and the
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
  lacks; the map's row is reworded to match).
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
| status | recording, network, bluetooth, night light, battery, tray, as one group | icons; battery icon and charge | each its own (kept from the old bar) |
| power | custom | icon | wlogout |

- The bar is transparent; pieces are M3 pill buttons: 48 px, corner full, `surface_container_high`,
  8 px apart, either side of the core. Icons and labels `on_surface_variant` / `on_surface`.
- The selected state is `secondary` with `on_secondary` (the viewed tag, rofi's selected row);
  hover and pressed are the state-layer tokens (0.08, 0.10), mixed by the waybar template.
- Type from the type tokens in IBM Plex Sans. Colors from `m3_*` roles through the waybar
  templates; no literal.
- The spectrum stays inside the media piece: waybar cannot draw outside its surface. It uses
  waybar's `cava` module if this build has it, else the repo's ribbons module (`pkg/waybar-ribbons`).

## The components (session apps, M3-shaped, placed under their pieces)

| component | app | M3 shape | placement | motion (mango layer rule) |
|---|---|---|---|---|
| launcher | rofi | search view: field, list rows with supporting text, selected row `secondary`; corner extra-large, elevation 3 by tone | top left, under the launcher piece | zoom (from 10%) |
| notifications | mako | card: title medium, body medium; corner large; critical as `error_container` | top right, under the bar's right end | fade |
| volume, brightness keys | swayosd | slider pill: icon, track `surface_container_highest`, active `primary`; corner full | top centre, under the bar | fade |
| power | wlogout | menu: six rows, power off in `error`; corner large | top right, under the power piece | fade |
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

## Decisions (the open questions, answered 2026-11-23: "use your proposals")

1. **The map**: the bar row is reworded; the morph and the mass are dropped.
2. **The spectrum on an empty workspace**: dropped; the spectrum lives in the media piece only.
3. **Layer motion**: mango's 150 ms ease-out quad stays.
4. **Waybar's top bar** (the CAD viewport status line) is replaced; the bottom media bar stays.

## As built

Where the build differs from the text above, and why:

- **The selected state is `secondary`, not `secondary_container`.** On Space Light the container
  reads 1.1:1 on `surface_container_high`, so a selected tag or row had no edge (acceptance 3).
- **A status piece** keeps network, bluetooth, night light, battery, the tray and the recording
  dot: without it the laptop loses its battery and network state. The old bar's telemetry (cpu,
  memory, temperature, disk) and the wallpaper button are gone.
- **The tags piece** also holds tag 0, the layout glyph and the key-mode and window-state chips,
  and lists the windows in view after the tags: waybar cannot name each tag's windows.
- **Placement**: the launcher is the first piece, so rofi opens top left under it; swayosd
  centres itself, so its pill is top centre; mako stacks from the bar's right end.
- **wlogout keeps all six actions** (lock, suspend, hibernate, log out, restart, power off).
- **Not built**: a piece taking the selected state while its component is open (waybar gets no
  signal when rofi, mako's history or wlogout opens); mako's text-button actions (mako has no
  buttons; actions stay in `makoctl menu`); elevation shadows (mango draws none: elevation is
  tone). The spectrum needs waybar's cava module; a build without it shows the track alone.
- **Unverified here** (no desktop-vm in the build session): the cava module in Arch's waybar, the
  rofi, swayosd and wlogout offsets on the real screen, the GTK icon rendering.

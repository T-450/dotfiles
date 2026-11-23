# SPEC-bar: a fixed core, one piece per component

Module `bar` of the [Material shapeshifter map](README.md). Status: draft (revision 3), awaiting
approval. Date: 2026-11-23. Depends on [SPEC-theme](SPEC-theme.md) (built: `m3_*` roles and the
system tokens). The design canvas board "Chosen, polished: one piece per component (M3)" is the
visual reference; where this text and the board differ, this text wins.

## Goal

The bar is a small core at the top of the screen that never moves and never morphs. Every shell
component is exactly one piece. At rest the pieces dock beside the core as Material 3 buttons,
each showing its component's compact face; to open, a component's piece moves and stretches into
the component (M3's container transform) and returns when it closes. This spec covers the core,
the pieces, the mass model, the morph engine, and the components drawn on the board. The detailed
shapes of notifications, OSDs, power, lock and the key overlay, and the greeter, come in their own
specs on the same engine.

## Non-goals

- The always-on instrument panel (outside the map): today's bottom media bar is not touched.
- Wallpaper-driven color, a second complete component beside the body (outside the map).

## The core and the pieces

| component | docked face | opens into (M3 component, corner token) |
|---|---|---|
| core | time (title medium), date (label medium) | never moves or morphs |
| workspaces | connected button group: each tag naming its windows, the active one in `secondary_container` | stays docked |
| launcher | search bar: icon and "Search" | search view: field and list, corner extra-large |
| media | play icon and the track | the spectrum (below) |
| notifications | bell with a count badge (`error` / `on_error`) | card with text buttons, corner large |
| volume, brightness | icon | vertical slider, corner full |
| power | icon | menu, corner large; power off in `error` |
| lock, key overlay | none | ride under the core; open from it when called |

- Pieces: M3 buttons, 48 px tall, corner full, 8 px apart either side of the core, on
  `surface_container_high`; icons and labels `on_surface_variant` / `on_surface`. The core: 56 px,
  corner full, `primary_container` with `on_primary_container` text.
- Open components: `surface_container`, elevation level 3, the component's corner token. A
  vacated dock keeps an `outline_variant` outline.
- States: hover 0.08 and pressed 0.10 `on_surface` state layers (the state tokens).
- Type from the type tokens, IBM Plex Sans only. Color only from `m3_*` roles; no literal, a
  `.tmpl` per the repo's rule.
- At rest nothing moves: no idle animation.

## Mass

Mass is piece count: one per component, 7 docked beside the core and 2 under it. A component
spends only its own piece and returns it on close. A piece is in exactly one place at any frame:
docked, stretching, or open. Its growth into the component is declared, not hidden.

## Morph engine

- The container transform: the piece moves and stretches from its dock to the component's bounds
  on the spatial spring (default, 0.8 / 380), its corner morphing from full to the component's
  token, its tone from `surface_container_high` to `surface_container`, rising to level 3.
  Content fades in on the effects spring once the piece is 60% open. Close: emphasized
  accelerate, 300 ms.
- The core never moves or morphs. Text sits only on docked or settled pieces.
- Usable from the first frame (the launcher's field takes input as the piece starts to move);
  settled within 450 ms (the spring is within 2% at about 200 ms); a second request mid-flight
  retargets the piece from where it is.
- Two components never share a piece, so any can be open at once; where two would overlap on
  screen, the later one opens beside the earlier.
- Reduced motion: no travel or stretch; the component fades in and out over 200 ms, as M3
  prescribes; the spectrum shows a static face.

## The spectrum

| | |
|---|---|
| Trigger | a player reports Playing over MPRIS; the media piece shows the track |
| Windows on the workspace | 16 bars inside the media piece: never drawn over a window |
| Workspace with no windows | the bars run below the piece, up to 190 px |
| Input | click-through: the bars are outside the bar's input region |
| Hide | a key toggles it (to be chosen: super+m is mango's monitor mode) |
| Data | `cava` (already installed for waybar's ribbons), 16 bands at 30 frames a second |

## Data sources

Tags, the windows on each tag and the focused window from mango over `mmsg` (as waybar does
today; mango has no foreign-toplevel management). MPRIS through `playerctl` or the renderer.
Time, network, battery, volume and brightness as waybar reads them; notifications from the
notification daemon (mako today: the notifications spec decides whether the bar takes over).

## Renderer

A Wayland layer-shell program with free geometry, corner and shadow animation, and per-frame
updates at the display's refresh rate. Recommendation: **Quickshell** (QML on Qt Quick:
layer-shell surfaces, springs and easing curves, animated radius and shadows, MPRIS built in, runs
`mmsg` and `cava` as processes). It is a new package (AUR `quickshell`), so it needs approval.
Rejected: waybar (no free geometry or morphs), eww (polling model, limited animation), AGS/Astal on
GTK4 (possible, weaker motion primitives).

Repo shape, one model for every app: a `bar/` app folder with `packages` (quickshell), the QML
under `.config/quickshell/`, colors and tokens from a `Theme.qml.tmpl` rendered by `theme`, a
`reload.sh`, and `quickshell.service` as a session user unit (`PartOf`/`After`/`WantedBy`
`graphical-session.target`). Waybar's top status bar is retired when the bar ships (one body);
its bottom media bar stays.

## Acceptance

1. In desktop-vm, shots of rest, the hover state, launcher, notification, volume, spectrum
   (windows open and an empty workspace) and power, in `space` and `space-light`.
2. Launcher: the field takes input on the first frame after super+d; the piece settled within
   450 ms (frame timestamps logged in a debug mode).
3. Mass: the debug mode logs the piece count per frame; 7 beside the core and 2 under it in every
   frame of a scripted run (each component open and closed, two at once, reopen mid-close).
4. The core and the workspace piece never change position (logged before and after every morph).
5. Reduced motion: no piece travels or stretches; components fade; the spectrum is static.
6. Contrast: every text pair at least 4.5:1, every component edge at least 3:1 (from the palette's
   floors); `theme lint`, `tools/docs --check`, `tests/run`; the cheatsheet lists new keys.

## Open questions

1. **Renderer**: approve Quickshell as a new package, or name another.
2. **External screens**: every output gets a core and docked pieces (the list stays up
   everywhere); a component opens only on the focused output, and only that output's pieces move
   (the body is never in two places at full size). Proposal; confirm.
3. **The spectrum's key**: which binding hides it (super+m is taken).
4. **Workspaces**: their piece stays docked here. Should it also stretch into an overview?
5. **Waybar**: retire only the top status bar (proposed), or the media bar too.

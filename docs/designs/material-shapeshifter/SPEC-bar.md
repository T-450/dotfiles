# SPEC-bar: the reserve core

Module `bar` of the [Material shapeshifter map](README.md). Status: draft, awaiting approval.
Date: 2026-11-23. Depends on [SPEC-theme](SPEC-theme.md) (built: `m3_*` roles and the system
tokens). The design canvas board "Chosen: the reserve core bar" is the visual reference; where
this text and the board differ, this text wins.

## Goal

The bar is the shell's one body: a 64 px row of machined plates at the top of the screen whose
middle, the reserve core, is spent to build other shapes and returned when they close. This spec
covers the body, its rest state, the mass model, the morph engine and two reference shapes that
prove it: the launcher and the spectrum. The other session shapes (notifications, volume and
brightness, power, lock, key overlay) come in SPEC-session on the same engine.

## Non-goals

- The greeter and the other session shapes (their own specs).
- The always-on instrument panel (outside the map): today's bottom media bar is not touched.
- Wallpaper-driven color, a second complete component beside the body (outside the map).

## The body

| part | plates | content | moves |
|---|---|---|---|
| workspace plates | one per tag (1-4), left | tag number and the windows on it, 14 px | never |
| core | 8 plates, middle | split-flap readout of the focused window | spent and returned |
| status plates | time, date, network, battery, right | label and value | never (the date plate shows the track while audio plays) |

- Plates: 56 px tall in the 64 px bar, 4 px apart, 8 px cut corners. Cut corners are a
  shell-specific shape, not an M3 shape token; they are the bar's identity and recorded here.
- Color only from `m3_*` roles: plates `surface_container_high`, borders `outline` (5.8:1 on
  `surface` in Space), text `on_surface` / `on_surface_variant`, the active workspace's light
  `secondary`, lit edges and meters `primary` / `primary_container`. No color literal in any
  file: a `.tmpl` per the repo's rule.
- Type: IBM Plex Sans from the type tokens (`label_large` for names); IBM Plex Mono for codes and
  readouts, a deviation from SPEC-theme's single typeface, recorded here.
- At rest nothing moves: no idle animation.

## Mass

Mass is plate count. The core holds 8; a shape spends plates from it and returns them when it
closes. A plate is in exactly one place at any frame: in the bar, in transit, or in a shape. While
plates are out, their slots stay as a dashed socket (the debt, visible). A shape may draw a plate
larger than it was in the bar: that growth is the declared impossible beat, never hidden.

## Morph engine

- A morph moves plates; nothing else carries mass. Text sits only on plates at rest or settled.
- Timing on motion tokens. A morph is usable from its first frame and complete within 450 ms; a
  second morph requested mid-flight retargets the plates from where they are, with no queue.
- Reduced motion: states switch without travel or growth; continuous motion becomes a static
  readout.

## Reference shape 1: the launcher

| | |
|---|---|
| Trigger | Super (as today's launcher key) |
| Frame 0 | the core plates leave a dashed socket; the query is typed into it, already live |
| Motion | per plate, 6 ms apart: fold edge-on (short2, emphasized accelerate), cross the screen at the plate's own size as a line of light (short3, standard), unfold and grow to a 200 × 168 tile (short3, emphasized decelerate); last tile at about 440 ms |
| Content | eight tiles: index, code, name; the selected tile's light `secondary` |
| Close | Escape or launch: the same motion in reverse |
| Spectrum running | the blades become plates at once (no merge animation) and the launcher starts |

## Reference shape 2: the spectrum

| | |
|---|---|
| Trigger | a player reports Playing over MPRIS |
| Split | each core plate becomes 4 blades (32), on short2 |
| Windows on the workspace | blades are meters inside the core plates: never drawn over a window |
| Workspace with no windows | blades telescope below the bar, up to 200 px, with lit tips and falling peak ticks (time-based decay) |
| Input | click-through: the blades are outside the bar's input region |
| Hide | a key toggles it (to be chosen: super+m is mango's monitor mode) |
| Stop | Paused or Stopped: blades retract and merge |
| Reduced motion | no blades: the core reads PLAYING with the track |
| Data | `cava` (already installed for waybar's ribbons), 32 bands at 30 frames a second |

## Data sources

Tags, the windows on each tag and the focused window come from mango over `mmsg` (as waybar's
modules do today; mango has no foreign-toplevel management). MPRIS through `playerctl` or the
renderer's own MPRIS support. Time, network and battery as waybar reads them.

## Renderer

A Wayland layer-shell program that can draw plates, 3D rotation about the x axis, and per-frame
geometry at the display's refresh rate. Recommendation: **Quickshell** (QML on Qt Quick:
layer-shell surfaces, `Rotation` with an x axis, springs and easing curves, MPRIS built in, runs
`mmsg` and `cava` as processes). It is a new package (AUR `quickshell`), so it needs approval.
Rejected: waybar (no free geometry or morphs), eww (no 3D transforms, polling model), AGS/Astal on
GTK4 (possible, weaker motion primitives).

Repo shape, one model for every app: a `bar/` app folder with `packages` (quickshell), the QML
under `.config/quickshell/`, its colors and tokens from a `Theme.qml.tmpl` rendered by `theme`,
a `reload.sh`, and `quickshell.service` as a session user unit (`PartOf`/`After`/`WantedBy`
`graphical-session.target`). Waybar's top status bar is retired when the bar ships (one body);
its bottom media bar stays.

## Acceptance

1. In desktop-vm: shots of rest, launcher open, spectrum with windows (blades inside the core)
   and on an empty workspace (blades below), in `space` and `space-light`.
2. Launcher: query echoes on the first frame after Super; last tile settled within 450 ms
   (frame timestamps logged by the bar in a debug mode).
3. Mass: the debug mode logs the plate count per frame; it is 8 in every frame of a scripted run
   (open, close, open mid-close, spectrum on and off, launcher during spectrum).
4. Workspace plates never change position (their geometry logged before and after every morph).
5. Reduced motion: no plate travels; the spectrum shows the static readout.
6. `theme lint`, `tools/docs --check`, `tests/run`; the keybindings cheatsheet lists the new keys.

## Open questions

1. **Renderer**: approve Quickshell as a new package, or name another.
2. **External screens**: the map says the list stays up on every screen, and that the body is
   never in two places at full size. Proposal: every output has a bar; only the focused output's
   bar has a live core (the others show their core as a dim readout and never morph).
3. **The spectrum's key**: which binding hides it (super+m is taken).
4. **Waybar**: retire only the top status bar (proposed), or the media bar too.

# SPEC-bar: a small core and its pieces

Module `bar` of the [Material shapeshifter map](README.md). Status: draft (revision 2), awaiting
approval. Date: 2026-11-23. Depends on [SPEC-theme](SPEC-theme.md) (built: `m3_*` roles and the
system tokens). The design canvas board "Chosen, revised: a small core and its pieces" is the
visual reference; where this text and the board differ, this text wins.

## Goal

The bar is a small fixed core at the top of the screen; everything else is moving pieces. Every
shell component is its own pieces: two for a large component, one for a small one. At rest the
pieces dock beside the core, each showing its component's compact face; to open, a component's
pieces detach, travel and morph into it, and they return when it closes. This spec covers the
core, the pieces, the mass model, the morph engine, and the components whose pieces are drawn on
the board. The detailed shapes of notifications, OSDs, power, lock and the key overlay, and the
greeter, come in their own specs on the same engine.

## Non-goals

- The always-on instrument panel (outside the map): today's bottom media bar is not touched.
- Wallpaper-driven color, a second complete component beside the body (outside the map).

## The core and the pieces

| component | pieces | docked face | opens into |
|---|---|---|---|
| core | fixed | time and date | never moves |
| workspaces | 2 | two tags each, naming their windows (14 px) | stays docked |
| launcher | 2 | `› run` / `apps` | search and list (left), details (right), side by side |
| media | 1 | the track | the spectrum (below) |
| notifications | 1 | the count | a card under its dock |
| volume, brightness | 1 each | the level | a vertical meter under its dock |
| power | 2 | glyphs | two rows: lock and log out, reboot and power off |
| lock, key overlay | 2 each | none | ride under the core; slide out when called |

- Pieces: 56 px tall, docked 8 px apart either side of the core, 8 px cut corners (a
  shell-specific shape, not an M3 shape token, recorded here). The core is 64 px tall, centred.
- Color only from `m3_*` roles: pieces `surface_container_high`, borders `outline`, the core
  `surface_container_highest` with a `primary` edge, text `on_surface` / `on_surface_variant`,
  the active workspace `secondary`, meters and lit edges `primary` / `primary_container`, the
  destructive action `error`. No color literal: a `.tmpl` per the repo's rule.
- Type from the type tokens (IBM Plex Sans); IBM Plex Mono for codes and readouts, a deviation
  from SPEC-theme's single typeface, recorded here.
- At rest nothing moves: no idle animation.

## Mass

Mass is piece count: 10 docked plus 4 under the core. A component spends only its own pieces and
returns them when it closes. A piece is in exactly one place at any frame: docked, in transit, or
in its component. An empty dock shows a dashed socket. A piece may grow as it becomes its
component; the growth is declared, never hidden.

## Morph engine

- A morph moves pieces; the core never moves. Text sits only on docked or settled pieces.
- Two motions, both on motion tokens:
  - Large components (two pieces): fold edge-on (short2, emphasized accelerate), cross at the
    piece's own size as a line of light (short3, standard), unfold and grow (short3, emphasized
    decelerate); the second piece 30 ms behind the first; settled at about 430 ms.
  - Small components (one piece): move and stretch on the fast spatial spring.
- Usable from the first frame (the launcher's query is live as its pieces leave); complete
  within 450 ms; a second request mid-flight retargets pieces from where they are.
- Two components never share a piece, so any of them can be open at once; where two would
  overlap on screen, the later one opens beside the earlier.
- Reduced motion: states switch without travel; the spectrum becomes a static PLAYING face.

## The spectrum

| | |
|---|---|
| Trigger | a player reports Playing over MPRIS; the media piece shows the track |
| Windows on the workspace | 16 meters inside the media piece: never drawn over a window |
| Workspace with no windows | the meters telescope below the media piece, up to 190 px, lit tips |
| Input | click-through: the blades are outside the bar's input region |
| Hide | a key toggles it (to be chosen: super+m is mango's monitor mode) |
| Data | `cava` (already installed for waybar's ribbons), 16 bands at 30 frames a second |

## Data sources

Tags, the windows on each tag and the focused window from mango over `mmsg` (as waybar does
today; mango has no foreign-toplevel management). MPRIS through `playerctl` or the renderer.
Time, network, battery, volume and brightness as waybar reads them; notifications from the
notification daemon (mako today: the notifications spec decides whether the bar takes over).

## Renderer

A Wayland layer-shell program that can draw pieces, 3D rotation about the x axis and per-frame
geometry at the display's refresh rate. Recommendation: **Quickshell** (QML on Qt Quick:
layer-shell surfaces, `Rotation` with an x axis, springs and easing curves, MPRIS built in, runs
`mmsg` and `cava` as processes). It is a new package (AUR `quickshell`), so it needs approval.
Rejected: waybar (no free geometry or morphs), eww (no 3D transforms, polling model), AGS/Astal on
GTK4 (possible, weaker motion primitives).

Repo shape, one model for every app: a `bar/` app folder with `packages` (quickshell), the QML
under `.config/quickshell/`, colors and tokens from a `Theme.qml.tmpl` rendered by `theme`, a
`reload.sh`, and `quickshell.service` as a session user unit (`PartOf`/`After`/`WantedBy`
`graphical-session.target`). Waybar's top status bar is retired when the bar ships (one body);
its bottom media bar stays.

## Acceptance

1. In desktop-vm, shots of rest, launcher, notification, volume, spectrum (windows open and an
   empty workspace) and power, in `space` and `space-light`.
2. Launcher: query echoes on the first frame after super+d; both pieces settled within 450 ms
   (frame timestamps logged in a debug mode).
3. Mass: the debug mode logs the piece count per frame; 10 docked + 4 under the core in every
   frame of a scripted run (each component open and closed, two at once, reopen mid-close).
4. The core and the workspace pieces never change position (logged before and after every morph).
5. Reduced motion: no piece travels; the spectrum shows the static face.
6. `theme lint`, `tools/docs --check`, `tests/run`; the keybindings cheatsheet lists new keys.

## Open questions

1. **Renderer**: approve Quickshell as a new package, or name another.
2. **External screens**: every output gets a core and docked pieces (the list stays up
   everywhere); a component opens only on the focused output, and only that output's pieces move
   (the body is never in two places at full size). Proposal; confirm.
3. **The spectrum's key**: which binding hides it (super+m is taken).
4. **Workspaces**: they never leave the dock here. Should they also morph (an overview), and with
   how many pieces?
5. **Waybar**: retire only the top status bar (proposed), or the media bar too.

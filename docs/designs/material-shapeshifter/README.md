# Capability Map: Material shapeshifter

Approved 2026-11-22. Specs in this directory are named `SPEC-<module id>.md`. This file is the index.

| Module id | Responsibility | Depends on | Spec |
|---|---|---|---|
| theme | One custom theme, `space` / `space-light`. Material 3 roles and tones. Key colors are COLOURlovers Space 787684, with Gruber Darker's red, green, and niagara, and Alchemist's yellow-as-cursor rule. `theme set` still paints the shell and GTK. The four existing palette files stay untouched. | none | [revision 3, approved](SPEC-theme.md), [plan](PLAN-theme.md): M1-M3 done, M4 (desktop-vm, merge) needs your machine |
| bar | One shapeshifter. Visible morph, any direction, any form. Each morph spends mass. A destroyed shape returns that mass to the bar. The body is never in two places at full size. | theme | [draft, revision 4](SPEC-bar.md) |
| greeter | The greeter is the bar in the greeter's shape. This is the success view. | bar | not started |
| session | Every in-session shell piece is the bar in another shape: workspace list, menus, launcher, notifications, volume, brightness, power, lock, key overlay. The list stays up on the panel and on external screens. Each workspace row names the windows on that tag. | bar | not started |
| gtk | GTK apps wear the active palette. They are not the bar. | theme | not started |

Build order: theme → bar → greeter, session. gtk after theme, beside bar.

Outside the map: terminals, editors, boot splash, the always-on instrument panel, wallpaper-driven color, a second complete component beside the body.

Color system: [Material 3 color roles](https://m3.material.io/styles/color/roles).

## Bar: decisions so far (input to SPEC-bar)

Explored on the design canvas; not a spec yet.

- Direction: **the whole shell on waybar and the apps we have** (canvas board "Chosen: the
  shell redesigned on waybar and the existing apps"). No new renderer: the user ruled out
  Quickshell. Waybar draws a fixed core (the clock, never moves or morphs) and one M3 pill piece
  per component; each component is its existing app reshaped to M3 and placed under its piece:
  rofi (search view), mako (cards), swayosd (slider), wlogout (menu). Pieces do not travel or
  morph; components open with mango's layer motion, and a waybar drawer widens a piece in place.
- Spectrum: inside the media piece only; waybar cannot draw below the bar.
- Superseded on the way here: the reserve core (v1), components of two or many pieces (v2), and
  one piece that stretches into its component (v3, needs a renderer the stack lacks).
- Explored and set aside: Penrose (five shapes), the relic and organism framings, the jelly
  direction. Rejected outright: goo connections, toy shapes, captions claiming effects the
  geometry does not show, shapes that cover windows for long stretches.
- Open for the spec: the renderer (a layer-shell program; a new package needs approval), cut
  corners as a shell-specific shape (not an M3 token), the other session shapes (notifications,
  OSDs, power, lock, key overlay), and external screens.

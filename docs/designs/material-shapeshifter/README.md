# Capability Map: Material shapeshifter

Approved 2026-11-22. Specs in this directory are named `SPEC-<module id>.md`. This file is the index.

| Module id | Responsibility | Depends on | Spec |
|---|---|---|---|
| theme | One custom theme, `space` / `space-light`. Material 3 roles and tones. Key colors are COLOURlovers Space 787684, with Gruber Darker's red, green, and niagara, and Alchemist's yellow-as-cursor rule. `theme set` still paints the shell and GTK. The four existing palette files stay untouched. | none | [revision 3, approved](SPEC-theme.md), [plan](PLAN-theme.md): M1-M3 done, M4 (desktop-vm, merge) needs your machine |
| bar | One shapeshifter. Visible morph, any direction, any form. Each morph spends mass. A destroyed shape returns that mass to the bar. The body is never in two places at full size. | theme | [draft, revision 2](SPEC-bar.md) |
| greeter | The greeter is the bar in the greeter's shape. This is the success view. | bar | not started |
| session | Every in-session shell piece is the bar in another shape: workspace list, menus, launcher, notifications, volume, brightness, power, lock, key overlay. The list stays up on the panel and on external screens. Each workspace row names the windows on that tag. | bar | not started |
| gtk | GTK apps wear the active palette. They are not the bar. | theme | not started |

Build order: theme → bar → greeter, session. gtk after theme, beside bar.

Outside the map: terminals, editors, boot splash, the always-on instrument panel, wallpaper-driven color, a second complete component beside the body.

Color system: [Material 3 color roles](https://m3.material.io/styles/color/roles).

## Bar: decisions so far (input to SPEC-bar)

Explored on the design canvas; not a spec yet.

- Direction: **a small core and its pieces** (canvas board "Chosen, revised: a small core and
  its pieces"). The bar is a small core at the top centre (time and date) that never moves or
  morphs; everything else is moving pieces docked beside it. Every shell component is its own
  pieces: one for a small one (media, notifications, volume, brightness), two for a large one
  (workspaces, launcher, power, lock, key overlay), or many where its shape is a grid of cells. To open, a component's pieces detach, travel and morph into it, leaving a
  dashed socket; they return on close. Mass is piece count. Machined pieces with cut corners.
- Launcher: two pieces fold edge-on, cross and unfold side by side; query live from frame 0;
  settled at about 430 ms.
- Spectrum: the media piece. Windows open: meters inside the piece. Empty workspace: they
  telescope below it. Click-through, hidden with a key; reduced motion: a static face.
- Superseded on the way here: the reserve core as one 8-plate middle (v1 of the chosen
  direction).
- Explored and set aside: Penrose (five shapes), the relic and organism framings, the jelly
  direction. Rejected outright: goo connections, toy shapes, captions claiming effects the
  geometry does not show, shapes that cover windows for long stretches.
- Open for the spec: the renderer (a layer-shell program; a new package needs approval), cut
  corners as a shell-specific shape (not an M3 token), the other session shapes (notifications,
  OSDs, power, lock, key overlay), and external screens.

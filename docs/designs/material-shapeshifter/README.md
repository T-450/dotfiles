# Capability Map: Material shapeshifter

Approved 2026-11-22. Specs in this directory are named `SPEC-<module id>.md`. This file is the index.

| Module id | Responsibility | Depends on | Spec |
|---|---|---|---|
| theme | One custom theme, `space` / `space-light`. Material 3 roles and tones. Key colors are COLOURlovers Space 787684, with Gruber Darker's red, green, and niagara, and Alchemist's yellow-as-cursor rule. `theme set` still paints the shell and GTK. The four existing palette files stay untouched. | none | [revision 3, approved](SPEC-theme.md), [plan](PLAN-theme.md): M1-M3 done, M4 (desktop-vm, merge) needs your machine |
| bar | One shapeshifter. Visible morph, any direction, any form. Each morph spends mass. A destroyed shape returns that mass to the bar. The body is never in two places at full size. | theme | not started |
| greeter | The greeter is the bar in the greeter's shape. This is the success view. | bar | not started |
| session | Every in-session shell piece is the bar in another shape: workspace list, menus, launcher, notifications, volume, brightness, power, lock, key overlay. The list stays up on the panel and on external screens. Each workspace row names the windows on that tag. | bar | not started |
| gtk | GTK apps wear the active palette. They are not the bar. | theme | not started |

Build order: theme → bar → greeter, session. gtk after theme, beside bar.

Outside the map: terminals, editors, boot splash, the always-on instrument panel, wallpaper-driven color, a second complete component beside the body.

Color system: [Material 3 color roles](https://m3.material.io/styles/color/roles).

## Bar: decisions so far (input to SPEC-bar)

Explored on the design canvas; not a spec yet.

- Direction: **Penrose**. The launcher is the bar's band pulled down into a loop whose left post
  passes in front of the bar and right post behind it; the band's length is the mass. The bar's
  silhouette (pill, islands, notch, frame or Möbius) is still open.
- Reframed as ancient alien technology: a living, reactive structure with moving pieces (an
  original design in that genre, not a recreation of any film's). Engraved carapace plates carry
  the text and never move; between them a spine of 36 vertebrae breathes, leans toward the
  pointer, and is the bar's mass. The launcher's Penrose loop is built from vertebrae; the ribs
  under them are the spectrum. Breathing stops under reduced motion.
- At the top of the screen, 64 px. Workspace rows never move and name their windows legibly.
- Audio: the spectrum (the core that telescopes into blades) is liked. On a workspace with no
  windows it may extend below the bar; with windows open it stays inside the bar as a widget.
- Rejected: jelly or goo connections, toy shapes, captions claiming effects the geometry does not
  show, and shapes that cover windows for long stretches.

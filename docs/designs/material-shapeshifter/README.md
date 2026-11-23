# Capability Map: Material shapeshifter

Approved 2026-11-22. Specs in this directory are named `SPEC-<module id>.md`. This file is the index.

| Module id | Responsibility | Depends on | Spec |
|---|---|---|---|
| theme | One custom theme, `space` / `space-light`. Material 3 roles and tones. Key colors are COLOURlovers Space 787684, with Gruber Darker's red, green, and niagara, and Alchemist's yellow-as-cursor rule. `theme set` still paints the shell and GTK. The four existing palette files stay untouched. | none | [draft](SPEC-theme.md) |
| bar | One shapeshifter. Visible morph, any direction, any form. Each morph spends mass. A destroyed shape returns that mass to the bar. The body is never in two places at full size. | theme | not started |
| greeter | The greeter is the bar in the greeter's shape. This is the success view. | bar | not started |
| session | Every in-session shell piece is the bar in another shape: workspace list, menus, launcher, notifications, volume, brightness, power, lock, key overlay. The list stays up on the panel and on external screens. Each workspace row names the windows on that tag. | bar | not started |
| gtk | GTK apps wear the active palette. They are not the bar. | theme | not started |

Build order: theme → bar → greeter, session. gtk after theme, beside bar.

Outside the map: terminals, editors, boot splash, the always-on instrument panel, wallpaper-driven color, a second complete component beside the body.

Color system: [Material 3 color roles](https://m3.material.io/styles/color/roles).

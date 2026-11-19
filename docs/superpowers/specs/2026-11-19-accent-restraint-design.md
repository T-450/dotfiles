# Accent restraint: cool common UI, sparse accent

## Intent

An elegant, minimal desktop: everyday UI (bar structure, borders, hover, icons, dates) reads in
each palette's cool tones, and the palette's accent appears only where the eye should land, so it
contrasts with the cool UI. Palettes keep their colors; only which role goes where changes.

## Goals

- The accent marks focus and the active item only: focused window border, active workspace,
  focused window title, the lock screen's input ring, the selected launcher row and logout button,
  the selected search match in ghostty, GTK's own accent.
- Common UI uses the cool role, `ansi6` (terminal cyan), muted toward its ground where it is
  structure rather than content.
- Decoration loses its own hues and glows: no orange start button, no magenta window-state
  outline, no glow around the active workspace or the start button.
- State colors (warning, error) still show state: keymode, urgent windows, critical notifications,
  battery and capture alerts.

## Non-goals

- Palette files: unchanged.
- Editors, TUIs and browsers (vim, helix, btop, lazygit, Claude Code, Pi, qutebrowser, firefox,
  mousepad, mpv): their schemes follow their sources and stay as they are.
- New theme machinery (a derived `ui` word, per-palette pointers): rejected as approaches 2 and 3.

## Anti-goals

- A desktop that looks flat or dead: focus must stay obvious at a glance.
- Text below its current contrast (`legible` stays where it is).

## Approaches

1. **Chosen: one cool role, muted, in the templates.** Templates use `ansi6` for common UI and
   restrict `accent` to focus points. Warm-accent palettes (Alchemist, Apprentice, Gruber Darker,
   Colibri) contrast by hue; in the 12 whose accent is itself blue or cyan the contrast comes from
   strength: muted cyan against the full accent.
2. `theme` derives a `ui` word per palette: the cool color furthest in hue from the accent. More
   hue contrast, but a heuristic that misfires (Elysian's grey badge, Rain's blue 14 degrees from
   its accent) and new code in `theme`.
3. Each palette names its UI color (`ui = "ansi12"`): most control, 17 hand picks, palette edits.

`ansi4` was weighed against `ansi6`: both sit within 25 degrees of the accent in 9-10 palettes, and
the bar is already built on `ansi6`, so `ansi6` changes least.

## Changes

| Where | Today | After |
|---|---|---|
| mako, every notification | border `accent`, title `syn_keyword` | border `ansi6` muted, title `fg_bright` |
| rofi input bar | border `accent` | border `ansi6` muted |
| swayosd fill | `syn_constant` (often orange) | `ansi6`, legible on the OSD |
| waybar start button | `@orange`, orange glow on hover | `@text`, cyan on hover, no glow |
| waybar window state | `@magenta` outline | `@cyan` outline |
| waybar active workspace | `@signal` fill with glow | `@signal` fill, no glow |
| waybar clock hover | cyan glow | no glow |

Kept on the accent: mango `focus_color` and `drop_color`, waybar active workspace and focused
title, hyprlock ring and check, rofi selected row border, wlogout selected button, ghostty search
match, GTK `accent_color`. Kept as state: waybar `@orange` keymode, `@warn`/`@crit`, mango
`urgent_color` and `global_color`, mako critical.

## Left to the builder

- "Muted": the exact mix toward the ground per element, chosen so borders read as hairlines
  (roughly `border_inactive` weight) on dark and light palettes alike; shown in previews.
- Whether `@magenta` and `@orange` color definitions remain used after the change; drop any that
  no longer are.

## Verification

- `theme init <slug> --to <scratch>` for Alchemist (warm accent), Space (cool accent, dark) and
  Metro (light): before/after previews of the bar, a notification, the launcher and the OSD,
  approved by the user before merging or applying live.
- `theme lint`, `tools/docs --check`, `tests/run`.

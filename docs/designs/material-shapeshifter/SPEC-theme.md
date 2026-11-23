# SPEC-theme: Space, a Material 3 design system

Module `theme` of the [Material shapeshifter map](README.md). Status: revision 3, awaiting
approval: revision 2 (approved 2026-11-23) amended with the plan review's findings. Revision 2
widened the module to the whole M3 system: color, type, shape, elevation, motion and state. Date: 2026-11-23. Inputs: two
computed palettes, `space.toml` (dark) and `space-light.toml` (light), audited below.

## Goal

The Material 3 design system the shapeshifter shell is built from, in two parts:

- **Color**: two palettes, `space` and `space-light`, that carry the full M3 role set and still
  drive every app the repo themes today. Every existing template keeps reading the legacy roles,
  which the palette maps from the M3 roles.
- **System tokens**: M3's type scale, shape scale, elevation levels, motion (durations and
  easing) and state-layer opacities, one set for every palette.

`bar`, `greeter` and `session` take every color, size, corner, curve and opacity from these
tokens and write none of their own: a morph is a change between two shape tokens on a motion
token.

## Non-goals

- No existing palette file changes. All ten files in `theme/palettes/` stay byte-identical (the
  map says "four"; the repo has ten).
- No generator in the repo. The scheme is computed once and committed, as the inputs say. The
  palette header records how (scheme variant, key colors, tool), so a rerun is reproducible.
- No wallpaper-driven color (outside the map).

## Data

Each palette file has the usual tables plus one new one:

| table | holds | read by |
|---|---|---|
| `[meta]` | name, variant, source | `theme` |
| `[material]` | the 45 M3 roles, snake_case (`primary` … `scrim`) | bar, greeter, session (as `m3_<role>`) |
| `[colors]` | the 21 legacy roles, each one M3 role by the mapping below | every existing template |
| `[terminal]` | fg, bg, cursor, 16 ANSI | ghostty, editors |
| `[syntax]` | `keyword`, `constant`, `number` (below); the rest default | vim, helix |

The 14 fixed roles (`*_fixed*`, `shadow`, `scrim`) are identical in both files, as M3 defines them.

### Scheme

- Variant: **Fidelity** (M3 content-based), as `materialyoucolor` 3.0.4 computes it: only
  `primary_container` is the source color itself. The secondary and tertiary containers sit at
  the primary source's tone (64 in HCT) on their own palettes, and dark `secondary` is the
  yellow's tone 80, not the bright source. Accepted as computed, not overridden: overriding
  containers would mean recomputing every `on_*` partner by hand. Light and dark come from the
  same tonal palettes; only tones differ.
- Key colors: primary = Space's blue, secondary = the Alchemist/Space yellow, tertiary = Gruber
  niagara, error = Gruber red, neutral = Space's navy at HCT hue 283, chroma 6. The header lists
  each key color's hex and its source swatch. Checked: HCT tonal palettes of the dark input's
  `primary`, `secondary` and `tertiary` reproduce all 12 fixed roles of both inputs exactly, so
  those three are the key colors. Neutral variant: the same hue at chroma 8 (the inputs' outline
  measures 8.5).
- Gruber's green is an M3 custom color (not harmonized: it is a named source color).
- Rule for every named source color (red, green): dark uses the source hex if it reads 4.5:1 on
  `surface`, light uses its tone-40 version. The inputs already do this for red; green follows.

### Legacy role mapping

One table for both variants; no per-variant exceptions.

| legacy role | M3 role |
|---|---|
| `bg_desktop` | `surface` |
| `bg_surface` | `surface_container` |
| `bg_widget` | `surface_container_high` |
| `bg_hover` | `surface_container_highest` |
| `border_hairline` | `outline_variant` |
| `border_inactive`, `fg_muted` | `outline` |
| `fg_text`, `fg_editor` | `on_surface` |
| `fg_secondary` | `on_surface_variant` |
| `fg_bright` | neutral palette at tone 98 (dark) / tone 4 (light): above `on_surface` |
| `fg_disabled` | `outline_variant` |
| `accent`, `link` | `primary` |
| `badge` | `tertiary` |
| `selection_bg` / `selection_fg` | `secondary_container` / `on_secondary_container` |
| `error` | `error` |
| `warning` | `secondary` (yellow) |
| `success` | custom green, color role |
| `shadow` | `shadow` |
| `terminal.cursor`, `syntax.keyword` | `secondary` (Alchemist: the yellow is the cursor and the keyword) |
| `syntax.constant`, `syntax.number` | `tertiary`, custom magenta (so keyword, constant and number stay three colors; the defaults would collapse them onto `ansi3` = `secondary`) |
| `terminal.fg`, `terminal.bg` | `on_surface`, `surface` |

### Terminal

Each ANSI slot is its hue, so `ls`, git and test runners read as written:

| slot (normal / bright) | source |
|---|---|
| 0 black | dark: `surface_container_lowest` (a step below the background, as Gruber Darker); light: `on_surface` |
| 1 / 9 red | error |
| 2 / 10 green | custom green |
| 3 / 11 yellow | secondary |
| 4 / 12 blue | primary |
| 5 / 13 magenta, 6 / 14 cyan | custom colors at those hues, primary's chroma; normal row tone 80 dark, 40 light |
| 7 white | dark: `on_surface_variant`; light: `outline_variant` |
| 8 bright black | `outline` |
| 15 bright white | dark: `fg_bright`; light: `surface_container_lowest` |

Bright row: the same palette 10 tones toward the text (lighter on dark, darker on light). Floors on
`terminal.bg`: chromatic slots 4.5:1, slot 8 3:1.

### Keycaps

No `[keycaps]` in either file: both derive from their own roles, like every imported palette.

## System tokens (theme/tokens.toml)

One file, read with the active palette, palette-independent (M3 defines these once, not per
scheme). Values are M3's system tokens as Jetpack Compose `material3` 1.5.0 (latest stable,
Apache-2.0) ships them in `androidx/compose/material3/tokens/*.kt`, read from the sources jar,
not from memory. Units: px at scale 1 (M3's dp and sp), ms, unitless opacity.

| group | tokens |
|---|---|
| shape (corner radius) | none 0 · extra-small 4 · small 8 · medium 12 · large 16 · large-increased 20 · extra-large 28 · extra-large-increased 32 · extra-extra-large 48 · full (a circle: half the short side) |
| elevation (shadow) | level0 0 · level1 1 · level2 3 · level3 6 · level4 8 · level5 12 |
| motion spring (damping, stiffness) | Expressive scheme: spatial fast 0.6/800 · default 0.8/380 · slow 0.8/200; effects fast 1/3800 · default 1/1600 · slow 1/800 |
| motion duration | short1-4 50/100/150/200 · medium1-4 250/300/350/400 · long1-4 450/500/550/600 · extra-long1-4 700/800/900/1000 |
| motion easing (cubic bezier) | standard 0.2,0,0,1 · standard-accelerate 0.3,0,1,1 · standard-decelerate 0,0,0,1 · emphasized 0.2,0,0,1 · emphasized-accelerate 0.3,0,0.8,0.15 · emphasized-decelerate 0.05,0.7,0.1,1 · linear 0,0,1,1 |
| state layer opacity | hover 0.08 · focus 0.10 · pressed 0.10 · dragged 0.16 |
| type scale (size/line height) | display L/M/S 57/64, 45/52, 36/44 · headline L/M/S 32/40, 28/36, 24/32 · title L/M/S 22/28, 16/24, 14/20 · body L/M/S 16/24, 14/20, 12/16 · label L/M/S 14/20, 12/16, 11/16 |
| type weight, tracking | weight 400, except title M/S and every label 500. Tracking: display L -0.2, title M and body M 0.2, title S and label L 0.1, body L 0.5, body S 0.4, label M/S 0.5, the rest 0 |
| emphasized type (Expressive) | same sizes; weight 500, except title M/S and every label 700; tracking: body L and title M 0.15, body M 0.25, body S 0.4, title S and label L 0.1, label M/S 0.5, the rest 0. Display, headline and title L use `brand`, the rest `plain` |
| typeface | `brand` and `plain`: IBM Plex Sans (installed, GTK's font; M3's Roboto is not installed) |

Springs: the shell uses M3's **Expressive** motion scheme (spatial springs that overshoot), not
Standard (damping 0.9 throughout): a shapeshifter is M3's case for expressive motion. Spatial
springs move position and shape; effects springs (no overshoot) move color and opacity.
Durations and easing stay for things that are not springs (fades in GTK CSS, mango's animation
curves).

Cross-check: `@material/web` 2.5.0 (`tokens/versions/v0_192`, older) agrees on durations,
easing, elevation and the shared corners, and differs on focus and pressed (0.12) and three
trackings (display L -0.25, body M 0.25, title M 0.15). Compose's token versions are newer
(state `v0_210`), so Compose wins.

The words, all of them (TOML keys use underscores, so a key and its word match):

- `shape_corner_<size>` for none, extra_small, small, medium, large, large_increased,
  extra_large, extra_large_increased, extra_extra_large, full (`9999`, the CSS convention for
  fully rounded; Compose's `CircleShape`)
- `elevation_level0` … `elevation_level5`
- `motion_spring_<spatial|effects>_<fast|default|slow>_<damping|stiffness>`
- `motion_duration_<short|medium|long|extra_long><1-4>`
- `motion_easing_<standard|standard_accelerate|standard_decelerate|emphasized|emphasized_accelerate|emphasized_decelerate|linear>`
- `state_<hover|focus|pressed|dragged>`
- `type_<display|headline|title|body|label>_<large|medium|small>_<size|line_height|weight|tracking>`,
  and the same under `type_emphasized_` plus `_font`
- `type_font_brand`, `type_font_plain`

Left out of Compose's files on purpose: the one-sided corners (`*Top`, `*Start`, `*End`), the
`CornerValue*` duplicates, the legacy easings and the Standard scheme's springs.

Templates read tokens as words, for example:
`{{shape_corner_large}}` is `16`, `{{motion_duration_medium2}}` is `300`,
`{{motion_easing_emphasized_decelerate}}` is `0.05, 0.7, 0.1, 1`,
`{{type_label_large_size}}` is `14`. Each template adds its own unit, as it does for colors.
A state layer is a color: `{{m3_surface|mix:m3_on_surface:state_hover}}`.

## Changes to `theme`

1. `load_palette` reads an optional `[material]` table: all 45 names or none, known names only,
   hex values. It exposes them to templates as `m3_<role>` (prefix: `error` and `shadow` exist in
   both sets).
2. A palette without `[material]` derives the 45 roles from its legacy roles, so `bar` works
   under every palette, as `keycap_defaults` does for keycaps. The mapping above, inverted:
   `primary` ← `accent`, `secondary` ← `warning`, `tertiary` ← `badge`, `error` ← `error`;
   containers are the base mixed 60% toward `bg_desktop`; fixed roles are the base, then mixed
   50% toward white (`X_fixed`), 80% and 50% toward black (`on_X_fixed`, `on_X_fixed_variant`).
   Every text role the floor check covers is derived through `ink` or `legible`, including
   `on_surface` (`fg_text` made legible at 4.5:1 on `bg_desktop`), so a derived palette meets the
   floors by construction and no import that loads today fails after this change.
3. `load_palette` fails a palette whose pairs read below the floors. The pairs, exactly: at
   4.5:1, `on_X` on `X` for X in primary, secondary, tertiary, error and their four containers,
   `on_surface` and `on_surface_variant` on `surface`, `inverse_on_surface` on `inverse_surface`;
   at 3:1, `outline` on `surface`. Deliberately unchecked: the fixed pairs (constants M3 computes
   once; a derived gruber-darker would read 4.31:1 there) and text on surface containers (colibri's
   `fg_text` on `bg_hover` reads 3.99:1 today; `bar` decides when it draws text on containers).
   One failing palette fails every render (`render_all` loads all palettes for per-palette
   templates), which is why derived roles are made to pass. This replaces the inputs' "Contrast
   from theme.contrast" comment (no such module exists in the repo).
4. `theme` reads `theme/tokens.toml` against an allowlist in `theme` (a `TOKENS` table, as
   `ROLES` is for colors): known groups and names only. Value types: number, a four-number list
   (easings), string (the typeface family; the emphasized styles' font resolves to it). Each token
   becomes a template word (below). `mix`'s amount accepts a `state_*` word as well as a number.
5. `docs/theming.md` lists Space and documents `[material]` and the tokens; `tools/docs`
   regenerates the roles table.

## Audit of the inputs

Measured with `theme`'s own `contrast()` on the uploaded files. The header claims hold: dark
4.77 / 13.80 / 6.83 / 5.82, light 6.49 / 16.31 / 7.08 / 4.27. Both load today, with `[material]`
silently ignored. Defects:

| # | variant | defect | measured | fix (mapping above) |
|---|---|---|---|---|
| 1 | dark | `fg_bright` = `inverse_on_surface`, a dark color | 1.41:1 on `bg_desktop` | neutral tone 98 |
| 2 | light | `success` = Gruber green unchanged | 1.71:1 on `bg_desktop` | tone-40 green |
| 3 | both | cursor and keyword are primary blue, not the yellow the header names | `syn_keyword` = `tertiary` in both | `secondary` |
| 4 | both | ANSI hues scrambled: green and blue slots are primary, yellow is slate, cyan is yellow | slots 2, 3, 6 | hue table |
| 5 | light | `ansi0` is the background; bright row unreadable | 0: 1.0, 9: 1.2, 10-13: 2.3, 14: 1.2 | hue table, darker bright row |
| 6 | dark | `ansi8` is a surface (zsh autosuggestions vanish); `ansi9` dark red | 8: 1.1, 9: 2.0, 14: 3.6 | `outline`, lighter bright row |
| 7 | dark | `primary` ≈ `primary_container`: the container is not a lower-emphasis tier | 1.12:1 between them (light: 2.74) | Fidelity: primary tone 80 (the file's `primary_fixed_dim`), container = source |
| 8 | dark | same for `tertiary` / `tertiary_container` (niagara and a tone below it) | 1.25:1 between them | tertiary tone 80 over a container at tone 64: 1.62:1 apart (computed, see Scheme) |
| 9 | light | neutrals are not the dark file's neutrals: chroma climbs to a lavender `surface_dim` | HCT chroma: dark neutrals 6, light `surface_dim` 24, `on_surface` 36 | one neutral palette for both |
| 10 | dark | `on_surface` is a cyan tint, not the neutral tone 90 that `inverse_surface` is | | neutral tone 90 (see open question 1) |
| 11 | dark | `[keycaps].accent` = `bg_desktop`: the lit cap is not lit | identical hex | drop `[keycaps]` |
| 12 | both | `warning` = `tertiary` (blue-grey reads as info) | | `secondary` |

## Acceptance

1. `theme list` shows `space` and `space-light`; `theme set space` and `theme set space-light`
   repaint the shell and GTK.
2. `git diff --stat theme/palettes/` touches only the two new files.
3. `load_palette` rejects a copy of `space.toml` with one `[material]` role removed, and one with
   `on_primary` lowered below 4.5:1 (scratchpad reproduction, not a committed test).
4. Every floor in this spec measured by code on both files, numbers in the commit message.
5. A scratchpad template using one token of each group renders the values in this spec; an
   unknown token name fails with its name.
6. `theme lint`, `tools/docs --check`, `tests/run` pass; `desktop-vm check` PASS under each
   variant, with `session.png` and a terminal frame looked at.

## Open questions

1. **`on_surface` tint.** The dark input tints body text cyan and the light input navy, each off its neutral palette. Recommendation: no per-role tint; if the text
   should lean navy, raise the neutral chroma for every neutral role in both variants.
2. **Space's swatch hexes.** The key colors are recovered from the inputs (see Scheme), but
   COLOURlovers is not reachable from this session to confirm which 787684 swatch each one is.
   The palette header names them; a wrong name changes no color.
3. **Default palette.** The map does not say whether `space` replaces `colibri` as `DEFAULT`.
   Recommendation: not in this module; decide when `bar` lands, since `bar` is what needs it.

Decided: typeface IBM Plex Sans (`bar` may still pick its own face in its spec); Expressive
tokens from Compose `material3`, reached through the session's new `dotfiles` environment
(`dl.google.com` allowed).

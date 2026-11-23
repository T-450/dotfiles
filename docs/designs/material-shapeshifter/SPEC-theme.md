# SPEC-theme: Space, a Material 3 palette pair

Module `theme` of the [Material shapeshifter map](README.md). Status: draft, awaiting approval.
Date: 2026-11-23. Inputs: two computed palettes, `space.toml` (dark) and `space-light.toml`
(light), audited below.

## Goal

Two palettes, `space` and `space-light`, that carry the full Material 3 role set and still drive
every app the repo themes today. `bar`, `greeter` and `session` read the M3 roles; every existing
template keeps reading the legacy roles, which the palette maps from the M3 roles.

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
| `[syntax]` | `keyword` only (Alchemist rule); the rest default | vim, helix |

The 14 fixed roles (`*_fixed*`, `shadow`, `scrim`) are identical in both files, as M3 defines them.

### Scheme

- Variant: **Fidelity** (M3 content-based): the key colors show as themselves in the containers.
  Light and dark come from the same tonal palettes; only tones differ.
- Key colors: primary = Space's blue, secondary = the Alchemist/Space yellow, tertiary = Gruber
  niagara, error = Gruber red, neutral = Space's navy hue at chroma 6. The
  header lists each key color's hex and its source swatch.
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

### Terminal

Each ANSI slot is its hue, so `ls`, git and test runners read as written:

| slot (normal / bright) | source |
|---|---|
| 0 black | dark: `surface_container_lowest` (a step below the background, as Gruber Darker); light: `on_surface` |
| 1 / 9 red | error |
| 2 / 10 green | custom green |
| 3 / 11 yellow | secondary |
| 4 / 12 blue | primary |
| 5 / 13 magenta, 6 / 14 cyan | custom colors at those hues, primary's chroma |
| 7 white | dark: `on_surface_variant`; light: `outline_variant` |
| 8 bright black | `outline` |
| 15 bright white | dark: `fg_bright`; light: `surface_container_lowest` |

Bright row: the same palette 10 tones toward the text (lighter on dark, darker on light). Floors on
`terminal.bg`: chromatic slots 4.5:1, slot 8 3:1.

### Keycaps

No `[keycaps]` in either file: both derive from their own roles, like every imported palette.

## Changes to `theme`

1. `load_palette` reads an optional `[material]` table: all 45 names or none, known names only,
   hex values. It exposes them to templates as `m3_<role>` (prefix: `error` and `shadow` exist in
   both sets).
2. A palette without `[material]` derives the 45 roles from its legacy roles (the mapping above,
   inverted; containers and fixed roles mixed from their base role toward `bg_desktop`), so `bar`
   works under every palette, as `keycap_defaults` does for keycaps.
3. `load_palette` fails a palette whose pairs read below the floors: each `on_X` on `X` 4.5:1,
   `outline` on `surface` 3:1. This replaces the inputs' "Contrast from theme.contrast" comment
   (no such module exists in the repo) with a check that runs on every `theme set`.
4. `docs/theming.md` lists Space and documents `[material]`; `tools/docs` regenerates the roles
   table.

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
| 8 | dark | same for `tertiary` / `tertiary_container` (niagara and a tone below it) | 1.25:1 between them | tertiary tone 80, container = niagara |
| 9 | light | neutrals are not the dark file's neutrals: chroma climbs to a lavender `surface_dim` | OKLCH C: dark surfaces 0.010-0.011, light `surface_dim` 0.055, `on_surface` 0.098 | one neutral palette for both |
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
5. `theme lint`, `tools/docs --check`, `tests/run` pass; `desktop-vm check` PASS under each
   variant, with `session.png` and a terminal frame looked at.

## Open questions

1. **`on_surface` tint.** The dark input tints body text cyan and the light input navy, each off its neutral palette. Recommendation: no per-role tint; if the text
   should lean navy, raise the neutral chroma for every neutral role in both variants.
2. **Space's swatch hexes.** COLOURlovers is not reachable from this session, so which 787684
   swatch is primary and which is the navy is taken from the inputs. The palette header must
   name them.
3. **Default palette.** The map does not say whether `space` replaces `colibri` as `DEFAULT`.
   Recommendation: not in this module; decide when `bar` lands, since `bar` is what needs it.

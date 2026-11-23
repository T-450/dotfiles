# PLAN-theme: build the Space palette pair

Plan for [SPEC-theme](SPEC-theme.md). Status: draft, awaiting approval. Date: 2026-11-23.
Prompt: the [capability map](README.md). The map builds `theme` first and only `theme` has an
approved spec, so this plan builds `theme`; the rest of the map is in "After theme" at the end.

One commit per milestone. Each milestone ends with its own checks passing; a failed check stops
the milestone (find whether the change, the check or the environment is wrong, fix one thing,
re-check).

## M1. `theme` reads `[material]` (theme/.local/bin/theme)

- [ ] `MATERIAL`: the 45 role names, in the inputs' order.
- [ ] `load_palette`: an optional `[material]` table is all 45 names or absent; unknown names and
      non-`#rrggbb` values fail, as `[keycaps]` does. Roles land in `v` as `m3_<role>`.
- [ ] `material_defaults(v)`, used when the table is absent, from the palette's own roles:

      | M3 roles | from |
      |---|---|
      | `primary`, `secondary`, `tertiary`, `error` | `accent`, `badge`, `ansi5`, `error` |
      | `on_X` | `ink(X)` |
      | `X_container` / `on_X_container` | `X` mixed 60% toward `bg_desktop` / its `ink` |
      | `X_fixed_dim`, `X_fixed`, `on_X_fixed`, `on_X_fixed_variant` | `X`, then `X` mixed 50% toward white, 80% and 50% toward black |
      | `surface`, `surface_dim` | `bg_desktop` |
      | `surface_container_lowest`, `_low` | `bg_desktop` 50% toward its far pole; `bg_desktop` halfway to `bg_surface` |
      | `surface_container`, `_high`, `_highest`, `surface_bright` | `bg_surface`, `bg_widget`, `bg_hover`, `bg_hover` |
      | `on_surface`, `on_surface_variant` | `fg_text`, `fg_secondary` |
      | `outline`, `outline_variant` | `border_inactive` made `legible` at 3:1 on `bg_desktop`, `border_hairline` |
      | `inverse_surface`, `inverse_on_surface`, `inverse_primary` | `fg_text`, `bg_desktop`, `accent` made legible on `fg_text` |
      | `shadow`, `scrim` | `shadow` |

      Every `on_*` goes through `ink` and `outline` through `legible`, so derived roles meet the
      floors by construction; nothing an existing template reads changes.
- [ ] Floor check on every palette, after defaults: each `on_X` on `X` 4.5:1 (X = primary,
      secondary, tertiary, error, their containers, surface), `outline` on `surface` 3:1. The
      error names the pair and the ratio, as the keycap legend check does.

Checks:
1. Before/after: `theme init <p> --to <dir>` for all ten palettes on `main` and on the branch;
   `diff -r` is empty (byte-identical output for every existing template).
2. Scratchpad reproduction: a copy of an input palette with one `[material]` role removed, one
   with an unknown role, one with `on_primary` below 4.5:1: each fails with a message naming it.
3. `theme lint`, `tests/run` (theme-test renders every palette, no token left).

## M2. The two palettes (theme/palettes/space.toml, space-light.toml)

Computed once in the scratchpad, committed as plain TOML; the script is not committed (spec
non-goal). Tool: `materialyoucolor` 3.0.4, colour spec 2021, `Variant.FIDELITY`, contrast 0.

- [ ] Palettes: primary, secondary and tertiary from the three recovered key colors; neutral and
      neutral variant at the navy's hue 283, chroma 6 (both variants: finding 9); error from
      Gruber red.
- [ ] Named-source rule (red, green): dark `error`/`success` = the source when it reads 4.5:1 on
      `surface`, light = its tone 40; dark `on_error` = red tone 10, raised to the pole if below
      4.5:1.
- [ ] `[colors]`, `[terminal]`, `[syntax] keyword` by the spec's tables. Magenta and cyan: HCT
      hues of the sRGB magenta and cyan primaries at primary's chroma. Bright row 10 tones toward
      the text. `fg_bright`: neutral tone 98 dark, tone 4 light. No `[keycaps]`.
- [ ] Header: sources and licenses (as the inputs), variant, tool and version, the key colors
      with their source swatch, and every floor measured by `theme`'s `contrast()`.

Checks:
1. The 12 fixed roles equal the inputs' (identical by construction; proves the key colors).
2. The audit script reruns on the new files: each of the spec's 12 findings resolved, with the
   number that shows it; every floor in the spec met.
3. `theme init space --to <dir>` and `space-light`; `tests/run`; `theme lint`.

## M3. Docs

- [ ] `docs/theming.md`: Space in the palette list; a `[material]` section (roles, `m3_` prefix,
      defaults, floors).
- [ ] `docs/onboarding.md`: both slugs in the palette list.
- [ ] `docs/apps/theme.md` hand-written part if it names palettes; `tools/docs`; `tools/docs --check`.

## M4. Desktop check (needs your machine)

`desktop-vm` is not available in this cloud container (Ubuntu, no qemu guest image), so this
milestone runs where `desktop-vm` lives:

```bash
desktop-vm up && desktop-vm check
```

then `theme set space`, then `theme set space-light`, each with `desktop-vm shot` of the session,
a terminal showing all 16 ANSI colors, and the keybinding cheatsheet; `desktop-vm down`. The
frames are looked at for the spec's findings, not only the PASS verdict.

## Risks

- Light `secondary` at tone 40 is an olive, not a bright yellow: it is the cursor, keyword and
  warning in light. That is M3's tone rule working as specified; the frames in M4 decide whether
  it reads as "yellow" enough.
- `materialyoucolor` follows MCU; a later version may move tones. The header pins the version,
  and the committed TOML, not the tool, is the source of truth.
- The derived `[material]` for the ten old palettes is used by nothing until `bar`; its
  formulas get their first real test there and may change then.

## After theme

Each module needs its spec before its plan: brainstorm, spec approval, then planning.

1. `gtk` (depends on theme only): can be specced right after M2, beside `bar`. Today's GTK
   templates read legacy roles; the spec decides whether they move to `m3_` roles.
2. `bar`: the largest open design. The spec has to settle the mass model (what a unit of mass
   is, what a morph spends, how a destroyed shape returns it), what renders it (likely a new
   layer-shell program: a new package or `pkg/` PKGBUILD needs your approval), and how "never in
   two places at full size" holds across outputs.
3. `greeter` and `session`: after `bar`, since both are the bar in another shape.

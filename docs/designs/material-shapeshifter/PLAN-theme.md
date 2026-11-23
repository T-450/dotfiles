# PLAN-theme: build the Space Material 3 design system

Plan for [SPEC-theme](SPEC-theme.md) revision 3. Status: revised after the adversarial plan
review, awaiting approval. Date: 2026-11-23. Prompt: the [capability map](README.md). The map
builds `theme` first and only `theme` has an approved spec, so this plan builds `theme`; the rest
of the map is in "After theme" at the end.

## Working rules

- Branch `theme-space` off `main`. One commit per milestone, and each commit carries its own
  docs (AGENTS.md: docs move with the code). Merge to `main` only after M4 passes, then delete
  the branch. Push only when asked.
- A failed check stops the milestone: find whether the change, the check or the environment is
  wrong, fix one thing, re-check.
- Session-local inputs move to `~/.cache/space-theme/` before M1, so any session can run the
  checks: the two uploaded palettes (`space.input.toml`, `space-light.input.toml`), `gen.py`
  (the palette generator), `audit.py` (the contrast audit), and the Compose sources jar with its
  sha256. Deleted when the module is merged.
- Scratch reproductions run against a `cp -r` copy of the repo (as theme-test does) or by
  importing the `theme` module and calling `load_palette(slug, path)` / `render_template`;
  `theme init` alone cannot load a palette or template from outside the repo. Python runs with
  `-B` so no `__pycache__` lands in `theme/.local/bin/` (it would show up in `tools/docs`).
- No `#rrggbb` in any doc: `theme lint` scans `docs/` too.

## M1. `theme` reads and derives `[material]` (theme/.local/bin/theme, docs/theming.md)

- [ ] `MATERIAL`: the 45 role names, in the inputs' order.
- [ ] `load_palette`: an optional `[material]` table is all 45 names or absent; unknown names and
      non-`#rrggbb` values fail, as `[keycaps]` does. Roles land in `v` as `m3_<role>`.
- [ ] `material_defaults(v)` when the table is absent, exactly as spec change 2 lists:

      | M3 roles | from |
      |---|---|
      | `primary`, `secondary`, `tertiary`, `error` | `accent`, `warning`, `badge`, `error` |
      | `on_X` | `ink(X)` |
      | `X_container` / `on_X_container` | `X` mixed 60% toward `bg_desktop` / its `ink` |
      | `X_fixed_dim`, `X_fixed`, `on_X_fixed`, `on_X_fixed_variant` | `X`; `X` 50% toward white; 80% and 50% toward black |
      | `surface`, `surface_dim` | `bg_desktop` |
      | `surface_container_lowest` | `bg_desktop` 50% toward black on a dark palette, white on a light one (the pole `pole()` does not return) |
      | `surface_container_low` | `bg_desktop` halfway to `bg_surface` |
      | `surface_container`, `_high`, `_highest`, `surface_bright` | `bg_surface`, `bg_widget`, `bg_hover`, `bg_hover` |
      | `on_surface`, `on_surface_variant` | `fg_text`, `fg_secondary`, each made `legible` at 4.5:1 on `bg_desktop` |
      | `outline`, `outline_variant` | `border_inactive` made `legible` at 3:1 on `bg_desktop`; `border_hairline` |
      | `inverse_surface`, `inverse_on_surface`, `inverse_primary` | `fg_text`; `ink(fg_text)`; `accent` made legible on `fg_text` |
      | `shadow`, `scrim` | `shadow` |

- [ ] Floor check after defaults, on the exact pair list in spec change 3; the error names the
      pair and its ratio, as the keycap legend check does.
- [ ] Docs in the same commit: `docs/theming.md` gains a `[material]` section (roles, the `m3_`
      prefix, the defaults, the floor pairs and the ones left unchecked); the `theme` docstring
      mentions `[material]`.

Checks:
1. Before/after: `theme init <p> --to <dir>` for all ten palettes on `main` and on the branch;
   `diff -r` is empty (every existing template renders byte-identical).
2. All ten palettes load with derived roles and pass the floors (that is what keeps `theme set`
   and imports working, since one failing palette fails every render).
3. Repo-copy reproduction with `~/.cache/space-theme/space.input.toml`: one `[material]` role
   removed, one unknown role, `on_primary` lowered below 4.5:1; each fails naming the problem.
4. `theme lint`, `tools/docs --check`, `tests/run`.

## M2. System tokens (theme/tokens.toml, theme/.local/bin/theme, docs)

- [ ] `theme/tokens.toml`: groups `shape`, `elevation`, `motion`, `state`, `type`,
      `type_emphasized`, `type_font`; keys are the spec's word list without the group prefix,
      underscores throughout. Header: Compose `material3` 1.5.0, the jar's `dl.google.com` URL
      and sha256, each token file's VERSION line, the Apache-2.0 license, and the hand-mapped
      values (below).
- [ ] Values printed by a scratchpad script from the jar's `tokens/*.kt`, formatted with `{x:g}`
      (`16`, not `16.0`; easings as `0.05, 0.7, 0.1, 1`), skipping the spec's excluded tokens.
      Mapped by hand and stated in the header: `CircleShape` → `full = 9999`; `FontFamily.SansSerif`
      → `IBM Plex Sans` (the spec's typeface decision); font weights Normal, Medium, Bold → 400,
      500, 700.
- [x] `theme`: a `SYSTEM_TOKENS` allowlist (`TOKENS` is taken by `theme lint`'s secret pattern) generated from the spec's word list; load `tokens.toml` once
      per render; unknown group or key fails; value types number, four-number list, string; each
      token added to `words`; `mix`'s amount takes a `state_*` word.
- [ ] Docs in the same commit: the tokens section of `docs/theming.md` (word list, units, source,
      the Expressive scheme); `docs/README.md` lists `tokens.toml` in the `theme/` line.

Checks:
1. `sha256sum` of the jar in `~/.cache/space-theme/` matches the header (pins the source; a rerun
   of the same script on the same jar could not fail, so it is not a check).
2. Repo-copy reproduction: a template using every word renders the spec's values;
   `mix:m3_on_surface:state_hover` mixes at 0.08; an unknown word and `mix:…:shape_corner_large`
   each fail naming it.
3. M1 check 1 again: still byte-identical.
4. `theme lint`, `tools/docs --check`, `tests/run`.

## M3. The two palettes (theme/palettes/space.toml, space-light.toml, docs)

Computed once with `~/.cache/space-theme/gen.py` (`materialyoucolor` 3.0.4, colour spec 2021,
`Variant.FIDELITY`, contrast 0), committed as plain TOML; the script is not committed (spec
non-goal).

- [ ] Palettes as spec Scheme: primary, secondary, tertiary from the recovered key colors;
      neutral at hue 283 chroma 6, neutral variant chroma 8, both variants; error from Gruber red.
- [ ] Named-source rule (red, green): dark uses the source when it reads 4.5:1 on `surface`,
      light its tone 40; dark `on_error` = red tone 10, raised to the pole if below 4.5:1.
- [ ] `[colors]`, `[terminal]` (fg, bg, cursor, 16 ANSI with magenta and cyan at tone 80 dark,
      40 light), `[syntax]` keyword, constant, number: all by the spec's tables. `fg_bright`:
      neutral tone 98 dark, tone 4 light. No `[keycaps]`.
- [ ] Header: sources and licenses, variant, tool and version, the key colors and their swatch,
      and every floor measured by `theme`'s `contrast()`.
- [ ] Docs in the same commit: Space in `docs/theming.md`'s palette list; both slugs and the new
      render count in `docs/onboarding.md` (it says 31; it is 38 today and 40 after); the
      hand-written part of `docs/apps/theme.md` where it names palettes.

Checks:
1. `audit.py` on the committed files asserts, for each legacy role and terminal slot, that it
   equals the M3 role the spec's mapping names, then reports each of the spec's 12 findings with
   the number that shows it resolved (finding 8 as amended: 1.62:1) and every floor.
2. Acceptance 3 on the committed `space.toml` (repo copy): a role removed, `on_primary` lowered;
   both fail.
3. `theme init space --to <dir>` and `space-light`; Vim and Helix syntax shows keyword, constant
   and number in three colors (rendered values differ); `theme lint`, `tools/docs --check`,
   `tests/run`.
4. Commit message carries the floor numbers (acceptance 4), as the header does.

## M4. Desktop check, merge (needs your machine)

`desktop-vm` is not available in this cloud container. On your machine, never in the live
session:

1. `desktop-vm up` (installs the branch's working tree, reboots, records the boot).
2. In the guest's session: `desktop-vm exec --user 'theme set space'` (it runs with the session
   environment, so the reload hooks fire), then `desktop-vm check`; look at `session.png`, then
   `desktop-vm shot` of a terminal printing all 16 ANSI colors and of the keybinding cheatsheet.
3. The same for `space-light`.
4. `desktop-vm down`.
5. Both PASS and the frames looked at: merge `theme-space` to `main`, delete the branch. Then, on
   the live machine, `./install.sh --link` (stow links the two new Pi theme files) and
   `./install.sh --check` reports no drift.

## Risks

- The secondary yellow is muted in both variants: dark tone 80, light tone 40 (an olive). It is
  the cursor, keyword and warning. That is M3's tone rule as computed; M4's frames decide whether
  it reads as yellow enough. The alternative is a source-yellow override, which is a spec change.
- `materialyoucolor` and Compose move with their releases; the headers pin versions (and the jar's
  sha256), and the committed TOML is the source of truth.
- The derived `[material]` of the ten old palettes has no consumer until `bar`. It is kept because
  the spec requires `bar` to work under every palette; its formulas get their first real test
  there and may change then.

## After theme

Each module needs its spec before its plan: brainstorm, spec approval, then planning.

1. `gtk` (depends on theme only): can be specced right after M3, beside `bar`. Today's GTK
   templates read legacy roles; the spec decides whether they move to `m3_` roles.
2. `bar`: the largest open design. The design canvas holds the current direction: an alien
   machine of plates around a reserve core (launcher and spectrum morphs), with five mechanisms
   (prism, conveyor, iris, phase, orrery). Its spec settles the mass model, what renders it (a
   new layer-shell program: a new package or `pkg/` PKGBUILD needs your approval), cut corners
   (not an M3 shape token: a shell-specific choice to record), and how "never in two places at
   full size" holds across outputs.
3. `greeter` and `session`: after `bar`, since both are the bar in another shape.

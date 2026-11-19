# Accent Restraint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Common desktop UI reads in the palette's cool `ansi6`; the accent marks only focus and the active item.

**Architecture:** Template-only: four app templates/stylesheets change which role they read. No palette, `theme` or install change. Proof is rendered previews per palette, not test files (AGENTS.md: no tests).

**Tech Stack:** `theme` templates (`{{role|filter}}`), GTK CSS (waybar), rasi (rofi), mako ini.

**Spec:** `docs/superpowers/specs/2026-11-19-accent-restraint-design.md`

## Global Constraints

- Palette files unchanged; no color literals outside `theme/palettes/` (`theme lint`).
- "Muted" cool = `ansi6|mix:<ground>:0.5`, where `<ground>` is the element's own background role.
- Kept on the accent: mango focus/drop, waybar active workspace and focused title, hyprlock ring
  and check, rofi selected row border, wlogout selected button, ghostty search match, GTK accent.
- State colors stay: `@orange` keymode, `@warn`, `@crit`, mako critical, mango urgent/global.
- Previews before merge or live apply; never `theme set` in the live session.

## Review Focus

- Light palettes (Metro, Rain, Alabaster): a 50% mix toward white may vanish as a border; check
  Metro's notification and launcher borders read at least as clearly as `border_inactive`.
- Palettes whose accent equals `ansi6` (Space, Cassette): focus must still stand out from muted
  cyan; check Space's active workspace against the bar.
- Gruber Darker: its `ansi6` is grey (saturation under 0.12); common UI goes neutral there, which is
  acceptable, but the OSD fill must stay legible.
- Low-urgency notifications keep `border_inactive`; only the normal tier changes.
- Comments in each changed file still describe what the colors mean (they name the accent today).

---

### Task 1: Templates read the cool role

**Files:**
- Modify: `mako/.config/mako/colors.tmpl:4-10`
- Modify: `rofi/.config/rofi/themes/colors.rasi.tmpl:4`, `rofi/.config/rofi/themes/quickinput.rasi:9`
- Modify: `swayosd/.config/swayosd/colors.css.tmpl:7`
- Modify: `waybar/.config/waybar/style.css:76-78,106,161,182`

- [ ] **Step 1: Render the before set**

Run: `for p in alchemist space metro; do theme init $p --to $SCRATCH/before/$p; done`
Expected: `rendered N files for <p>` three times.

- [ ] **Step 2: Edit**

- mako: normal `border-color={{ansi6|mix:bg_widget:0.5}}`; normal title
  `foreground="{{fg_bright|legible:bg_widget}}"`; header comment rewritten to match.
- rofi: add `cool: {{ansi6|mix:bg_surface:0.5}};` to the `*` block; inputbar `border-color: @cool`.
- swayosd: `osd_fill {{ansi6|legible:bg_widget}}`.
- waybar style.css: `#custom-start` color `@text`, hover `color: @cyan` with no `text-shadow`;
  drop `box-shadow` from the active workspace rule; `#custom-winstate` uses `@cyan`; drop the
  clock's `text-shadow`. Update the comments on those rules and the `@orange`/`@magenta`
  definitions in `colors.css.tmpl` so they list only what still uses them.

- [ ] **Step 3: Render the after set and compare**

Run: `for p in alchemist space metro; do theme init $p --to $SCRATCH/after/$p; done`, then
`diff -r $SCRATCH/before/$p $SCRATCH/after/$p` per palette.
Expected: differences only in mako `colors`, rofi `colors.rasi`, swayosd `colors.css` and
waybar `colors.css` (comments only).

- [ ] **Step 4: Checks**

Run: `theme lint && tools/docs --check && tests/run`
Expected: both `ok` lines, `docs/ matches the repo`, no failed tests (a live `theme set` during the
run trips "leaves the checkout unchanged"; rerun if so).

- [ ] **Step 5: Commit**

`git commit -m "desktop: accent marks focus only; common UI in the cool ansi6"` with the four
apps' files and the plan.

### Task 2: Previews and approval

**Files:** none in the repo (scratchpad only).

- [ ] **Step 1: Build before/after previews**

For Alchemist, Space and Metro: the bar (waybar's rendered CSS on its markup, headless), a
normal notification, the launcher and the OSD, before above after. Render with headless Chrome or
the existing HTML preview path in the scratchpad.

- [ ] **Step 2: Send previews; wait for approval**

Expected: user approves, or names changes (loop back to Task 1 Step 2).

- [ ] **Step 3: Merge**

After approval: merge `accent-restraint` to `main`, delete the branch, `theme set "$(theme current)"`
only if the user asks for it live.

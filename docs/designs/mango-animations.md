# Mango animations: 150 ms, no overshoot, shadows on floating windows

*   **Author:** Test
*   **Date:** 2026-11-12

## Overview

mango, the Wayland compositor this repo configures (mangowm 0.18.5, see [mango](../apps/mango.md)),
animates every window and overlay change. The animations took 350-800 ms and opening windows grew
past their final size before settling, so the desktop felt slow. This design makes every
animation 150 ms long on one curve with no overshoot, changes how far fades and zooms travel, turns
blur fully off, and turns shadows on for floating windows. It also cleans up config lines that
never had any effect, and fixes layer rules that silently cancelled each other.

The change is in `mango/` (config and rules) and its docs. Two related changes ship as separate
commits: powertop is declared as a diagnostic tool in `thinkpad/` (it was installed by hand to
measure this change, and `tools/docs --drift` fails until it is declared), and the power menu
(`wlogout/`) gets an opaque background.

## Key terms

*   **Layer surface (overlay):** a surface drawn above or below windows, not managed as a window:
    the launcher and keybinding cheatsheet (rofi), notifications (mako), the volume and brightness
    popup (swayosd, the OSD), the power menu (wlogout), the bar (waybar), and the wallpaper.
*   **Floating window:** a window outside the tiling layout. In this repo: file and polkit
    dialogs, Thunar, Mousepad, xarchiver, blueman, waypaper, the floating terminal, and the
    dropdown terminal (`mango/.config/mango/rule.conf`).
*   **`mmsg`:** mango's command-line client. `mmsg dispatch setoption,KEY,VALUE` sets a config key
    in the running session until the next config reload.
*   **Config reload:** mango re-reads its config when the file is saved, on Super+R, and after
    `theme set`. A reload drops every `setoption` override.
*   **Themes:** `dark-2026` and `light-2026` are palettes in `theme/palettes/`; `theme set NAME`
    switches. A palette role such as `shadow` is a named color the templates use.
*   **`tools/docs`:** the docs generator. It rewrites the generated reference blocks in `docs/`;
    `--check` fails when a block is stale, `--drift` compares installed packages with every
    `packages` file, `--snapshot` rewrites `docs/reference/installed.md`.
*   **CUJ:** a critical user journey, written as Given, When, Then.

## The Problem

**Slow transitions.** The durations were 400 ms to open, 800 ms to close, 500 ms to move, 350 ms
to switch tags and 400 ms to move focus. The open curve (`0.46,1.0,0.29,1.1`) overshoots by about
3 percent. The keybinding cheatsheet (Super+/, rofi started by the Python script `mango-keys`)
appeared about 135 ms after the keypress, then zoomed for 400 ms with overshoot, and took 800 ms
to close.

**Effects settings that did nothing.** The config set `blur=0` and `shadows=0` but `blur_layer=1`
and `layer_shadows=1`, plus 12 tuning lines. In mango 0.18.5 the global keys are master switches:
a layer shadow is drawn only when `shadows` and `layer_shadows` are both 1
(`src/animation/layer.c:255`), and layer blur only when `blur` and `blur_layer` are both 1
(`src/manage/layer.c:344`). So no blur and no shadow was ever drawn, and the layer switches and
tuning lines only suggested otherwise. Popups and floating windows had nothing setting them apart
from the windows under them except a 1 px border, which on the light theme is a pale line between
two near-white surfaces.

**Energy.** While an animation runs, mango redraws every frame and the GPU stays awake. Shorter
animations draw fewer frames. The measured effect is in [Evidence](#evidence); it is a real but
small battery gain. The main gain is responsiveness.

## Goals

*   **Fast.** All five animation durations (open, close, move, tag, focus) are 150 ms, 9 frames at
    60 Hz. Layer surfaces use the same durations.
*   **No overshoot.** All seven curve keys use `0.5,1,0.89,1`, a quadratic ease-out: about 21
    percent of the travel in the first frame, then steps that shrink evenly. No y control value is
    outside 0 to 1, so nothing grows past its final size.
*   **Shorter fades and zooms.** Fades start at 0.5 opacity when opening and 0.6 when closing;
    zooms grow from 0.1 of full size and shrink to 0.6. These values were chosen by eye on the
    laptop panel.
*   **Effects that match the config.** Blur is fully off, so every overlay is opaque. Shadows are on
    for floating windows, on both themes. Layer shadows stay enabled, but no overlay shows one (see
    Effects below), and none draws a stray shadow over the bar. The four switches are written out with a comment that the global keys gate the layer
    keys, and the lines that tune blur are deleted.
*   **One behavior** on AC power and on battery, and on both themes.
*   **Repo checks pass:** `mango -p`, `theme lint`, `tools/docs --check`, `tools/docs --drift`,
    `./install.sh --check`, `tests/run`.

## Non-Goals

*   **Launch time of Super+/** (about 135 ms: the Python script about 45 ms, rofi about 90 ms).
*   **The lock screen.** mango's effects never reach it; a blurred lock screen would need the
    swaylock-effects fork.
*   **Settings by power state or by theme.**
*   **Turning animations off.**
*   **An external monitor.** Tuned and checked on the laptop panel (eDP-1) only.
*   **A benchmark in the repo, or a pass/fail gate.** The measurement was a one-off record.

## Critical User Journeys (CUJs)

### CUJ 1: Open and close the keybinding cheatsheet

*   **Given**: The new config is loaded.
*   **When**: The user presses Super+/, then Escape.
*   **Then**: The config sets the open and close durations to 150 ms on a curve with no y value
    outside 0 to 1, so the cheatsheet's zoom finishes in 150 ms and never grows past its size.
    This is checked by reading the config, not by measuring frames.

### CUJ 2: Switch tags, move focus, close a window

*   **Given**: Two tags with tiled windows.
*   **When**: The user switches tag, moves focus, then closes a window.
*   **Then**: The tag slide, the border color change on focus, the close, and the neighbor's move
    each finish in 150 ms, without overshoot.

### CUJ 3: Floating windows stand out on both themes, and overlays draw no stray shadow

*   **Given**: A white window (for example a blank browser page) fills the tile, on `dark-2026` and
    then on `light-2026`.
*   **When**: The user opens the floating terminal (Alt+Shift+T), then Super+/, then the volume
    popup.
*   **Then**: The floating terminal has a shadow that sets it apart from the window below. Super+/
    and the volume popup show no shadow, and no dark band appears along the top of the bar while
    Super+/ is open. Tiled windows, notifications and the bar have none.

## Technical Plan (Architecture)

### How mango 0.18.5 animates and draws effects

*   **Windows** have five animations, each with its own duration and curve key: open, close, move
    (a window moving or resizing in the layout), tag (the slide on a tag switch) and focus (a
    cross-fade of the border color, and of opacity and dim color when those differ; here both
    opacities are 1.0 and dim is off, so only the border color changes).
*   **Layer surfaces** open with the open duration and curve, close with the close ones
    (`src/manage/layer.c`, `src/animation/layer.c`), and resize with the move duration
    (`src/manage/layer.c:334`). Their type (slide, fade, zoom) comes from `layer_animation_type_*`
    and per-layer `layer_rule` lines: rofi zooms, notifications, the OSD and the power menu fade.
*   **Fades** run during open and close: opacity goes from `fade_in_begin_opacity` (or to
    `fade_out_begin_opacity`) over the open (or close) duration, shaped by
    `animation_curve_opacity_fade_in` (or `_out`). **Zooms** scale from `zoom_initial_ratio` and to
    `zoom_end_ratio`. These four ratios are global: they apply to windows and layers, including the
    zoom on file dialogs. mango clamps both zoom ratios to 0.1-1.0 (`override_config` in
    `src/config/option_defs.c`).
*   **Effects:** `blur` and `shadows` are master switches over `blur_layer` and `layer_shadows`
    (see The Problem). Window shadows follow `shadows`; `shadow_only_floating=1` limits them to
    floating windows. A layer gets a shadow only if it is above windows and reserves no screen
    space (`src/manage/layer.c:245-247`), so the bar (which reserves space) never gets one. A layer
    shadow outlines the layer's whole surface, not what it draws: rofi's surface spans the screen
    above the bar (it anchors to all four edges), so with `layer_shadows=1` its shadow is a dark
    band along the top of the bar (measured: rows just above the bar drop from luminance 250 to
    30-77 while Super+/ is open). The OSD showed no shadow when checked. Shadow size, blur and offset
    come from `shadows_size`, `shadows_blur`, `shadows_position_x/y`; the color comes from the
    `shadow` palette role, black in every palette.
*   **Layer rules cancel each other.** A `layer_rule` that does not mention `no_shadow`, `no_blur`
    or `no_animation` still sets them, to 0 (`src/config/option_defs.c:1364`), and every matching
    rule is applied in order (`src/manage/layer.c:224-235`). So a layer's later animation rule
    turned its earlier `no_shadow` back off; the notifications rule never took effect. Window rules
    default to -1 and do not have this problem (`option_defs.c:1441`). The fix is one rule line
    per layer.
*   **Live tuning:** `setoption` applies a key through the same parser as the config file and
    rebuilds the curve tables (`src/dispatch/bind.c:2305`, `src/config/reapply.c:156`), so the
    values chosen live are the values the config file produces.

### What changes

1.  **`mango/.config/mango/config.conf`, effects:** `blur_layer` 1 to 0, `shadows` 0 to 1;
    `blur=0`, `layer_shadows=1`, `shadow_only_floating=1` and the four shadow size, blur and offset
    lines stay; `blur_optimized` and the six `blur_params_*` lines are deleted; a comment states
    that the global switches gate the layer ones.
2.  **`config.conf`, animations:** the duration and the curve are defined once as mango config
    variables (`var=anim_ms,150`, `var=ease_out_quad,0.5,1,0.89,1`) and every duration and curve
    key references them, so "one duration, one curve" is part of the config's structure; the four
    ratios to 0.5, 0.6, 0.1 and 0.6; animation types unchanged; a comment warns that mango silently
    raises `zoom_initial_ratio` below 0.1.
3.  **`mango/.config/mango/rule.conf`:** delete the two window rules for app_id `Rofi` (rofi is a
    layer surface, so they never match); drop `no_blur:1` from the screenshot selection and idle
    dim layer rules and keep their `no_animation:1`; delete the bar's `no_shadow` rule (the bar
    never gets a shadow); merge each layer's rules into one line, so `no_shadow:1` on
    notifications and on rofi takes effect, with a comment on why.
4.  **Docs:** one paragraph in `docs/apps/mango.md`; this design in `docs/designs/`, linked from
    `docs/README.md`. `colors.conf.tmpl` and `docs/theming.md` do not change: `shadows_color`
    stays and mango keeps using the `shadow` role.
5.  **Separate commits:** powertop in `thinkpad/packages` with a line in `docs/apps/thinkpad.md`;
    wlogout's background from `alpha(@desktop, 0.92)` (8 percent of the windows behind show
    through today) to the opaque `@desktop` palette color.

## Evidence

A one-off benchmark measured the cost of the animations before this change. It is not in the repo.

*   **Method.** On battery, swayidle stopped, after a 60 s settle. One fixed workload on an empty
    tag next to one tiled window, repeated 3 times per 36 s run: open a terminal window, move
    focus, switch tag away and back, open and close the Super+/ cheatsheet, show and hide the
    dropdown terminal (27 actions per run). Variants applied with `setoption`, 4 runs each,
    interleaved in rotating order. Per run: mango's own CPU time (`/proc/PID/stat`), GPU busy time
    (the run's length minus the i915 GPU's idle residency), and Intel RAPL energy for the CPU
    package and the whole platform.
*   **Screening.** Platform energy sees every process. A run's energy figures were dropped when its
    whole-system CPU use (powertop) was more than 5 points above the quietest run of the same
    variant; 5 of 20 runs were dropped, all loaded by another program running at the time. mango
    CPU and GPU busy are not screened; other programs barely move them, though GPU busy counts
    every program that uses the GPU.
*   **Results** (median of 4 runs, range in brackets):

    | Variant | mango CPU | GPU busy | Platform power (screened) |
    |---|---|---|---|
    | old config | 2.51% [2.33-2.58] | 11.4% [11.2-11.6] | 2.53 W |
    | durations 150 ms only | 1.24% [1.19-1.30] | 6.5% [6.4-6.6] | 2.17 W |
    | animations off | 0.75% [0.72-0.80] | 3.1% [2.7-3.1] | 1.83 W |
    | no workload | 0% | 0.1% | 1.12 W |

*   **Reading.** 150 ms durations alone halve mango's CPU and GPU time on this workload. Animation
    power above "animations off" falls from about 0.70 W to 0.34 W (an estimate from RAPL, not a
    battery reading). The workload runs about 45 actions a minute; at 10 a minute the saving is
    about 0.08 W, about 1.8 percent of the 4.3-4.5 W the battery reported during the clean runs.
*   **Not measured.** The new curve, the ratios and the shadows. A variant that turned off
    `blur_layer` and `layer_shadows` matched the old config exactly, because neither was drawn.
    Durations below 150 ms were not tried; 150 ms was chosen by eye.

## Alternatives Considered

### Alternative A: Turn all animations off

*   **Pros**: Fastest and cheapest (mango CPU 0.75 percent, GPU busy 3.1 percent above).
*   **Cons**: Windows and overlays jump into place.
*   **Reason for Rejection**: Rejected by author: the author values the smoothness animations give.

### Alternative B: Turn shadows off too (all four switches 0)

*   **Pros**: Matches what was on screen before; deletes all shadow lines and `shadows_color`; no
    unmeasured cost.
*   **Cons**: Popups and floating windows keep only a 1 px border against the windows below.
*   **Reason for Rejection**: Rejected by author: shadows set floating windows apart, and that
    matters most on the light theme.

### Alternative B2: Layer shadows off (`layer_shadows=0`)

*   **Pros**: No overlay can draw a shadow, so the rofi band cannot appear; no per-layer rule needed.
*   **Cons**: None visible today, since no overlay shows a shadow either way.
*   **Reason for Rejection**: Rejected by author: layer shadows stay enabled, with rofi opted out.

### Alternative C: A different duration per kind (tag 200 ms, focus 0 ms)

*   **Pros**: A longer tag slide over the full screen; no focus animation (mango's default).
*   **Cons**: More numbers; tag at 200 ms draws 12 frames instead of 9.
*   **Reason for Rejection**: Rejected by author after comparing both on the panel.

### Alternative D: The other candidate curves

*   **Pros**: `0.46,1.0,0.29,1` was already used for move, tag and focus; `0.33,1,0.68,1` puts
    about 30 percent of the travel in frame 1.
*   **Cons**: Less even steps across 9 frames.
*   **Reason for Rejection**: Rejected by author after comparing all three on the panel.

### Alternative E: A pass/fail benchmark gate

*   **Pros**: Would flag a mango upgrade that makes animations costlier.
*   **Cons**: With limits taken from the maximum of 4 runs, the median of 4 new runs exceeds them
    about 7-21 percent of the time with no change; it needs a margin, a repeat rule and a failure
    procedure, and the benchmark needs sudo and stops the idle lock for about 20 minutes.
*   **Reason for Rejection**: Rejected by author: the measurement stays a one-off record.

### Smaller alternatives

*   **Settings by power state:** rejected by author; a hook from TLP into mango for well under 0.1 W.
*   **Blur only behind the power menu:** rejected by author; mango can only turn blur off per
    layer, so every other layer would need an opt-out rule, and an opaque background reads better.
*   **Stronger popup borders in the app templates instead of shadows:** rejected by author; it
    changes the rofi and swayosd folders and does nothing for floating windows.
*   **A smaller zoom (`zoom_initial_ratio` 0.85):** rejected by author after comparing on the panel.
*   **A blurred lock screen:** out of scope (see Non-Goals).
*   **Removing powertop:** rejected by author; it names the programs behind outside load, which
    mango CPU and GPU busy cannot.
*   **Measuring the cheatsheet with a screen recording:** rejected by author; CUJ 1 is checked from
    the config.

## Risks

*   **Shadow cost is unmeasured.** Shadows are drawn for floating windows, including during their
    animations. To measure it, run the benchmark's `new` and `new-noshadow` variants.
*   **Visible change.** Every floating window gets a shadow on both themes. The power menu, the
    screenshot selection and the idle dim layer cover the bar's area too, so a shadow they cast
    falls outside the screen (checked on the panel: no band above the bar); with a second monitor
    beside the panel it could show on that monitor's edge. A new overlay that spans the screen
    above the bar would draw rofi's band until it gets its own `no_shadow` rule.
*   **mango upgrades.** mangowm is not pinned. All switches stay written out, so a change in
    mango's defaults cannot silently turn an effect on or off.
*   **Reload while testing.** Saving `config.conf` reloads mango and drops `setoption` overrides.

## Detailed Implementation Plan

Three commits on one branch, merged to `main` and pushed. Stage files by path: the working tree may
hold unrelated changes. Commit messages carry no co-author trailer and no session link.

### Step 0: Branch

```sh
git checkout main && git pull --ff-only origin main
git checkout -b mango-snappy-animations
```

### Commit 1: powertop

1.  **`thinkpad/packages` (Modify):** append after `tlp`:
    `powertop   # diagnostic only; never --auto-tune: TLP owns the tunables`
2.  **`docs/apps/thinkpad.md` (Modify):** a new paragraph after the "TLP alone manages power"
    paragraph: "powertop is installed as a diagnostic only (per-process CPU use and wakeups); its
    `--auto-tune` and `powertop.service` are never used, because TLP alone manages power."
3.  **Generated docs:** run `tools/docs`, then `tools/docs --snapshot`. The first rewrites the
    thinkpad reference block and its row in the `docs/README.md` app table; the second rewrites
    `docs/reference/installed.md` with every declared package's current version, so other
    versions may change in the same diff.
4.  **Check:** `tools/docs --check`, `tools/docs --drift`, `./install.sh --check`.
5.  **Commit:**
    ```sh
    git add thinkpad/packages docs/apps/thinkpad.md docs/README.md docs/reference/installed.md
    git commit -m "thinkpad: powertop, a diagnostic beside TLP"
    ```

### Commit 2: mango

6.  **`mango/.config/mango/config.conf` (Modify), effects block.** Replace the block from
    `# Effect` through `shadows_position_y = 0` with:

    ```text
    # Effect
    # mango 0.18.5 gates layer blur on blur=1 and layer shadows on shadows=1:
    # blur_layer and layer_shadows do nothing alone
    blur=0
    blur_layer=0

    shadows=1
    layer_shadows = 1
    shadow_only_floating=1
    shadows_size = 12
    shadows_blur = 15
    shadows_position_x = 0
    shadows_position_y = 0
    ```

7.  **`config.conf`, animation block.** Replace the block from `# Animation Configuration`
    through `animation_curve_opacity_fade_in=...` with:

    ```text
    # Animation Configuration
    var=anim_ms,150
    var=ease_out_quad,0.5,1,0.89,1
    animations=1
    layer_animations=1
    animation_type_open=slide
    animation_type_close=slide
    layer_animation_type_open=slide
    layer_animation_type_close=slide
    animation_fade_in=1
    animation_fade_out=1
    tag_animation_direction=1
    # mango 0.18.5 silently raises zoom_initial_ratio below 0.1 to 0.1
    zoom_initial_ratio=0.1
    zoom_end_ratio=0.6
    fade_in_begin_opacity=0.5
    fade_out_begin_opacity=0.6
    animation_duration_move=$anim_ms
    animation_duration_open=$anim_ms
    animation_duration_tag=$anim_ms
    animation_duration_close=$anim_ms
    animation_duration_focus=$anim_ms
    animation_curve_open=$ease_out_quad
    animation_curve_move=$ease_out_quad
    animation_curve_tag=$ease_out_quad
    animation_curve_close=$ease_out_quad
    animation_curve_focus=$ease_out_quad
    animation_curve_opacity_fade_out=$ease_out_quad
    animation_curve_opacity_fade_in=$ease_out_quad
    ```

    This also removes the trailing spaces after the two `*_close=slide` lines. A `var=` must be
    defined before its first use; mango 0.18.5 expands it in `config.conf`, and `mango -p` fails on
    an undefined `$name`.
8.  **`mango/.config/mango/rule.conf` (Modify):**
    *   Delete the `# launcher` comment, the two `window_rule=...app_id:Rofi` lines and the blank
        line after them.
    *   `layer_rule=no_blur:1,no_animation:1,layer_name:selection` becomes
        `layer_rule=no_animation:1,layer_name:selection`; the same for `dimland_layer`.
    *   Replace the remaining layer rules with one line per layer:

        ```text
        # one rule per layer: in mango 0.18.5 every matching layer_rule also sets no_shadow, no_blur and
        # no_animation (to 0 when unset), so a later rule for the same layer turns them back off
        layer_rule=no_animation:1,layer_name:selection
        layer_rule=no_animation:1,layer_name:dimland_layer
        layer_rule=no_shadow:1,animation_type_open:fade,animation_type_close:fade,layer_name:notifications
        # rofi's layer spans the screen above the bar and mango shadows a layer's whole surface,
        # not what it draws, so the shadow would be a dark band over the bar
        layer_rule=no_shadow:1,animation_type_open:zoom,animation_type_close:zoom,layer_name:rofi
        layer_rule=animation_type_open:fade,animation_type_close:fade,layer_name:swayosd
        layer_rule=animation_type_open:fade,animation_type_close:fade,layer_name:logout_dialog
        ```

        This drops `layer_rule=no_shadow:1,layer_name:waybar`.
9.  **`docs/apps/mango.md` (Modify):** a new paragraph after the borders paragraph, before
    `## Reference`:

    > Every animation lasts 150 ms (9 frames at 60 Hz) on one curve, a quadratic ease-out with no
    > overshoot (`0.5,1,0.89,1`). Fades start at 0.5 (opening) and 0.6 (closing) opacity; zooms grow
    > from 0.1 and shrink to 0.6 of full size. Blur is off, so every overlay is opaque. Shadows are
    > on for floating windows only (`shadow_only_floating=1`). Layer shadows stay enabled but no
    > overlay shows one: a layer shadow outlines the layer's whole surface, not what it draws, and
    > rofi's surface spans the screen above the bar, so `rule.conf` turns its shadow off;
    > notifications have `no_shadow` and the bar never gets one. `blur` and `shadows` are master
    > switches: `blur_layer` and `layer_shadows` do nothing without them. On a busy test workload,
    > 150 ms durations alone halved mango's CPU time (2.51 to 1.24 percent) and the GPU's busy time
    > (11.4 to 6.5 percent), measured before shadows were turned on; the full change was not
    > measured. Why these values: [design](../designs/mango-animations.md).

10. **`docs/README.md` (Modify):** after the "Installed versions" line in the page list, add a
    `Designs` entry that links `designs/`, described as "design records for larger changes
    (mango animations)".
11. **`docs/designs/mango-animations.md` (Create):** this file.
12. **Check:**
    *   `mango -c ~/.config/mango/config.conf -p && echo ok`
    *   `tools/docs`, which should leave no diff, then `tools/docs --check` and `./install.sh --check`
    *   `theme lint` and `tests/run`. These scan the working tree, so an unrelated uncommitted file
        with a finding (for example personal paths in `claude/.claude/settings.json`) fails them
        locally; the files in this commit must add no finding.
    *   Save reloads mango. Check CUJ 2 and CUJ 3 on `dark-2026`, run `theme set light-2026`,
        check CUJ 3 again, run `theme set dark-2026`. Take a screenshot with a selection and
        confirm the selection does not animate.
13. **Commit:**
    ```sh
    git add mango/.config/mango/config.conf mango/.config/mango/rule.conf docs/apps/mango.md \
        docs/README.md docs/designs/mango-animations.md
    git commit -m "mango: 150 ms animations without overshoot; shadows on floating windows, blur off"
    ```

### Commit 3: wlogout

14. **`wlogout/.config/wlogout/style.css` (Modify):** in the `window` block,
    `background-color: alpha(@desktop, 0.92);` becomes `background-color: @desktop;`.
15. **`docs/apps/wlogout.md` (Modify):** append to the first paragraph: "Its background is the
    opaque desktop color: mango draws no blur, so a translucent background would show the windows
    behind it."
16. **Check:** `theme lint` adds no finding for these files; `tools/docs --check`; open the power
    menu (Super+Shift+Escape) over a busy window: nothing shows through.
17. **Commit:**
    ```sh
    git add wlogout/.config/wlogout/style.css docs/apps/wlogout.md
    git commit -m "wlogout: opaque background, since mango draws no blur"
    ```

### Step 18: Merge and push

```sh
git checkout main && git merge --ff-only mango-snappy-animations && git push origin main
```

CI runs `install.sh` twice on a fresh VM, then `tests/run`. A push starts a CI VM on this laptop.

### Rollback

Each commit reverts on its own with `git revert`; mango reloads on the next save or Super+R.
Reverting commit 1 does not uninstall powertop; `sudo pacman -Rns powertop` does, if wanted.

--------------------------------------------------------------------------------

*Drafted with EGM*

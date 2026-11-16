# Displays: best mode per display, clamshell when the lid closes

*   **Author:** Test
*   **Date:** 2026-11-15

## Overview

The T14 is used with an external display, an LG UltraFine 32" 4K, and sometimes with others. Today
each display runs at whatever mango picks, the LG at scale 1 (the smallest text), and closing the
lid with the LG connected leaves the laptop panel enabled behind the lid, where windows and focus
can still land. This design gives each display its best mode and a scale for its pixel density,
places the displays to match the desk (the laptop to the right of the LG), and turns the laptop
panel off while the lid is closed and an external display is connected, so the external display is
the only one. It also powers every display off at idle, not just the laptop panel.

The change is in `mango/` (config, the `mango-monitor` script, a user unit, user tmpfiles),
`swayidle/`, and their docs. logind keeps its defaults.

## Key terms

*   **Output:** a display as mango and Wayland see it, named by its connector (`eDP-1` is the
    laptop panel; `DP-1`, `DP-2`, `HDMI-A-1`, `HDMI-A-2` are the ports). A connector name depends
    on which port a display is plugged into, so it does not identify the display; its make, model
    and serial (from the display's EDID) do.
*   **Monitor rule:** a `monitor_rule=` line in mango's config: how to match an output and what
    mode, scale, position and state to give it.
*   **Config reload:** mango re-reads its config when a config file is saved
    (`auto_reload_config`, on by default), on Super+R, and after `theme set`. A reload re-applies
    every monitor rule.
*   **Logical size:** an output's size in layout coordinates, its pixels divided by its scale.
    The LG at scale 1.25 is 3072x1728.

## Findings

Measured on the T14 (Intel UHD, CometLake) with the LG on `DP-1`, mango 0.18.5; mango's behaviour
from its 0.18.5 source.

*   **Lid closed, LG connected: the panel stays on.** Reproduced: with the lid closed,
    `wlr-randr` shows `eDP-1` enabled at 0,0 next to `DP-1`. logind counts the LG as an external
    display, treats the laptop as docked and ignores the lid (`HandleLidSwitchDocked=ignore`, the
    default). Nothing in mango's config reacts to the lid.
*   **A runtime disable does not survive a reload.** `mmsg dispatch disable_monitor` turns an
    output off, but `reapply_monitor_rules` (`src/config/reapply.c`) re-enables every output whose
    rule does not say `disable:1`, and every output with no rule. When the panel comes back,
    windows whose last monitor was `eDP-1` move back to it (`handle_output_layout_change`,
    `oldmonname`). So the panel's off state has to be a rule mango reads on every reload.
*   **Idle wake would light the panel behind the lid.** swayidle runs
    `mmsg dispatch wakeup_monitor,eDP-1` on resume, which enables the panel unconditionally.
    The LG is never powered off at idle: only `eDP-1` sleeps.
*   **`monitor.conf` names the wrong port.** Its 4K rule is for `DP-2` at 0,0, overlapping the
    panel; the LG is on `DP-1` today and gets mango's defaults (preferred mode, scale 1, placed
    right).
*   **The LG.** EDID: 3840x2160 at 60 Hz preferred, 700x400 mm (139 PPI), 10 bits per colour,
    40-60 Hz range, HDR10 with a 248 cd/m² peak, wide gamut (red at 0.675, 0.315, near DCI-P3).
*   **What this hardware and mango build can't do.**
    *   VRR: no connector on this GPU has a `vrr_capable` property (Intel Gen9 has no adaptive
        sync), so `vrr:1` would have no effect.
    *   HDR: mango's HDR needs its Vulkan renderer, which this build (scenefx, GLES) can't use;
        the LG's 248 cd/m² peak would also make HDR dimmer than SDR.
    *   10 bits per colour: mango only raises the render format for HDR (`hdr_depth`), so the
        output stays 8-bit.
    *   An ICC profile (`icc:`): output colour transforms also need the Vulkan renderer. Normal
        (sRGB) content looks oversaturated on the LG's wide-gamut panel; the monitor's own sRGB
        picture mode, set once in its on-screen menu, fixes that.
*   **What mango does support.** Fractional scaling (`wp_fractional_scale_v1` with viewporter),
    so 1.25 renders sharp in Ghostty, Firefox, GTK 4 and Qt 6. `switchbind=fold|unfold` runs an
    action when the lid closes or opens; it fires only on a change, never at startup.
    `source_optional=` includes a config file that may not exist, and mango watches included files
    for changes. Rule matching on make, model and serial is exact (`strcmp`); the name is a regex.
    When an output comes back, windows left with no monitor move to the selected one, so a moment
    with no output at all loses nothing.

## Decisions

From the user:

*   The LG runs at scale 1.25: a 3072x1728 workspace, text about the size of the laptop panel's
    at scale 1 once viewing distance is counted (about 70 cm against 50 cm).
*   The laptop sits to the right of the LG.
*   Displays without a rule of their own get the best mode and a scale from their pixel density,
    picked automatically.
*   Lid closed with an external display connected: the external display is the only one.

Defaults (correct any in review):

*   Lid open with an external display connected: both on, side by side, as today.
*   Lid closed with no external display: the laptop suspends, as today (logind's default).
*   Outputs are bottom-aligned: the laptop's bottom edge lines up with the LG's.
*   The laptop panel keeps its preferred mode (1920x1080 at 60 Hz) and scale 1.
*   `Xft.dpi` (the scale XWayland apps draw themselves at) becomes 120, matching the LG's 1.25;
    today it is 144 (1.5) while every output runs at scale 1. No XWayland app runs today.
*   No VRR, HDR, 10-bit or ICC settings (Findings).

## Design

Three pieces, each with one owner.

### `monitor.conf`: displays pinned by hand

Static rules for displays whose settings are fixed by hand, matched by make, model and serial,
never by connector name. One today, the LG:

```ini
monitor_rule=make:LG Electronics,model:LG ULTRAFINE,serial:509AZWSGA385,width:3840,height:2160,refresh:60,scale:1.25,primary:1
```

No position: `mango-monitor` owns the layout. With `x` and `y` unset, a reload leaves an enabled
output where it is. The rules for `eDP-1` and `DP-2` go, and so does `hdr_depth` (HDR is not
possible here). The file ends with the generated file:

```ini
source_optional=~/.local/state/mango/outputs.conf
```

`primary:1` makes the LG the XWayland primary output while it is connected; without it, the panel
is primary (the first matching rule).

### `mango-monitor`: the layout and the laptop panel

`mango/.local/bin/mango-monitor`, rewritten in Python (as `mango-keys` and `theme` are). Its data:
the lid state (`/proc/acpi/button/lid/*/state`; no lid counts as open) and the outputs from
`wlr-randr --json` (name, make, model, serial, enabled, modes, physical size), including disabled
ones. A pure function turns them into a plan: per output, enabled or not, mode, scale, position.

*   **Internal or external.** An output named `eDP-*`, `LVDS-*` or `DSI-*` is the laptop panel;
    every other output is external.
*   **Pinned or automatic.** An external display is pinned when a `monitor_rule` in
    `~/.config/mango/monitor.conf` sets at least one of make, model and serial and every one it
    sets equals the display's (mango's test, without the name). mango gives a pinned display its
    mode and scale; the script leaves them alone and only positions it. Rules that match by name
    alone are not considered (a connector name does not identify a display).
*   **Best mode (automatic).** Among modes at 59 Hz or more (all modes if there are none), the
    most pixels, then the highest refresh. A 4K TV that does 4K only at 30 Hz gets 1080p at 60 Hz.
*   **Scale (automatic).** Pixel density divided by 110, rounded to a quarter, kept between 1 and
    3; 1 when the physical size is unknown (0, or under 100 mm wide, as projectors report). 110
    is the density that gives the LG the user's 1.25 (139 / 110 = 1.27). A 27" 4K gets 1.5, a 27"
    1440p or a 24" 1080p gets 1, a 15.6" 4K gets 2.5.
*   **Panel.** Off when the lid is closed and an external display is connected; otherwise on. The
    plan never leaves no output enabled.
*   **Layout.** External displays left to right in connector-name order, the laptop panel
    rightmost, every output bottom-aligned to the tallest, x and y never negative (negative
    coordinates break pointer input in XWayland apps). With the LG: the LG at 0,0, the panel at
    3072,648. With the lid closed: the LG alone at 0,0.

Commands:

*   `mango-monitor apply [--dry-run]`: computes the plan and applies the difference in one
    `wlr-randr` call (one atomic output configuration), then writes the panel's rule to
    `~/.local/state/mango/outputs.conf` if it changed, e.g.
    `monitor_rule=name:^eDP-1$,x:3072,y:648,disable:1`. The rule keeps the panel's state and
    position across config reloads; the `wlr-randr` call is what takes effect now. `--dry-run`
    prints the plan and changes nothing. While the displays sleep (below), `apply` does nothing:
    `wake` applies.
*   `mango-monitor toggle` (Super+M p, as today): turns the panel off or on until the next lid or
    display change, through the same `wlr-randr` call and rule. It refuses to turn off the only
    enabled output; today's toggle allows it.
*   `mango-monitor watch`: runs `apply`, then follows `mmsg watch all-monitors` and runs `apply`
    when the set of connected outputs (name and serial, from `wlr-randr`) changes. The stream also
    reports focus and tag changes; those are ignored.
*   `mango-monitor sleep` and `wake`, for swayidle: `sleep` powers every enabled output off
    (`mmsg dispatch sleep_monitor,NAME`) and leaves a marker in `$XDG_RUNTIME_DIR`; `wake`
    removes the marker and runs `apply`, so a closed lid keeps the panel off.

### `~/.local/state/mango/outputs.conf`: the panel's rule, generated

Written only by `mango-monitor`, never by hand, and never in the repo. A stale "panel off" with no
external display would start mango with no output, so the file never outlives a session:

*   `mango-monitor.service` removes it when it stops (`ExecStopPost`), which is when the session
    ends.
*   User tmpfiles (`mango/.config/user-tmpfiles.d/mango-monitor.conf`) remove it at boot and
    create `~/.local/state/mango/`, which mango needs to watch the file.

With the file absent, mango gives the panel its defaults (preferred mode, scale 1, enabled), and
the unit applies the plan once the session starts.

### Triggers

| Event | Runs |
|---|---|
| Lid closes or opens | `switchbind=fold,spawn,~/.local/bin/mango-monitor apply` and the same for `unfold`, in `bind.conf`'s `common` mode so they work in any key mode |
| Display plugged in or out | `mango-monitor.service` (`watch`), a user unit in `mango/.config/systemd/user/` like `mango-whichkey.service` |
| Session start | the unit's first `apply` |
| Idle 10 min / activity | swayidle: `mango-monitor sleep` / `mango-monitor wake`, replacing `sleep_monitor,eDP-1` / `wakeup_monitor,eDP-1` |
| Super+M p | `mango-monitor toggle` |

logind is unchanged: lid closed with an external display connected is docked (ignored), so the
laptop stays awake for the LG; lid closed with none suspends. Unplugging the LG with the lid
closed turns the panel back on (so windows land on it), and logind then suspends.

### Walkthroughs

*   **At the desk, lid open, LG plugged in.** mango applies the LG's rule (4K at 60 Hz, 1.25) and
    places it right of the panel; the unit sees a new output and moves the LG to 0,0 and the panel
    to 3072,648.
*   **Close the lid.** `fold` runs `apply`: the panel turns off and its rule says `disable:1`; its
    windows move to the LG. A later `theme set` keeps it off.
*   **Open the lid.** `unfold` runs `apply`: the panel comes back at 3072,648 and its windows move
    back to it.
*   **Wake from suspend with the lid closed and the LG just plugged in.** No lid event fires; the
    unit sees the new output and turns the panel off.
*   **A projector.** Not pinned: it gets its best mode at scale 1 (unknown size), on the left.

## Changes

| File | Change |
|---|---|
| `mango/.config/mango/monitor.conf` | The LG's rule; drop the `eDP-1` and `DP-2` rules and `hdr_depth`; `Xft.dpi: 120`; `source_optional` last |
| `mango/.config/mango/bind.conf` | `switchbind` fold and unfold in `common`; Super+M p runs `mango-monitor toggle` |
| `mango/.local/bin/mango-monitor` | Python rewrite: `apply`, `toggle`, `watch`, `sleep`, `wake` |
| `mango/.config/systemd/user/mango-monitor.service` | New: `watch`, removes the generated file on stop |
| `mango/.config/user-tmpfiles.d/mango-monitor.conf` | New: create `~/.local/state/mango/`, remove the generated file at boot |
| `swayidle/.config/systemd/user/swayidle.service` | Every display off at 10 min, back on through the plan |
| `docs/apps/mango.md`, `docs/session.md`, `docs/apps/swayidle.md` | Displays, lid and idle behaviour; the LG's sRGB picture mode as a one-time step |

`tools/docs` regenerates the reference blocks (the new unit and tmpfiles entry); `mango/packages`
already has `wlr-randr`.

## Verification

*   `mango-monitor apply --dry-run` live (it changes nothing): the plan for the LG must be 4K at
    60 Hz, 1.25, at 0,0, the panel at 3072,648, and with the lid closed the panel off.
*   The plan function against recorded `wlr-randr` output for a 1440p 144 Hz monitor, a TV with
    4K at 30 Hz and 1080p at 60 Hz, a projector reporting 0 mm, and two external displays at once.
*   `mango -c ~/.config/mango/config.conf -p`, `theme lint`, `tools/docs --check`, `tests/run`,
    `./install.sh --check`.
*   desktop-vm `up` and `check` (it has no lid and one output): the session starts, the unit runs,
    `apply` leaves the single output on, and a config reload changes nothing. Needs 6 GB free.
*   On the T14 (the lid exists only there), by the user after the merge: close the lid with the LG
    connected (only the LG stays on), `theme set` while closed (the panel stays off), open it
    (the panel returns at the right), unplug the LG with the lid closed (the laptop suspends), and
    idle 10 minutes (both displays go dark, and come back with the lid's state).

# Displays: best mode per display, clamshell when the lid closes

*   **Author:** Test
*   **Date:** 2026-11-15

## Overview

The T14 is used with an external display, an LG UltraFine 32" 4K, and sometimes with others. Today
each display runs at whatever mango picks, the LG at scale 1 (the smallest text), and closing the
lid with the LG connected leaves the laptop panel enabled behind the lid, where windows and focus
can still land. This design hands display management to
[way-displays](https://github.com/alex-courtis/way-displays), an open-source daemon for wlroots
compositors: it gives each display its native resolution at its highest refresh and a scale from
its pixel density, places the displays to match the desk (the laptop to the right of the LG), and
turns the laptop panel off while the lid is closed and an external display is connected, so the
external display is the only one. One YAML file holds the settings; `way-displays -g` shows the
state and `way-displays -s`/`-t`/`-w` change and save it. A small glue script covers what mango
does differently from sway: config reloads and idle sleep. Every display now powers off at idle.

The change is a new `way-displays/` app folder, `mango/` (config, the `mango-monitor` glue, user
tmpfiles), a udev rule in `thinkpad/root/`, `swayidle/`, and their docs. logind keeps its
defaults.

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

*   Existing open-source tools over custom code; managing displays should be easy.
*   The LG runs at scale 1.25: a 3072x1728 workspace, text about the size of the laptop panel's
    at scale 1 once viewing distance is counted (about 70 cm against 50 cm).
*   The laptop sits to the right of the LG.
*   Other displays get their best mode and a scale from their pixel density, automatically.
*   Lid closed with an external display connected: the external display is the only one.

Defaults (correct any in review):

*   Lid open with an external display connected: both on, side by side, as today.
*   Lid closed with no external display: the laptop suspends, as today (logind's default).
    way-displays never disables the only display.
*   Displays are bottom-aligned: the laptop's bottom edge lines up with the LG's.
*   The laptop panel stays at scale 1 (auto scale would give it 1.5).
*   The best mode is the native resolution at its highest refresh (`MAX_PREFERRED_REFRESH`), not
    the highest resolution at any refresh (`MAX`), which would put a TV that does 4K only at 30 Hz
    at 30 Hz.
*   way-displays shows a notification only for warnings and errors: it may run its callback
    several times per connect.
*   The lid is read through a udev rule that gives the logged-in user the lid switch device only
    (`uaccess`), not membership of the `input` group, which would expose every keyboard.
*   `Xft.dpi` (the scale XWayland apps draw themselves at) becomes 120, matching the LG's 1.25;
    today it is 144 (1.5) while every output runs at scale 1. No XWayland app runs today.
*   No VRR, HDR, 10-bit or ICC settings (Findings); `VRR_OFF` for every display, so way-displays
    doesn't try.

## Design

### way-displays owns the displays

`way-displays/` is a new app folder: `packages` (`way-displays`, AUR), `.config/way-displays/cfg.yaml`,
and `.config/systemd/user/way-displays.service` (a session daemon: `PartOf=`/`After=`/
`Requisite=graphical-session.target`, `Restart=on-failure`). It talks to mango over wlr output
management (protocol version 4, which mango's wlroots 0.20 provides) and reads the lid with
libinput. `cfg.yaml`:

```yaml
ARRANGE: ROW
ALIGN: BOTTOM
ORDER:                       # externals left to right, the laptop panel rightmost
- '!^(DP|HDMI)-'
- '!^eDP-'
SCALING: TRUE
AUTO_SCALE: TRUE
AUTO_SCALE_DPI: 110          # the density that gives the LG the user's 1.25 (139 / 110 = 1.27)
AUTO_SCALE_MIN: 1.0
AUTO_SCALE_MAX: 3.0
SCALE_ROUND_TO: 0.25
SCALE_ROUND_STRATEGY: NEAREST
SCALE:
  'LG Electronics LG ULTRAFINE 509AZWSGA385': 1.25
  '!^eDP-': 1.0
MODE:
  '!^(DP|HDMI)-':
    MAX_PREFERRED_REFRESH: TRUE
VRR_OFF:
- '!.*'
DISABLED:
  '!^eDP-':
    IF:
    - LID: CLOSED
CALLBACK_CMD: ~/.local/bin/mango-monitor sync
```

With the LG: the LG at 0,0 (3072x1728), the panel at 3072,648. With the lid closed: the LG alone.
A 27" 4K gets 1.5, a 27" 1440p or a 24" 1080p gets 1, a 15.6" 4K gets 2.5, a projector reporting
no size gets 1.

Changing things: `way-displays -g` prints every display, its mode, scale, position and why;
`way-displays -s SCALE 'ULTRAFINE' 1.5` or `-s MODE ...` changes the live state; `-w` saves it to
`cfg.yaml`, which is linked into the repo (way-displays writes through the link and drops the
comments; review `git diff` before committing, as for any app-written config).

### mango-monitor: glue for what mango does differently

`mango/.local/bin/mango-monitor`, bash, replacing today's toggle.

*   `sync`, way-displays' `CALLBACK_CMD`: after each change, writes
    `monitor_rule=name:^eDP-1$,disable:1` to `~/.local/state/mango/outputs.conf` when the panel is
    connected and disabled, and empties the file otherwise, writing only on a difference. mango's
    config reload re-enables any output whose rule doesn't say `disable:1` (Findings), and
    way-displays would then disable it again, moving its windows twice; with the rule, a reload
    (`theme set`, Super+R, a config save) leaves the panel off. For a `WARNING`, `ERROR` or
    `FATAL` callback it also runs `notify-send "way-displays" "$CALLBACK_MSG"`. When `wlr-randr`
    fails or times out it leaves the file alone: writing it would reload mango for nothing.
    Each write is a config file change, so mango reloads its whole config (keyboard layout, tag
    rules, every monitor rule), once per panel change.
*   `toggle` (Super+M p, as today): `way-displays -t DISABLED eDP-1`, a manual override that
    way-displays drops once the lid rule agrees with it. It refuses when the panel is the only
    enabled display (a notification says so); today's toggle allows that. Without the daemon it
    says so in a notification and can only turn the panel back on (it empties the rule and enables
    the panel), never off. The override can still outlive the display that made it safe:
    turn the panel off, then unplug the LG, and way-displays keeps the panel off (with one display
    it ignores the lid, so its own state is "on" and never matches the override). So `sync`, seeing
    the panel connected and off with no display on, runs `way-displays -t DISABLED eDP-1` again,
    which drops the override (`-d` would delete the lid condition from the config), and writes
    nothing: the next callback does. It reads the outputs again a second later and acts only if
    that read agrees: one snapshot can catch the gap right after an unplug, or a callback resumed
    at wake. Not while the displays are asleep (the lid inhibitor below is
    held): a callback that started before `sleep` would see every display off and queue the toggle
    for the paused daemon, which would light the panel behind the lid on wake.
*   `sleep` and `wake`, for swayidle. mango powers a display off by disabling it, and
    way-displays re-enables any display that is not in the state it wants (`act.c`), so idle
    sleep would undo itself. `sleep` pauses way-displays (`systemctl --user kill -s STOP
    way-displays.service`), then `mmsg dispatch sleep_monitor,NAME` for each enabled display;
    `wake` resumes it (`-s CONT`), and way-displays turns back on what should be on: a closed lid
    keeps the panel off. mango matches a bare monitor name in `mmsg dispatch` as a regex
    (`match_monitor_spec`), so `DP-1` would match `eDP-1` too: every dispatch anchors it,
    `sleep_monitor,^DP-1$`.
*   The lid at idle. logind counts an external display as docking the laptop only while its
    connector is enabled, and `sleep_monitor` disables it. With the lid closed and every display
    asleep, logind's re-check of the closed lid (it runs after each event it handles) would
    suspend the laptop at 10 min. So `sleep`, while an external display is connected (DRM sysfs,
    any connector but eDP, LVDS, DSI or a VM's virtual one), first starts a transient user unit,
    `mango-monitor-lid.service`: `systemd-inhibit --what=handle-lid-switch --mode=block` around
    `mango-monitor hold-lid`, which checks every 5 s and ends once no external display is
    connected, so unplugging the LG while asleep with the lid closed suspends within 5 s. The unit
    is `Type=notify`: the holder reports ready, and systemd-inhibit starts it only after logind
    granted the inhibitor, so the displays sleep only once it is held (polkit allows it for the
    user's active session). If it can't be taken, the external displays stay on. One unit name
    means one inhibitor, `PartOf=graphical-session.target` ends it with the session, and stopping
    it ends the holder too. `wake` ends it once an external display is on again, the lid is open,
    or the last external is gone (5 s at most): releasing it is itself an event for logind, so
    releasing before way-displays turned the LG back on would suspend the laptop in that gap.

`monitor.conf` keeps no display rules: the `eDP-1` and `DP-2` rules and `hdr_depth` go, so no rule
fights way-displays on reload (a display with no rule keeps its mode, scale and position). It
keeps `xwayland_ignore_scale=1`, sets `Xft.dpi: 120`, and ends with
`source_optional=~/.local/state/mango/outputs.conf`.

### The generated rule never outlives a session

A stale `disable:1` with no external display would start mango with no output. `way-displays.service`
empties the file when it stops (`ExecStopPost`, which runs `mango-monitor stop-hook`), and user tmpfiles
(`mango/.config/user-tmpfiles.d/mango-monitor.conf`) create `~/.local/state/mango/` and remove the
file at boot. A restart (`install.sh` restarting a changed unit, `Restart=on-failure`) with the lid closed
over an external display keeps the file: emptying it would reload mango, light the panel behind
the lid and move its windows twice until way-displays is back a second later. At logout
`graphical-session.target` is still active while its units stop, with a stop job waiting. So
`stop-hook` empties the file when the target is inactive or has a stop job. Otherwise (a restart,
a manual `systemctl --user stop`, the start limit) it keeps `disable:1` only while the lid is
closed and `wlr-randr --json` (`timeout 5`) shows an enabled external output, and empties it
else: with the lid open and nothing managing the panel it would stay off. If wlr-randr times out
(a compositor that is there but not answering) the file is unchanged; if it fails at once (mango
crashed or was killed while the target stays up) the file is emptied, since a kept `disable:1`
would start the next login with no output once the external display is gone. The write is `sync`'s atomic one, and the unit's `-` prefix keeps a failing hook
from failing the stop.

### Config reloads

Every reload re-applies every monitor rule, and an output with no rule is enabled
(`reapply_monitor_rules`). The generated rule keeps the panel off across reloads, but a reload while
the displays are asleep at idle (a config save or `theme set` while idle) wakes every other display;
way-displays stays paused and turns nothing off until activity resumes it. Rare, and waking is the
safe direction, so it is left as is.

### The lid

way-displays opens the lid switch with libinput, which needs read access to its `/dev/input`
node. `thinkpad/root/etc/udev/rules.d/70-lid-switch.rules`:

```
SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="Lid Switch", TAG+="uaccess"
```

logind then grants the logged-in user that one device. It takes effect at the next boot, or on
this machine once after `install.sh --system` with `sudo udevadm trigger --subsystem-match=input`.
logind is unchanged: lid closed with an external display is docked (ignored), so the laptop stays
awake for the LG; lid closed with none suspends. At idle the lid inhibitor (above) keeps that true
while every display is asleep.

way-displays logs "Unable to monitor laptop lid via libinput ... usermod -a -G input" once at every
start: its discovery opens every input device on the seat and gets EACCES on all but the lid.
`Monitoring lid device: /dev/input/eventN` after it confirms the lid is read.

### The login screen

The greeter is its own small mango session (greetd runs `mango -c
/etc/greetd/mango-greeter-config.conf -s /etc/greetd/mango-greeter-session.sh`, both from
`sysc-greet-mango`), so neither way-displays nor `mango-monitor` runs there. sysc-greet puts the
login prompt on the monitor mango focuses first, the laptop panel, so with the lid closed the
prompt sits behind the lid and the LG shows only the background. The greeter has no keybindings to
move it. Rather than adding one, the greeter gets the same rule as the desktop: lid closed with an
external display connected, the panel is off and the prompt is on the external display.

The repo owns three files in `greeter/root/etc/greetd/` (the package's stay untouched):

*   `greeter-panel`: `mmsg dispatch disable_monitor,^<panel>$` when the lid is closed
    (`/proc/acpi/button/lid/*/state`, none counts as open) and `wlr-randr --json` shows an enabled
    external display, `enable_monitor` otherwise. The name is anchored: mmsg matches it as a regex.
    No reloads happen in the greeter, so a runtime disable is enough. It exits 0 on any error.
*   `mango-greeter.conf`: `source=/etc/greetd/mango-greeter-config.conf`, then
    `switchbind=fold,spawn,/etc/greetd/greeter-panel` and the same for `unfold`, so closing or
    opening the lid at the login screen moves the prompt too.
*   `greeter-session.sh`: runs `greeter-panel`, starts a background watcher, then
    `exec /etc/greetd/mango-greeter-session.sh`, so the panel is off before sysc-greet picks its
    monitor. The watcher follows `mmsg watch all-monitors` and re-runs `greeter-panel` when the
    sorted set of monitor names in an event differs from the last one acted on (mango streams
    focus and tag changes too), so a display plugged in or out at the login screen moves the
    prompt. It reads the stream until mmsg exits, which happens when mango quits, and its output
    goes to /dev/null so it holds no descriptor of the greeter's log pipe: it neither keeps the
    greeter alive nor blocks `mmsg dispatch quit`. `greeter-panel` never blocks or fails
    (`timeout 5` on wlr-randr, exit 0 on any error).

Both scripts are bash (`#!/usr/bin/env bash`), as everywhere in the repo.

`config.toml` points at `mango-greeter.conf` and `greeter-session.sh`. After login the user's
mango starts with the panel on until way-displays turns it off, about a second.

### Walkthroughs

*   **At the desk, lid open, LG plugged in.** way-displays sets 4K at 60 Hz and 1.25, the LG at
    0,0, the panel at 3072,648.
*   **Close the lid.** way-displays disables the panel; its windows move to the LG; `sync` writes
    the rule, so a later `theme set` keeps it off.
*   **Open the lid.** The panel comes back at 3072,648, its windows move back, `sync` empties the
    rule.
*   **Wake from suspend with the lid closed and the LG just plugged in.** way-displays sees the LG
    arrive and the lid closed, and disables the panel.
*   **Boot with the lid closed and the LG connected.** The login prompt is on the LG.
*   **A projector.** Native resolution at its highest refresh, scale 1, on the left.

## Changes

| File | Change |
|---|---|
| `way-displays/packages`, `.config/way-displays/cfg.yaml`, `.config/systemd/user/way-displays.service` | New app |
| `docs/apps/way-displays.md` | New: what it does here, how to change things |
| `mango/.local/bin/mango-monitor` | Bash: `sync`, `toggle`, `sleep`, `wake`, and the internal `hold-lid` (the lid inhibitor's holder) and `stop-hook` (way-displays.service's `ExecStopPost`) |
| `mango/.config/mango/monitor.conf` | No display rules; `Xft.dpi: 120`; `source_optional` last |
| `mango/.config/mango/bind.conf` | Super+M p runs `mango-monitor toggle` |
| `mango/.config/user-tmpfiles.d/mango-monitor.conf` | New: create the state directory, remove the generated rule at boot |
| `greeter/root/etc/greetd/config.toml`, `greeter-panel`, `mango-greeter.conf`, `greeter-session.sh` | The login prompt follows the lid rule |
| `greeter/packages` | `jq`, `wlr-randr` for `greeter-panel` |
| `thinkpad/root/etc/udev/rules.d/70-lid-switch.rules` | New: the lid switch for the logged-in user |
| `swayidle/.config/systemd/user/swayidle.service` | Every display off at 10 min through `mango-monitor sleep`/`wake` |
| `docs/apps/mango.md`, `docs/apps/thinkpad.md`, `docs/session.md`, `docs/apps/swayidle.md`, `docs/keybindings.md` | Displays, lid and idle; the LG's sRGB picture mode as a one-time step |

`tools/docs` regenerates the reference blocks; `tools/docs --snapshot` records the new package.

## Verification

*   `way-displays` builds and installs from the AUR (`install.sh`), and its config parses:
    `way-displays -c <cfg> -g` against a running daemon in the VM.
*   `mango -c ~/.config/mango/config.conf -p`, `theme lint`, `tools/docs --check`, `tests/run`,
    `./install.sh --check`, `systemd-analyze --user verify` on the new and changed units.
*   desktop-vm `up` and `check` (one output, no lid): the session starts, way-displays runs and
    keeps the single output on, a config reload changes nothing, `mango-monitor sync` leaves the
    rule file empty. Needs 6 GB free.
*   On the T14, by the user after the merge: close the lid with the LG connected (only the LG
    stays on), `theme set` while closed (the panel stays off), open it (the panel returns at the
    right), unplug the LG with the lid closed (the laptop suspends), idle 10 minutes (both go dark
    and come back with the lid's state; with the lid closed the laptop stays awake and
    `systemd-inhibit --list` shows `mango-monitor` while the displays are off), Super+M p, then
    unplug the LG with the panel off (the panel comes back), and reboot with the lid closed (the
    login prompt is on the LG).

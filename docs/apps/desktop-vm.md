# desktop-vm

A hand-run QEMU/KVM VM that boots this repo's desktop from the working tree and shows what CI cannot: the boot, the greeter and the session on a screen, without touching your live session.

## Why a VM

The boot menu and the greeter exist only before a session starts, and the session itself holds the
screen and the keyboard; the only other way to see them is to reboot the laptop. The VM boots
[runner-up](runner-up.md)'s Arch cloud image under OVMF, with `virtio-vga-gl` and `egl-headless`, so
mango gets real GLES through virgl. Screenshots come from the VNC framebuffer (QMP's `screendump`
has no surface under `egl-headless`) and keys from QMP `send-key`. The output is named `Virtual-1`,
so mango's `^eDP-1$` monitor rule does not match; that is expected and not changed.

## Taking turns with CI

QEMU runs in a transient user unit, not as a child of the command, so the VM outlives the shell that
started it. `Conflicts=runner-up.service` stops the coordinator when the VM starts, so no new CI job
starts; a job already running keeps its VM, and the unit's `ExecStartPre` (`desktop-vm wait-ci`) waits
for those QEMU processes to finish. `ExecStopPost` (`desktop-vm restore-ci`) starts the coordinator
again, but only if it was active before. `RuntimeMaxSec=4h` keeps a forgotten VM from blocking CI
forever.

## What it checks, and what it does not

`base` proves the repo can go from runner-up's cloud image to this desktop: it delivers the working
tree as a git bundle (HEAD plus untracked non-ignored files, in a temporary index, so your index and
stash are untouched), runs `bootstrap.sh`, runs `install.sh` again and fails if it prints any of the
change lines `tests.yml` greps for, then runs `install.sh --check`. It does not prove a clean install
(CI does), and it does not cover the laptop's UKI boot path, `grub-install`, f2fs, ThinkPad hardware
(TLP, fprintd, backlight, battery, Bluetooth), the eDP-1 monitor rule, pixel diffing, or a daemon.

## `up`: a session run

`up` boots the base on a throwaway overlay (`-snapshot`: `base.qcow2` is never written), delivers the
working tree, runs `install.sh` (not `bootstrap.sh`: the base already bootstrapped) with the same CI
environment, then again (it must change nothing) and `install.sh --check`. It then reboots the guest
and records the boot over VNC: a frame every 0.5 s, kept only when its pixels differ from the last
kept one (at most 40). It finishes when the guest agent answers from the new boot, `greetd` is active
and the screen has not changed for 3 s, and leaves the VM running at the greeter. Any failure or
interrupt stops the VM and keeps the run directory. If the base is stale (image or hardware profile
changed, older than 7 days, `refs/desktop-vm/base` missing, or the tree changed something `install.sh`
cannot undo: a removed package, a removed or renamed `root/` file, any `setup.sh` change, a deleted
user unit), `up` prints why and rebuilds it first; `--rebuild` forces that.

## `check`: log in and test

`check` runs on the VM `up` left at the greeter (it refuses if the unit is not alive) and appends to
the current run directory. It never stops the VM, pass or fail, so you can look at it; `down` ends it.

1. Logs in unless the user already has a graphical session: types the user name and `ret` at the
   greeter (sysc-greet), waits 2 s for the password prompt, types the password and `ret`.
2. Waits up to 120 s for a session of the user on `seat0` with `Type=wayland` and `Class=user` (the
   `manager` session has no seat and is ignored) and for `graphical-session.target` to be active for
   the user. On timeout it saves `login-failed.png` and fails saying which condition never held.
3. Waits until the screen has not changed for 3 s (up to 60 s) and saves it as `session.png`.
4. Runs `tests/run` as the user in the session environment (`WAYLAND_DISPLAY`,
   `MANGO_INSTANCE_SIGNATURE`, ... taken from `systemctl --user show-environment`), with `CI=1` and
   mise's auto-install off as `tests.yml` has it, into `tests.log` (timeout 30 min). A non-zero exit
   fails the check.
5. Collects `failed-system.txt` (`systemctl --failed`), `failed-user.txt` (`systemctl --user
   --failed`) and `journal-errors.txt` (`journalctl -b -p err`). A failed unit that is not in
   `desktop-vm/expected-failures` fails the check; listed ones are reported as expected. Journal
   errors are counted and the first lines printed but never fail the check: the VM always logs
   TDX/SGX CPU notices.
6. Writes `verdict.json` (`pass`, `reasons`, `expected`, `journal_errors`), prints one line per
   reason and `check: PASS` or `check: FAIL (<n> reasons)`, and exits 0 or 1. A failure in steps 1-4
   (login timeout, guest agent gone) is a reason too, and the verdict is still written.

## `view`: watch it

`view` opens `vncviewer` (tigervnc, from `desktop-vm/packages`) on `vnc.sock` and returns at once:
the viewer runs detached, logs to `<run>/viewer.log`, and the command prints its PID. It refuses if
the unit is not alive. Close the window to end it; `down` ends it too because the socket goes away.

It is view-only by default: the tool's QMP keys (`keys`, `type`, `check`'s login) and a human's typing
would interleave on the same guest keyboard. `--control` drops that for hands-on use. The viewer
always connects `-Shared`, since QEMU's VNC server closes the other clients when one asks for an
exclusive session, which would cut the tool's own frame grabs; and `-RemoteResize=0`, so the guest
stays at 1920x1080, the output mode under test.

## Commands

```bash
desktop-vm base             # build the base disk (needs runner-up's image and a kvm place)
desktop-vm up [--rebuild]   # boot the working tree on the base, reboot, stop at the greeter
desktop-vm check            # log in, run tests/run in the session, list failed units; exit 0 or 1
desktop-vm view [--control]  # VNC viewer on the screen, view-only unless --control
desktop-vm shot [FILE]      # one VNC frame to PNG (default <run>/shot-NN.png)
desktop-vm keys ret ctrl-alt-f2
desktop-vm type desktopvm
desktop-vm exec 'systemctl is-active greetd'
desktop-vm exec --user 'systemctl --user --failed'
desktop-vm status           # unit, run directory, base age and why it is stale
desktop-vm down             # QMP quit; the unit ends and the coordinator comes back
```

Resources come from the first `provider: kvm` place in `~/.config/runner-up/config.json` (`cores`,
`memoryMB`, `diskGB`, `image`), never from constants. `qemu-base` is not repeated here: runner-up's
packages declare it, and this VM boots runner-up's image anyway.

## State and logs

`$XDG_STATE_HOME/desktop-vm/` (default `~/.local/state/desktop-vm/`) holds `base.qcow2`,
`base-vars.fd`, `base.json` and `runs/<UTC timestamp>-base/` or `-up/`: the QEMU serial log, the
delivered commit, and each guest command's log (`install-1.log`, `install-2.log`, `check-install.log`,
`deliver.log`, …). A `check` adds `session.png`, `tests.log`, `failed-system.txt`, `failed-user.txt`,
`journal-errors.txt`, `verdict.json` (and `login-failed.png` when the login did not work). An `up`
run also holds `boot-NN-<seconds>s.png` (the distinct frames of the reboot, seconds counted from the
reboot command) and `greeter.png` (the settled greeter).
`$XDG_RUNTIME_DIR/desktop-vm/` (mode 0700) holds `qmp.sock`, `qga.sock`, `vnc.sock` and the `run`
symlink to the current run directory.

`status` builds a commit of the working tree in a temporary index to judge staleness: it writes git
objects, never refs or your index.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`desktop-vm/packages`): `edk2-ovmf` (UEFI firmware: OVMF_CODE.4m.fd / OVMF_VARS.4m.fd), `qemu-hw-display-virtio-gpu-gl` (the GL GPU device; pulls virglrenderer (host GL for the guest)), `qemu-hw-display-virtio-vga-gl` (virtio-vga-gl: the display mango runs on (real GLES, not software VGA)), `qemu-ui-egl-headless` (egl-headless display for virgl (pulls qemu-ui-opengl); QMP screendump has no surface), `tigervnc` (vncviewer for `desktop-vm view`: connects to the VM's VNC unix socket)

**Linked into your home** (stow, `install.sh --link`):

- `~/.local/bin/desktop-vm`
<!-- end generated -->

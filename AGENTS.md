# AGENTS.md

Guidance for coding agents (Claude Code) in this repository.

## What this is

Personal dotfiles for an Arch Linux desktop on **mangowm** 0.18.x (Wayland) on a ThinkPad T14
(single panel `eDP-1`, 1920x1080, scale 1). `docs/` is the reference: read `docs/README.md` (layout,
app index), `docs/session.md`, `docs/theming.md`, `docs/testing.md` before changing things.

## Layout (details: docs/README.md#layout)

**One model for every app; no special cases.** An app folder uses only these parts:
`packages` (pacman/AUR), `pkg/<name>/PKGBUILD` (unpackaged programs), dot-entries (`.config/`,
`.local/`, `.zshrc` …: linked into `$HOME` by GNU stow, one link per file), `root/` (system files,
copied to `/` by `install.sh --system`), `*.tmpl` (rendered in place by `theme`), `render.sh`
(generated art), `reload.sh` (after `theme set`), `setup.sh` (only state that isn't a file:
services, gsettings, login shell, linger), `.config/systemd/user/*.service` (enabled by install.sh).
A new need either fits one of these or extends install.sh/theme for **every** app, never one.

- `bootstrap.sh` (fresh Arch → this desktop) clones the repo and runs `install.sh`.
- Paths in configs, binds, units and scripts use the **installed** locations: `~/.local/bin/<cmd>`,
  `~/.config/<app>/…`, `%h/.config/…` in units, `/usr/...` for packaged files. Never repo paths.
- A new file in an app folder goes live only after `./install.sh --link` (or `--system`).
- The repo owns every file it links or copies; `install.sh --check` reports drift.

## Rules

- A standing instruction from the user, the person you are working for. It is about how your turns end.
  A message with no tool call in it ends your turn, and the work stops there until you are asked to continue.
  The user has seen you end turns in four ways while work they asked for was still owed, and does not want any of them. One: a long summary of what was done that closes by announcing the next step and has no tool call, so the next thing never starts. Two: an offer to carry on with something unless the user would prefer otherwise, which stops to wait for an answer the user was not going to give. Three: a list of decisions for the user when, by your own account, none of them blocks the rest of the work. Four: deciding that this is a good place to report, because the turn has been long or a milestone is done. Status notes are welcome, and so are your recommendations on open decisions, but put them in the same message as your next tool call and carry on with whatever does not depend on the user's answer. If you notice yourself inviting the user to redirect you or offering to wait, delete it and do the next thing. The stops the user does want are the ones where nothing can move without them, or where the thing blocking you is deliberately protected from you. This does not override the need for confirmation on risky or destructive actions.
- Update the keybindings listing (Super + /) every time a keybinding is added or changed.
- Don't write tests: the user runs the required commands and verifies. `tests/run` must still pass.
- **Check every change in [desktop-vm](docs/apps/desktop-vm.md) before calling it done**, never in
  the live session (no second mango, no locker such as hyprlock, no reloading the user's apps to
  test): `desktop-vm up` installs the working tree in a VM, reboots and records the boot;
  `desktop-vm check` logs in at the greeter
  and runs `tests/run` in that session (PASS/FAIL, `verdict.json`). Look at what you changed: the
  run directory's `boot-*.png`, `greeter.png`, `session.png`, and `desktop-vm shot` / `keys` /
  `exec` for anything else. `desktop-vm down` when done: the VM pauses CI while it runs. If starting
  it is blocked (it stops `runner-up.service`), ask the user to run `desktop-vm up`.
- **Every install and configuration, new or updated, goes through the repo**: programs in
  `<app>/packages` or `<app>/pkg/`, files as dot-entries or under `root/`, the rest in `setup.sh`.
  No one-off manual steps, no migration code: a one-time fix on this machine is done by hand
  once, not kept in a script. Scripts stay idempotent (act only on a difference; a second `install.sh` run changes
  nothing) and reproducible: a clean Arch VM running `install.sh` must end up with the same desktop
  (CI runs bootstrap.sh on a fresh VM on every push).
- **Docs move with the code.** A new or changed app means, in the same commit: its folder, its
  `packages`, its `docs/apps/<app>.md` (hand-written part), `tools/docs` (regenerates the reference
  blocks), and `tools/docs --snapshot` when packages changed. `tools/docs --check` must pass.
- **Never write a color literal in a config.** Colors come from `theme/palettes/*.toml` through
  `<app>/**/NAME.tmpl` templates (`{{role|filter}}`) rendered in place to `NAME`; list `NAME` in the
  app's `.gitignore`. Scripts read `THEME_*` from `~/.config/theme/colors.sh`. `theme lint` must pass.
- **Never commit secrets** (an app's `service.json` or `auth.json`, tokens, keys). `theme lint` flags known names.
- **Agents have no sudo** (it asks for a password). Never ask for the password or pipe one into
  `sudo -S`. Put the root work in the repo (`packages`, `root/`, `setup.sh`), give the user one
  `! <command>` line to run (usually `./install.sh`), and carry on with what doesn't need root.
- **Apps write to linked configs.** Claude Code rewrites `claude/.claude/settings.json` through the
  link (`*@synced` plugin entries, `/effort` and `/model` changes, key reordering). Before committing
  it, review `git diff` and keep only changes the user decided on.
- **Session daemons are user units** with `PartOf=`/`After=`/`Requisite=graphical-session.target`
  and `WantedBy=graphical-session.target`, in the app's `.config/systemd/user/`. No `exec_once`,
  no `dbus-update-activation-environment`. hyprlock stays guarded by `pidof -q hyprlock ||` and
  swayidle keeps `KillMode=process`. Never `systemctl --user disable`/`reenable` a repo unit:
  systemd deletes a linked unit file on disable (install.sh --link restores it).
- Env vars: `mango/.config/mango/env.conf` for mango's children, `mango/.config/environment.d/` for
  units; a variable both need goes in both.
- Git: work on a branch and merge to `main`; push to `origin` (github.com/T-450/dotfiles, public:
  never commit secrets) only when the user asks for it in the session. `upstream` is
  DreamMaoMao's repo and is never pushed to. No PRs. Never skip git hooks (`--no-verify`,
  `-c core.hooksPath=...`). Delete a branch once it is merged; a branch dropped unmerged is
  deleted too, with its reason in the report.
- Never add a `Co-Authored-By` trailer or share an agent session (link or ID) in commits, issues,
  comments or anything else sent to another service.

## Engineering directives

Optimize for correctness, minimal surgical changes and fast execution. On any conflict with the
rules above (no tests, merge to `main`, no PRs, turn endings, desktop-vm), the rules above win.

### Workflow

- `using-superpowers` is the meta-skill where installed. These directives govern without it; load a
  skill's `SKILL.md` only when its domain guidance is needed.
- Line 1 of a non-trivial reply names the posture: `> [Active: brainstorming, ponytail]` (feature,
  plan), `systematic-debugging` (bug, trace), `test-driven-development` (implementation: here a
  reproduction, not a test file), `verification-before-completion, requesting-code-review` (review,
  completion), `ponytail` alone (Q&A, exploration).
- **Spike** (feasibility): one cheap probe, then the finding and a recommendation in 2-3 sentences.
- **Bounded** (bugfix, 1-3 file additive change): trace the root cause, reproduce, minimal change,
  targeted verification. Autonomous.
- **Architectural** (new app or subsystem, changes to install.sh/theme/bootstrap/CI contracts):
  brainstorm, spec approval, plan, plan approval, adversarial plan review in fresh context,
  implement, diff-grounded readiness review, verification, branch finish. When a step needs a
  user-supplied prompt (planning, plan review, readiness review), ask for it instead of improvising.
- Track bounded work with an inline `- [ ]` checklist; architectural work with one per milestone.

### Approval gate

Ask first for: architectural changes and new apps; a new package or `pkg/` PKGBUILD (installed
tools run freely); changes to bootstrap.sh, CI or `root/` system files; destructive operations
(`rm -rf`, `git reset --hard`, `git clean -fd`, deleting unmerged work). Everything else runs
autonomously: read-only exploration, bounded fixes, additive changes, running `tests/run`.

### Ponytail constraints

- Ladder: YAGNI, then existing repo scripts and helpers, stdlib, native platform, installed
  packages, then the minimum new code.
- Think before coding: state assumptions, surface tradeoffs, push back when something simpler exists.
- Surgical: every changed line traces to the request; no reformatting or refactoring next to it.
- Fix the root cause where callers route through, not the symptom.
- Delivery: `[change] → skipped: [X], add when [Y].`
- Arithmetic (contrast ratios, sizes, timings) comes from code, never from mental math in text.

### Verification and recovery

- No harness for a behavior: a standalone reproduction or CLI command showing before and after
  (scratchpad, not a committed test). Config: dry-runs and validators (`mango -p`,
  `ghostty +validate-config`, `theme lint`), not exit code 0 alone.
- Never claim "passes" or "fixed" without fresh output from this turn.
- When verification fails: stop cascading edits, find whether the cause, the change, the check or
  the environment is wrong, form one hypothesis, make one minimal adjustment, re-verify.
- Review the diff (spec compliance, scope creep, unrelated edits) before merging to `main` and after
  each subagent task.

### Communication

- Lead with the answer: command, `file_path:line`, snippet or finding.
- Number multi-step work; at most 5 bullets per list; `Step X of Y` only for real multi-step tasks.
- No filler, time estimates or closers.

### Coding guidelines

1. Good taste removes special cases: when the edge case folds into the normal path, the design is
   right. Many `if` branches for edge cases mean the design is wrong.
2. Data structures first; the right layout makes the code obvious.
3. Short functions, shallow indentation: three or four levels deep means split it.
4. Honest names: short for short-lived locals, descriptive for anything global; no types in names.
5. Comments explain why; if code needs a what-comment, rewrite the code. The full story goes in the
   commit message.
6. Never break users: whoever depends on an interface (a command's flags or output, a file format,
   a keybinding, behavior) is a user, even when they were "doing it wrong".
7. No abstractions for imaginary futures; refactor when the second real user appears.
8. Details over vision: error paths, lifetimes and performance are where the bugs live.
9. One logical change per commit, with a message that says why; too big to review is too big to merge.
10. Understand everything you submit, whatever wrote it.
11. Own mistakes, remove bad code without ego, accept pushback; attack the code, not the person.

## Validating changes

```bash
desktop-vm up && desktop-vm check           # every change: VM boot, greeter, session, tests/run
desktop-vm shot; desktop-vm down            # look at a frame; stop the VM (CI resumes)
theme lint                                  # colors, gitignored renders, secrets
tools/docs --check                          # docs in step with the repo
tests/run                                   # unit tests (CI runs them too)
theme set "$(theme current)"                # re-render + reload after editing a template
./install.sh --check                        # home and system files match the repo
./install.sh --link                         # after adding a file to an app folder
mango -c ~/.config/mango/config.conf -p && echo ok
systemctl --user --failed; journalctl --user -b -u <unit>
```

## Conventions

- Shell scripts: `#!/usr/bin/env bash` (or `/usr/bin/bash`), tabs, a header comment with the usage
  line. Commands in `.local/bin/` have no `.sh` suffix.
- `osd-brightness` has two verb pairs on purpose: `up`/`down` (keys) show the OSD, `bup`/`bdown`
  (bar scroll) use plain brightnessctl at 1% steps.
- Comments explain _why_ (hardware quirks, e.g. thermald unsupported on this T14). Keep that style.

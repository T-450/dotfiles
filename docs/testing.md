# Testing and CI

Modeled on [Omarchy](https://github.com/basecamp/omarchy)'s `test/` (`docs/testing.md` there):
plain bash, TAP-style lines, one file per area, a runner that keeps going past failures.

```bash
tests/run                       # every tests/unit.d/*-test.sh
tests/run tests/unit.d/theme-test.sh
tools/docs --check              # docs/ in step with the repo
tools/docs --drift              # this machine's packages vs every <app>/packages
```

## Writing a test

`tests/unit.d/<area>-test.sh`, picked up by name:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_command ghostty
scratch_home                     # HOME=<fresh dir>, XDG_* unset: nothing reaches the real home
...
pass "what held"                 # ok - what held
```

- `fail "desc" [detail]` prints `not ok - desc` and **ends the file**: later checks would only
  report against state the failure already broke. `tests/run` goes on with the next file and
  prints each failing file's log; logs stay in the directory it prints.
- `skip "why"` for checks this machine can't run; `require_session` skips the whole file unless a
  live mango session answers `mmsg` (session checks pass in CI's VM only when it starts one).
- Tests never touch the real home: `scratch_home`, `install.sh --home DIR`, `theme init --to DIR`.
- Tests never change the checkout either. Templates render in place and your live configs link to
  those renders, so a test that renders or installs works on a copy (`cp -r "$ROOT"`; see
  `system-test.sh`). `tests/run` hashes the checkout around each file and fails a file that
  changed it.

## CI: a clean machine on every push

`.github/workflows/tests.yml` runs on [runner-up](apps/runner-up.md): GitHub Actions jobs in a
**fresh Arch Linux KVM VM per job** (Arch's official cloud image), on this laptop. The job runs
`install.sh` on the clean VM, runs it again and fails if the second run changes anything, then runs
`tests/run`. That is the proof that the repo reproduces the desktop from scratch.

The job also prints the toolchain's versions (`mise -C / ls --global`) and runs `tests/run` under
`mise exec`, so the tests see the toolchain. Auto-install is off there, so a missing tool fails a
test instead of being installed without the lockfile. The two install steps get the workflow's
read-only token as `MISE_GITHUB_TOKEN`, so mise's GitHub API calls don't share the anonymous rate
limit of every VM behind this laptop's IP.

`toolchain-test.sh` checks on every machine that `config.toml`, `mise.lock` and `locks/` agree. On
the installed checkout, it also checks that every locked tool is installed, that a clean zsh finds
each tool in its install directory and not through a shim, that `helix --health` finds every
language's servers, and that `mise/` has no uncommitted change.

`runs-on: arch-kvm` is the pool label. The coordinator (`runner-up.service`) uses `gh`'s
sign-in, so `gh auth login` must have run; `runner-up status` shows the place and waiting jobs.

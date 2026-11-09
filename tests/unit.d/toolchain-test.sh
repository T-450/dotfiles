#!/usr/bin/env bash
# the toolchain mise/.config/mise/ declares. Everywhere: config.toml, mise.lock and locks/ agree.
# On the installed checkout: every locked tool is installed, resolves in a clean interactive zsh
# (not through a shim), helix finds each language's servers, and installing left mise/ unchanged.
set -euo pipefail
# a test never installs: a missing tool must fail, not be installed into the real home
export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

out=$(python3 -I - "$ROOT/mise/.config/mise" <<'PY'
import re
import sys
import tomllib
from pathlib import Path

d = Path(sys.argv[1])
config = tomllib.loads((d / "config.toml").read_text())
entries = tomllib.loads((d / "mise.lock").read_text()).get("tools", {})
# a tool's request: "1.2", {version = "1.2", ...}, or a list of those (several versions installed)
requests = {k: [r if isinstance(r, str) else r["version"] for r in (v if isinstance(v, list) else [v])]
            for k, v in config.get("tools", {}).items()}
locked = [(k, e) for k, es in entries.items() for e in es]
tables = [(k, p, t) for k, e in locked for p, t in [("", e), *e.items()] if isinstance(t, dict)]
refs = {t["path"] for _, _, t in tables if "path" in t and "digest" in t}
dirs = {p.relative_to(d).as_posix() for p in d.glob("locks/*/*") if p.is_dir()}
settings = config.get("settings", {})
checks = {
    "requested in config.toml, no exact version in mise.lock":
        [f"{k}@{r}" for k, rs in requests.items() for r in rs
         if not any(r in e.get("specifiers", []) and e.get("version") for e in entries.get(k, []))],
    "in mise.lock, not requested in config.toml": sorted(set(entries) - set(requests)),
    "platforms other than linux-x64 (and its CPU variants)":
        [f"{k} {p}" for k, e in locked for p in e
         if p.startswith("platforms.") and not re.fullmatch(r"platforms\.linux-x64(-[a-z0-9-]+)?", p)],
    "downloads without a sha256 or blake3 checksum":
        [f"{k} {p}".strip() for k, p, t in tables
         if "url" in t and not t.get("checksum", "").startswith(("sha256:", "blake3:"))],
    "backends outside core, aqua, github, npm, go, dotnet":
        [f"{k} {e.get('backend')}" for k, e in locked
         if e.get("backend", "").partition(":")[0] not in {"core", "aqua", "github", "npm", "go", "dotnet"}],
    "sidecars mise.lock references that locks/ lacks": sorted(refs - dirs),
    "sidecars in locks/ that mise.lock doesn't reference": sorted(dirs - refs),
    "settings missing (minimum_release_age = 24h, asdf and vfox disabled)":
        [k for k, ok in [("minimum_release_age", settings.get("minimum_release_age") == "24h"),
                         ("disable_backends", {"asdf", "vfox"} <= set(settings.get("disable_backends", [])))]
         if not ok],
}
bad = [f"{what}: {', '.join(keys)}" for what, keys in checks.items() if keys]
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
) || fail "config.toml, mise.lock and locks/ agree" "$out"
pass "config.toml, mise.lock and locks/ agree"

installed=$(realpath -m "$HOME/.config/mango/config.conf" 2>/dev/null || true)
if [[ $installed != "$ROOT"/* ]]; then skip "installed toolchain: this checkout isn't the installed one"; exit 0; fi
require_command mise

out=$(cd / && mise ls --global --missing --no-header 2>&1) && [[ -z $out ]] || fail "every locked tool is installed" "$out"
pass "every locked tool is installed"

for lang in go rust typescript tsx javascript jsx json jsonc python zig c cpp c-sharp java bash toml yaml markdown; do
	out=$(mise -C / exec -- helix --health "$lang" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' |
		sed -n '/^Configured language servers:/,/^Tree-sitter parser:/p') || fail "helix --health $lang runs" "$out"
	# javascript's adapter named '' is helix's own entry, not a tool to install
	bad=$(grep '✘' <<<"$out" | if [[ $lang == javascript ]]; then grep -v "✘ '' not found"; else cat; fi || true)
	[[ -z $bad ]] || fail "helix --health $lang: language servers, formatter and debugger found" "$bad"
done
pass "helix --health: every language's servers, formatter and debugger found"

real=$HOME
scratch_home
# zsh reads the real ~/.zshrc and mise the real config and installs; everything they write goes
# to the scratch home
out=$(env -i HOME="$HOME" ZDOTDIR="$real" PATH=/usr/bin:/bin TERM=dumb ZSH_COMPDUMP="$TEST_TMP/zcompdump" \
	MISE_CONFIG_DIR="$real/.config/mise" MISE_DATA_DIR="$real/.local/share/mise" \
	MISE_STATE_DIR="$TEST_TMP/mise-state" MISE_CACHE_DIR="$TEST_TMP/mise-cache" \
	RUSTUP_HOME="$real/.rustup" CARGO_HOME="$real/.cargo" MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0 \
	zsh -i -c 'for n; do print -r -- "$n $(whence -p "$n")"; done; print -r -- "telemetry $DOTNET_CLI_TELEMETRY_OPTOUT"' zsh \
	go cargo rustc rustup node npm pnpm bun tsc uv uvx zig dotnet java javac gradle cmake ninja meson \
	cc c++ clang clang++ lldb-dap python3 2>"$TEST_TMP/zsh.err") || fail "a clean interactive zsh starts" "$(cat "$TEST_TMP/zsh.err")"
bad=$(awk '$1 != "telemetry" && ($2 == "" || $2 ~ "/mise/shims/") {print $1, $2 ? "resolves through a shim" : "not found"}' <<<"$out")
[[ -z $bad ]] || fail "a clean zsh resolves every tool from its install dir" "$bad"
pass "a clean zsh resolves every tool from its install dir"
grep -qx 'python3 /usr/bin/python3' <<<"$out" || fail "python3 stays the system's" "$(grep '^python3' <<<"$out")"
pass "python3 is /usr/bin/python3"
grep -qx 'telemetry 1' <<<"$out" || fail "DOTNET_CLI_TELEMETRY_OPTOUT is 1 in a clean zsh" "$(grep '^telemetry' <<<"$out")"
pass ".NET telemetry is off"

out=$(git -C "$ROOT" status --porcelain -- mise/)
[[ -z $out ]] || fail "mise/ matches the last commit (no mise use -g or upgrade left uncommitted)" "$out"
pass "mise/ matches the last commit"

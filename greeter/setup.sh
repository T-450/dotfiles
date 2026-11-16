#!/usr/bin/env bash
# greeter/setup.sh: start greetd at boot (its files come from greeter/root/ via install.sh --system),
# draw the host name as the login screen's art, and give sysc-greet the Blue Dawn loop (pkg
# wallpaper-cosmic-storm, swaybg/) as its background: a link in its custom wallpaper folder, played
# by gslapper, and two keys in its preferences, `wallpaper` (that file) and `form_mode` frosted (a
# blurred, dimmed plate behind the login form, so its small text reads over the clouds). sysc-greet
# rewrites the preferences file when you change something at the login screen, so only these keys
# are set, when they differ. The file is the greeter's own (0600 in its home), so even the check
# needs sudo: one call, which writes only on a difference.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
enable_system greetd.service

# the login screen's art: this machine's host name (root/etc/greetd/greeter-hostname-art, also run
# by a pacman hook after each sysc-greet-mango update); the check needs no root
art=/etc/greetd/greeter-hostname-art
[[ -x $art ]] && { "$art" --check || sudo "$art"; }

dawn=/usr/share/backgrounds/cosmic-storm/blue-dawn.mp4
walls=/var/lib/greeter/Pictures/wallpapers
[[ -r $dawn ]] || exit 0
if [[ $(readlink -- "$walls/blue-dawn.mp4" 2>/dev/null) != "$dawn" ]]; then
	sudo install -d -o greeter -g greeter -m 755 "$walls"
	sudo ln -sfn -- "$dawn" "$walls/blue-dawn.mp4"
	echo "link    $walls/blue-dawn.mp4 -> $dawn"
fi
sudo python3 -I - <<'EOF'
import json, os, pwd
from pathlib import Path

want = {"wallpaper": "blue-dawn.mp4", "form_mode": "frosted"}
greeter = pwd.getpwnam("greeter")
cache = Path(greeter.pw_dir) / ".cache" / "sysc-greet"
path = cache / "preferences"
try:
    prefs = json.loads(path.read_text())
except (FileNotFoundError, ValueError):
    prefs = {}
changed = [k for k, v in want.items() if prefs.get(k) != v]
if changed:
    prefs.update(want)
    cache.mkdir(parents=True, exist_ok=True)
    for d in (cache.parent, cache):
        os.chown(d, greeter.pw_uid, greeter.pw_gid)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(prefs, indent=2) + "\n")
    os.chown(tmp, greeter.pw_uid, greeter.pw_gid)
    os.chmod(tmp, 0o600)
    tmp.replace(path)
    for k in changed:
        print(f"config  sysc-greet {k}")
EOF

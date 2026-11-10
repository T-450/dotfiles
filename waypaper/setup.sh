#!/usr/bin/env bash
# waypaper/setup.sh: the waypaper settings this desktop needs, in ~/.config/waypaper/config.ini:
# pictures from ~/Pictures/Wallpapers and ~/.config/swaybg (the palette's own), and each pick
# handed to wallpaper-set (swaybg/) instead of a backend of waypaper's. waypaper rewrites the whole
# file on every pick, so the repo can't link it: only these keys are set, when they differ.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
[[ -d $HOME/Pictures/Wallpapers ]] || { mkdir -p "$HOME/Pictures/Wallpapers" && echo "mkdir   ~/Pictures/Wallpapers"; }
python3 -I - "$HOME/.config/waypaper/config.ini" <<'EOF'
import configparser, sys
from pathlib import Path

path = Path(sys.argv[1])
want = {
    "folder": ["~/Pictures/Wallpapers", "~/.config/swaybg"],
    "backend": "none",  # waypaper sets nothing itself, it only runs post_command
    "post_command": "~/.local/bin/wallpaper-set $wallpaper",
}


def lines(value):  # waypaper writes folder as "a\n     b", so values compare by their stripped lines
    text = value if isinstance(value, str) else "\n".join(value)
    return [line.strip() for line in text.splitlines() if line.strip()]


config = configparser.ConfigParser(interpolation=None)
config.read(path, encoding="utf-8")
if not config.has_section("Settings"):
    config.add_section("Settings")
settings = config["Settings"]
changed = [key for key, value in want.items() if lines(settings.get(key, "")) != lines(value)]
for key in changed:
    settings[key] = "\n".join(lines(want[key]))
    print(f"config  waypaper {key}")
if changed:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        config.write(f)
EOF

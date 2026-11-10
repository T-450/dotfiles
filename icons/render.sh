#!/usr/bin/env bash
# icons/render.sh: Tela-mango, the Tela icon theme in the palette's accent, made in
# .local/share/icons/Tela-mango (linked into your home). It holds only Tela's blue icons (folders,
# places, some apps; devices turn grey), recolored the way Tela's installer makes its variants,
# plus the links that point at them; it inherits the rest from Tela-dark or Tela-light, by the
# palette's variant (pkg/tela-icon-theme-standard). Run by `theme` after rendering templates;
# remade only when its inputs changed. TELA_DIR=dir reads the base themes from dir.
set -euo pipefail
cd "$(dirname "$0")"
colors=../theme/.config/theme/colors.sh
out=.local/share/icons/Tela-mango
stamp=render.stamp # sha256 of what the theme is made from
. "$colors"
base=${TELA_DIR:-/usr/share/icons}/Tela-$THEME_VARIANT
if [[ ! -d $base ]]; then
	echo "skip    icons: no $base (install.sh --packages)" >&2
	exit 0
fi
inputs=$({ echo "$THEME_ACCENT $THEME_VARIANT $base"; pacman -Q tela-icon-theme-standard 2>/dev/null || true; cat "$0"; } | sha256sum | cut -d' ' -f1)
[[ -f $out/index.theme && $(cat "$stamp" 2>/dev/null) == "$inputs" ]] && exit 0

python3 - "$base" "$out" "$THEME_ACCENT" "$THEME_VARIANT" "$THEME_FG_MUTED" "$THEME_SELECTION_FG" <<'EOF'
import os, re, shutil, sys, tempfile
base, out, accent, variant, grey, white = sys.argv[1:]
# Tela's own color, as its folder icon declares it (.ColorScheme-Highlight { color: ... })
folder = open(os.path.join(base, "scalable/places/default-folder.svg"), encoding="utf-8").read()
blue = re.search(r"\.ColorScheme-Highlight\s*\{\s*color:\s*(#[0-9a-fA-F]{6})", folder).group(1)
dirs = ("scalable/apps", "scalable/places", "scalable/devices", "16/places", "32/devices")
os.makedirs(os.path.dirname(out), exist_ok=True)
tmp = tempfile.mkdtemp(prefix=".Tela-mango.", dir=os.path.dirname(out))
made = {}  # real path of a base icon -> its recolored copy

def recolor(text, d):
    # what Tela's install.sh does for a color other than its standard one
    if d.endswith("devices"):
        return text.replace(blue, grey)
    lines = []
    for line in text.replace(blue, accent).split("\n"):
        if "ColorScheme-Highlight" in line:
            line = line.replace("currentColor", accent, 1)
        elif "ColorScheme-Background" in line and d == "scalable/places":
            line = line.replace("currentColor", white, 1)
        lines.append(line)
    return "\n".join(lines)

try:
    listing = {d: sorted(os.scandir(os.path.realpath(os.path.join(base, d))), key=lambda e: e.name) for d in dirs}
    for d, entries in listing.items():
        os.makedirs(os.path.join(tmp, d))
        for e in entries:
            if e.name.endswith(".svg") and e.is_file(follow_symlinks=False):
                text = open(e.path, encoding="utf-8").read()
                if blue in text or re.search(r"ColorScheme-(Highlight|Background)", text):
                    dest = os.path.join(tmp, d, e.name)
                    open(dest, "w", encoding="utf-8").write(recolor(text, d))
                    made[os.path.realpath(e.path)] = dest
    links = 0
    for d, entries in listing.items():  # icon names that are links to a recolored icon
        for e in entries:
            target = made.get(os.path.realpath(e.path)) if e.is_symlink() else None
            if target:
                here = os.path.join(tmp, d)
                os.symlink(os.path.relpath(target, here), os.path.join(here, e.name))
                links += 1
    index = open(os.path.join(base, "index.theme"), encoding="utf-8").read()
    index = re.sub(r"(?m)^Name=.*$", "Name=Tela Mango", index)
    index = re.sub(r"(?m)^Inherits=.*$", f"Inherits=Tela-{variant},hicolor", index)
    open(os.path.join(tmp, "index.theme"), "w", encoding="utf-8").write(index)
    shutil.rmtree(out, ignore_errors=True)
    os.rename(tmp, out)
except BaseException:
    shutil.rmtree(tmp, ignore_errors=True)
    raise
print(f"render  icons/{out} ({len(made)} icons in {accent} and {links} links, over Tela-{variant})")
EOF
echo "$inputs" >"$stamp"

#!/usr/bin/env bash
# keybindings: the leader tree in bind.conf resolves, and the cheatsheet's search (mango-keys --rank)
# puts the expected row first for exact, partial, misspelled, synonym and key queries.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"
require_command python3
scratch_home
conf=$ROOT/mango/.config/mango/bind.conf
keys=$ROOT/mango/.local/bin/mango-keys
# the palette the views draw with
"$ROOT/theme/.local/bin/theme" init dark-2026 --to "$TEST_TMP/r" >/dev/null
export MANGO_KEYS_COLORS=$TEST_TMP/r/theme/.config/theme/colors.sh

# every mode is opened from somewhere and binds Escape; every one-shot ends with setkeymode,default
out=$(python3 - "$conf" <<'PY'
import re, sys
modes, opened, esc, mode, prev = set(), set(), set(), "default", None
for n, line in enumerate(open(sys.argv[1]), 1):
    line = line.strip()
    if line.startswith("key_mode="):
        mode = line.split("=", 1)[1]
        modes.add(mode)
    m = re.match(r"(bind[slrpc]*)=([^,]*),([^,]*),([^,]*),?(.*)", line)
    if not m:
        continue
    kind, mods, key, action, arg = m.groups()
    if action == "setkeymode":
        opened.add(arg)
    if key == "Escape" and action == "setkeymode" and arg == "default":
        esc.add(mode)
    if "c" in kind[4:] and action != "setkeymode":
        prev = (n, mode, mods, key)
    elif "c" in kind[4:]:
        if not prev or prev[1:] != (mode, mods, key):
            print(f"line {n}: a one-shot's setkeymode,default follows no action on {mods}+{key}")
        prev = None
    elif prev:
        print(f"line {prev[0]}: one-shot on {prev[2]}+{prev[3]} has no setkeymode,default after it")
        prev = None
for m in sorted(modes - {"default", "common"}):
    if m not in opened:
        print(f"mode {m}: nothing opens it")
    if m not in esc:
        print(f"mode {m}: no Escape bind (keys it doesn't bind reach apps)")
for m in sorted(opened - modes - {"default"}):
    print(f"setkeymode,{m}: no key_mode={m} block")
PY
)
[[ -z $out ]] || fail "the leader tree resolves" "$out"
pass "leader tree: every mode is opened, binds Escape, one-shots return to default"

# query <TAB> expected first row (a|b: either is right)
out=$(MANGO_KEYS_CONF=$conf PYTHONDONTWRITEBYTECODE=1 python3 - "$keys" <<'PY'
import sys
from importlib.machinery import SourceFileLoader
mk = SourceFileLoader("mk", sys.argv[1]).load_module()
rs = mk.rows()
corpus = """
fullscreen	Fullscreen
full	Fullscreen
fulscr	Fullscreen
fullsrceen	Fullscreen
fullscren	Fullscreen
ful screen	Fullscreen
fake full	Fullscreen inside the tile
close	Close window
clsoe	Close window
kill	Force kill
quit	Close window
force kill	Force kill
lock	Lock screen
lcok	Lock screen
lock scren	Lock screen
terminal	Terminal (Ghostty)
termnial	Terminal (Ghostty)
term	Terminal (Ghostty)
shell	Dropdown terminal: a persistent shell; Alt+Esc hides it
dropdown	Dropdown terminal: a persistent shell; Alt+Esc hides it
float term	Floating terminal: a throwaway window
browser	Browser (Firefox)
firefox	Browser (Firefox)
browsr	Browser (Firefox)
web	Browser (Firefox)
files	File manager (Thunar)
thunar	File manager (Thunar)
file manger	File manager (Thunar)
clipboard	Clipboard history
clipbaord	Clipboard history
paste	Clipboard history
wallpaper	Wallpaper picker (waypaper)
walpaper	Wallpaper picker (waypaper)
theme	Theme picker
colors	Theme picker
screenshot	Screenshot of the screen
screenshot screen	Screenshot of the screen
screnshot region	Screenshot of a region
record	Start/stop screen recording
recrod	Start/stop screen recording
video	Start/stop screen recording
volume up	Volume up
volume dwn	Volume down
mute mic	Mute the microphone
brightness	Brightness up
brigthness down	Brightness down
notifications	Notifications ▸
dismiss	Dismiss all notifications
do not disturb	Do not disturb on/off
dnd	Do not disturb on/off
log out	Log out
logout	Log out
power	Power menu
shutdown	Power menu
reboot	Power menu
reload	Reload mango's config
bar	Show/hide the bar
waybar	Show/hide the bar
float	Float/tile
floating	Floating terminal: a throwaway window|Center the floating window|Float/tile
maximize	Maximize
maximise	Maximize
on top	Keep on top
pin	Pin to all tags
sticky	Pin to all tags
minimize	Minimize
restore	Restore a minimized window
scratchpad	Show/hide minimized windows
resize	Resize ▸|Resize a window
wider	Wider
monocle	Monocle
monocel	Monocle
scroller	Scroller
scrolelr	Scroller
grid	Grid
tile	Tile|Float/tile
next layout	Next layout
master	Swap with master
more master	More master windows
focus left	Focus left
focus rigth	Focus right
move window left	Move window left
next tag	Next tag
previous tag	Previous tag
tag 3	Show tag
move to tag	Move window to tag
workspace	Show tag
all tags	Show all tags
monitor	Monitor ▸
laptop panel	Laptop panel on/off
launcher	App launcher
app launcher	App launcher
cheatsheet	Keybindings (this cheatsheet)
help	Keybindings (this cheatsheet)
super f	Fullscreen
super d	App launcher
super enter	Terminal (Ghostty)
space w	Window ▸
space w f	Fullscreen inside the tile
leader	Leader: every other group
alt tab	Jump to a window by its hint
overview	Overview, cycle windows|Overview
drag	Drag a window
swipe	Previous tag with windows|Next tag with windows|Overview|Leave overview
zzqx	-
"""
for line in corpus.strip().splitlines():
    q, want = line.split("\t")
    got = mk.rank(q, rs)
    top = rs[got[0][0]]["desc"] if got else "-"
    if top not in want.split("|"):
        print(f"{q!r}: first row {top!r}, want {want!r}")
PY
)
[[ -z $out ]] || fail "search puts the expected row first" "$out"
pass "search: exact, partial, misspelled, synonym and key queries"

# the views fzf and the popup use render without error
MANGO_KEYS_CONF=$conf "$keys" --rank 'fulscr' | sed 's/\x1b\[[0-9;]*m//g' | grep -q 'Super.*Fullscreen' || fail "--rank lists rows"
MANGO_KEYS_CONF=$conf "$keys" --card 0 | grep -q 'F O C U S' || fail "--card draws a group"
MANGO_KEYS_CONF=$conf "$keys" --pango window | grep -q 'Keep on top' || fail "--pango draws a mode"
pass "rank, card and popup views render"

# fzf takes the cheatsheet's options (an unknown flag or color name exits 2 and the window closes)
if command -v fzf >/dev/null; then
	out=$(MANGO_KEYS_CONF=$conf PYTHONDONTWRITEBYTECODE=1 python3 - "$keys" <<'PY'
import os, subprocess, sys
from importlib.machinery import SourceFileLoader
mk = SourceFileLoader("mk", sys.argv[1]).load_module()
args = []
os.execvp = lambda f, a: args.extend(a)
mk.tui()
rows = subprocess.run([sys.argv[1], "--rank", ""], capture_output=True, text=True).stdout
r = subprocess.run([a for a in args if a != "--disabled"] + ["--filter", "Fullscreen"], input=rows,
                   capture_output=True, text=True)
if r.returncode != 0 or not r.stdout:
    print(f"fzf exit {r.returncode}: {r.stderr.strip()}")
PY
)
	[[ -z $out ]] || fail "fzf takes the cheatsheet's options" "$out"
	pass "fzf takes the cheatsheet's options"
else skip "fzf not installed"; fi

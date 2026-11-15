# Keybindings: modifier layers, and a keycap cheatsheet

Design for the keybinding layout in `mango/.config/mango/bind.conf`, the which-key popup and the
`mango-keys` cheatsheet (super+/). Status: implemented.

## Goals

- **The modifier names the group, the key names the action**, pressed together in one chord:
  super = go and open, super+shift = carry the focused window, super+alt = window state,
  super+ctrl = layout and view, Print = capture. Seeing the modifier tells you the group.
- One step for almost everything. Only rare actions (session, notifications, monitors) take two:
  super+key opens a key mode, the next key acts.
- Plain alt, ctrl+alt and ctrl+shift stay with apps: zsh's word motions and alt+., helix's alt
  commands, Firefox's alt+left/right. Only alt+esc (dropdown) and alt+tab (jump hints) are mango's.
- One bind per action. No fullscreen key: maximize covers it, and fullscreen was unwanted.

History, in order: (1) a super+space leader with group letters (super+space w m: three steps for
maximize); (2) super+letter group modes (super+w m: two steps, but super prefixed everything and
named nothing); (3) these modifier layers.

## Model

| layer | keys |
|---|---|
| super: go/open | h/j/k/l focus · 1..9 view tag · left/right previous/next tag · tab overview cycle · o overview · u previous window · return terminal · shift+return floating terminal · d launcher · b browser · e files · v clipboard · w wallpaper · p theme · / cheatsheet |
| super+shift: carry | h/j/k/l move · 1..9 send to tag · left/right carry to previous/next tag · q close |
| super+alt: window | m maximize · t float/tile · c center · z minimize · shift+z restore · s show/hide minimized · o on top · p pin · h/j/k/l resize (repeats) · q force kill |
| super+ctrl: layout/view | space next layout · t tile · s scroller · m monocle · g grid · d deck · z swap with master · = / - masters · w scroller widths · [ / ] scroller stack · 1..9 add tag to view · shift+1..9 add window to tag · left/right tag with windows · tab previous tags · a all tags |
| Print: capture | Print screen · shift+Print region · ctrl+Print record |
| two steps | super+esc session: l lock · e log out · p power · r reload · b bar; super+n notifications: r restore · d dismiss all · z do not disturb; super+m monitor: h/l focus · shift+h/l send · p laptop panel |

alt+esc dropdown terminal and alt+tab jump hints stay; media keys and mouse drags are
unchanged. No touchpad gestures: every action has a key.

### mango mechanics (0.18.5, read from source)

- `key_mode=NAME` starts a block of binds for that mode; `setkeymode,NAME` switches. Binds in a
  mode stay in the mode, so a one-shot operation is two binds on the same key with the `c` flag
  (all matching binds fire, in order): the action, then `setkeymode,default`. `setkeymode` stops the
  chain, so it is always last. `reload_config` also stops a chain, so `s r` goes through
  `mmsg dispatch reload_config` after `setkeymode,default`.
- Keys a mode does not bind go to the focused app, and the mode stays. Every mode binds Esc.
- Modifiers must match exactly, so every action in a mode is bound twice, `NONE,key` and
  `SUPER,key` (super is often still down after super+key). The cheatsheet shows one row.
- Media and lock-screen keys sit under `key_mode=common`, so they work in every mode.
- `mmsg watch keymode` streams `{"keymode":"NAME"}`; Waybar 0.16 has a `mango/keymode` module.

## Which-key popup

`mango-whichkey`, a user unit (`graphical-session.target`), reads `mmsg watch keymode`. On any mode
but `default` it shows that mode's card as a mako notification (`app-name=mango-whichkey`:
bottom-center, no timeout, no history, monospace, Pango markup) and replaces it on the next mode;
on `default` it dismisses it. It is passive: mako never takes keyboard focus, so the mode keeps
every key. The card comes from `mango-keys --card MODE`, the same parser as the cheatsheet. Waybar's
`mango/keymode` shows the mode name while a mode is open.

## Cheatsheet (mango-keys)

A floating Ghostty window (`com.mitchellh.ghostty-keys`, 1582x930, centered) running fzf: exactly
155x41 cells of 10x22 px plus Ghostty's padding and mango's border, so no stray pixels are left over
(`rule.conf` shows the arithmetic).

- **One grid.** Keycaps never sit on consecutive lines: the list uses fzf's `--gap`, the card a
  blank line, the popup a thin spacer. Row pitch 44 px, cap 22 px, gap 22 px everywhere.
- **List.** Every row: the group name, the keycaps right-aligned in one shared field (so the action
  key always sits next to its description), a 2-cell gutter, the description. No header rows, so a
  group title can never sit alone at the bottom of the view; rows keep bind.conf's order. The
  selected row is a full-width bar. A footer names the layers (Super GO · OPEN, +Shift CARRY,
  +Alt WINDOW, +Ctrl LAYOUT), each in its group's hue.
- **Group card.** The preview pane shows the selected row's whole group, its rows on the same lines
  as the list's; a mode's rows read `› H` under the key that opens it. A group taller than the pane
  shows the rows around the selection.
- **Keycaps.** The keyboard's own colors (the palette's `[keycaps]`, NuPhy Air60 HE): modifiers in
  the black `key_mod` with a faint aluminium edge, the action key in the violet `key_accent`, a
  mode's opening key in the grey `key_cap`, white `key_legend`s; `+` and `›` in `key_frame`. Group
  names, the card title and the selection mark keep their group hues (`HUES`).
- **Color by purpose**, from the active palette, so every theme works and no literal is written.
  Matched characters: `key_amber`, bold. Empty search: "0/0" and a blank card.
- **Search.** fzf is the interface and reruns the search on every key press
  (`--disabled`, `change:reload`): `mango-keys --rank QUERY` scores rows and draws the match
  highlight. Each query word must match a row's group, description, keys or synonyms, best first:
  exact word, word prefix, substring, in-order letters (fzf-style, missing letters), then a typo
  (one edit, two for words of 7+ letters, adjacent swaps count as one). Key words work too:
  `super e`, `super ctrl space`. An empty query lists everything in group order. A row's synonyms
  (`close: kill quit exit`) are searchable but not shown.
- **Speed.** Rows are parsed once per bind.conf change into `$XDG_RUNTIME_DIR/mango-keys.json`;
  ranking is a few ms.
- Esc or Enter closes it. `mango-keys --print` prints the rows as plain text (docs, tests).

## Input devices

- Touchpad back on (`disable_trackpad=0`), no gestures bound. `drag_lock=0`: with drag
  lock a tap-drag stays held after the finger lifts until the next tap, a classic stuck drag.
- TrackPoint: the kernel logged `psmouse serio2: TrackPoint ... lost synchronization` twice this
  boot (kernel bug 209167, Elan TrackPoint on RMI4 pass-through; the psmouse reconnect resets a held
  button). That is too rare to explain frequent sticking, and mango's code drops no TrackPoint
  events, so the cause is not proven. Next time it sticks:
  `sudo libinput debug-events --device /dev/input/event14` (move, click, scroll) and the kernel log.

## Testing

- `tests/unit.d/keys-test.sh`: a corpus of queries (exact, partial, missing letter, wrong letter,
  swapped letters, synonyms, key words, multi-word, nonsense) against `mango-keys --rank`, each with
  its expected first row; the group modes resolve (every `setkeymode` target exists, every mode
  binds Esc, every one-shot ends with `setkeymode,default`); `mango -p` parses the config.
- desktop-vm: boot, greeter, session, tests/run; screenshots of the cheatsheet and the popup.

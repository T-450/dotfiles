# Keybindings: groups, a leader, and a keycap cheatsheet

Design for the keybinding layout in `mango/.config/mango/bind.conf`, the which-key popup and the
`mango-keys` cheatsheet (super+/). Status: implemented.

## Goals

- Every binding belongs to a group with one entry point, and the key after it names the operation
  by its word (`w f` = window, fullscreen-in-tile). One mental model for every action.
- The hot path stays one chord: focus, tags, terminal, launcher, close, fullscreen.
- Everything else sits behind a leader, so Alt and Ctrl+Alt go back to apps (Helix, Ghostty).
- One bind per action, as before. Keys apps own stay free: ctrl/alt+1..9, alt+left/right,
  ctrl+left/right, ctrl+shift/ctrl+alt+arrows, every click and wheel turn.

## Model

**Chords.** Super = go/look. +Shift = carry the focused window along. +Ctrl = add instead of switch.

| keys | action |
|---|---|
| super+h/j/k/l · +shift | focus · move the window that way |
| super+1..9 · +shift · +ctrl · +ctrl+shift | view tag · send window · add tag to view · add window to tag |
| super+left/right · +shift | previous/next tag · carry the window there |
| super+return · super+d · alt+esc | terminal · launcher · dropdown terminal |
| super+shift+q · super+f | close · fullscreen |
| super+tab · alt+tab · super+u | overview cycle · jump hints · previous window |
| super+/ · super+space | cheatsheet · leader |

Media, brightness and Print stay as they are (`bindl`), mouse drags and 4-finger swipes too.

**Leader.** super+space opens the `leader` key mode; a letter opens a group mode; a letter in the
group runs the operation and returns to `default` (one-shot). Shift+letter is the variant or the
opposite. Esc leaves any mode; super+space in the leader closes it. Group keys in the leader also
match with Super still held (super+space, then super+w works like w).

| group | keys |
|---|---|
| a apps | b browser · f files · t floating terminal · v clipboard · w wallpaper · p palette (theme) |
| w window | t float/tile · m maximize · f fullscreen in tile · o on top · p pin to all tags · c center · z minimize · shift+z restore · s show/hide minimized · shift+q force kill · r resize ▸ |
| w r resize | h/j/k/l shrink/grow width and height (repeats; sticky) · esc/return done |
| l layout | n next · t tile · s scroller · m monocle · g grid · d deck · z swap with master · = / - more/fewer masters · w scroller width cycle · [ / ] scroller stack left/right |
| t tag | tab previous tags · a all tags · n/p next/previous tag with windows |
| m monitor | h/l focus · shift+h/l send window · p laptop panel on/off |
| c capture | r region · s screen · v video record on/off |
| n notifications | r restore last · d dismiss all · z do not disturb |
| s session | l lock · e log out · p power menu · r reload · b bar |

### mango mechanics (0.18.5, read from source)

- `key_mode=NAME` starts a block of binds for that mode; `setkeymode,NAME` switches. Binds in a
  mode stay in the mode, so a one-shot operation is two binds on the same key with the `c` flag
  (all matching binds fire, in order): the action, then `setkeymode,default`. `setkeymode` stops the
  chain, so it is always last. `reload_config` also stops a chain, so `s r` goes through
  `mmsg dispatch reload_config` after `setkeymode,default`.
- Keys a mode does not bind go to the focused app, and the mode stays. Every mode binds Esc.
- Modifiers must match exactly, so mode binds are `NONE,key`; the leader's group keys are bound
  twice (NONE and SUPER) because super is often still down after super+space.
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

A floating Ghostty window (`com.mitchellh.ghostty-keys`, 1500x860, centered) running fzf.

- **List.** Every row: a group chip in the group's hue, the keycaps, the description. No header rows,
  so a group title can never sit alone at the bottom of the view; rows keep bind.conf's order.
- **Group card.** fzf's preview pane shows the whole group of the selected row: title, entry
  (`Super+Space › w`) and every key in it as a two-row keycap (legend over a darker skirt, after
  NuPhy Node's high-profile caps). Groups have at most 13 keys, so a card never scrolls.
- **Keycaps.** Rounded caps (Nerd Font round ends). Modifier caps: `bg_hover` toward `fg_muted`
  with a `fg_bright` legend. The final key: the group's hue with dark ink. Chords join with `+`,
  leader sequences with `›`.
- **Color by purpose**, from the active palette, so every theme works and no literal is written:
  window `ansi5` (purple), apps `success`, tag `ansi3` (gold), layout `ansi6` (cyan), monitor
  `ansi11` (orange), capture `error` (coral), notifications `ansi13` (violet), session `ansi1`
  (red), focus and the chords `fg_bright`, media `ansi4`, mouse `fg_muted`. Matched characters:
  `warning` (pale yellow), bold. Selected row: `bg_hover` bar with a marker in the group's hue.
  Blue is the input cursor only. `colors.sh` exports `THEME_ANSI0..15` for this.
- **Search.** fzf is the interface and reruns the search on every key press
  (`--disabled`, `change:reload`): `mango-keys --rank QUERY` scores rows and draws the match
  highlight. Each query word must match a row's group, description, keys or synonyms, best first:
  exact word, word prefix, substring, in-order letters (fzf-style, missing letters), then a typo
  (one edit, two for words of 7+ letters, adjacent swaps count as one). Key words work too:
  `super f`, `space w`. An empty query lists everything in group order. A row's synonyms
  (`close: kill quit exit`) are searchable but not shown.
- **Speed.** Rows are parsed once per bind.conf change into `$XDG_RUNTIME_DIR/mango-keys.json`;
  ranking is a few ms.
- Esc or Enter closes it. `mango-keys --print` prints the rows as plain text (docs, tests).

## Input devices

- Touchpad back on (`disable_trackpad=0`), so the 4-finger swipes work. `drag_lock=0`: with drag
  lock a tap-drag stays held after the finger lifts until the next tap, a classic stuck drag.
- TrackPoint: the kernel logged `psmouse serio2: TrackPoint ... lost synchronization` twice this
  boot (kernel bug 209167, Elan TrackPoint on RMI4 pass-through; the psmouse reconnect resets a held
  button). That is too rare to explain frequent sticking, and mango's code drops no TrackPoint
  events, so the cause is not proven. Next time it sticks:
  `sudo libinput debug-events --device /dev/input/event14` (move, click, scroll) and the kernel log.

## Testing

- `tests/unit.d/keys-test.sh`: a corpus of queries (exact, partial, missing letter, wrong letter,
  swapped letters, synonyms, key words, multi-word, nonsense) against `mango-keys --rank`, each with
  its expected first row; the leader tree resolves (every `setkeymode` target exists, every mode
  binds Esc, every one-shot ends with `setkeymode,default`); `mango -p` parses the config.
- desktop-vm: boot, greeter, session, tests/run; screenshots of the cheatsheet and the popup.

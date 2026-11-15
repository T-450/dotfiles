# Keybindings

Defined in `mango/.config/mango/bind.conf`; design and reasons in [designs/keybindings.md](designs/keybindings.md). **super+/** opens the cheatsheet (`mango-keys`): every bind as keycaps, searchable as you type, with the selected row's whole group beside it.

Two kinds of keys:

- **Chords**, pressed together, for what you do all day. Super = go/look, +shift = take the focused window along, +ctrl = add instead of switch.
- **The leader**, super+space, then a group letter, then an operation letter, pressed in turn (`super+space w f`). Each operation returns to normal; Esc leaves at any point. While a group is open, a popup at the bottom shows its keys and the bar shows its name.

## Chords

| keys | action |
|---|---|
| super+h/j/k/l | focus left/down/up/right |
| super+shift+h/j/k/l | move the window that way |
| super+1..9 | view tag |
| super+shift+1..9 | send the window to tag |
| super+ctrl+1..9 / super+ctrl+shift+1..9 | add the tag to the view / add the window to the tag |
| super+left/right | previous/next tag |
| super+shift+left/right | carry the window to the previous/next tag |
| super+return | Ghostty |
| super+d | rofi launcher |
| alt+esc | dropdown terminal: the one persistent shell, on the top edge of whatever tag you view; alt+esc again hides it and it keeps running (also alt+caps, since Caps Lock is Escape) |
| super+shift+q | close window |
| super+f | fullscreen |
| super+tab / alt+tab | overview, cycling windows / jump to a window by its hint |
| super+u | previous window |
| super+/ | the cheatsheet (again closes it) |
| super+space | the leader |
| super+esc | leave any key mode |
| media / brightness / mic-mute keys | `osd-volume`, `osd-brightness` (swayosd) + playerctl (`bindl`, work while locked and in every mode) |
| Print | screenshot of the screen (clipboard + ~/Pictures/Screenshots) |

## Leader: super+space, then

| group | keys |
|---|---|
| **a** apps | **b** firefox · **f** thunar (GTK apps open floating at 720x480) · **t** floating terminal (800x600, a throwaway) · **v** clipboard history (Enter copies, Shift+Delete removes) · **w** wallpaper picker · **p** theme picker |
| **w** window | **t** float/tile · **m** maximize · **f** fullscreen inside the tile · **o** keep on top · **p** pin to all tags · **c** center a floating window · **z** minimize · **shift+z** restore · **s** show/hide minimized · **shift+q** force kill · **r** resize |
| **w r** resize | **h/l** narrower/wider, **k/j** shorter/taller (hold to repeat; on a tiled window it moves the split) · **Enter**/**Esc** done |
| **l** layout | **n** next · **t** tile · **s** scroller · **m** monocle · **g** grid · **d** deck · **z** swap with master · **=**/**-** more/fewer masters · **w** cycle scroller widths · **[**/**]** stack into the left/right column (scroller) |
| **t** tag | **Tab** back to the previous tags · **a** all tags · **n**/**p** next/previous tag with windows |
| **m** monitor | **h**/**l** focus the left/right monitor · **shift+h**/**shift+l** send the window there · **p** laptop panel on/off (`mango-monitor`) |
| **c** capture | **r** screenshot of a region · **v** start/stop screen recording (~/video) |
| **n** notifications | **r** restore the last · **d** dismiss all · **z** do not disturb |
| **s** session | **l** lock · **e** log out (`mango-quit`) · **p** power menu · **r** reload mango's config (it also reloads on save) · **b** show/hide the bar |

Super can stay down for the group letter (super+space, super+w), not for the operation.

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

Left to apps on purpose, since mango takes every key and click a bind matches: every alt and ctrl+alt key except alt+esc and alt+tab, ctrl+1..9 and alt+1..9 (tab switching), alt+left/right (back/forward), ctrl+left/right (word jumps), ctrl+shift+arrows and ctrl+alt+arrows (word selection, Ghostty's tabs, prompt jumps and splits) and every click and wheel turn (paste, open in a new tab, waybar's click actions). Each action has one bind: the mouse only drags (super+drag moves a floating window, super+right-drag resizes it), and the touchpad has only 4-finger swipes (left/right: previous/next tag with windows, up/down: overview). A key a group doesn't use reaches the focused app, and the group stays open: Esc closes it.

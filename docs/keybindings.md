# Keybindings

Defined in `mango/.config/mango/bind.conf`; design and reasons in [designs/keybindings.md](designs/keybindings.md). **super+/** opens the cheatsheet (`mango-keys`): every bind as keycaps, searchable as you type, with the selected row's whole group beside it.

The modifier names the group, the key names the action, pressed together:

| modifier | group |
|---|---|
| super | go and open |
| super+shift | carry the focused window |
| super+alt | window state |
| super+ctrl | layout and view |
| Print | capture |

Rare actions take two steps: super+esc (session), super+n (notifications) or super+m (monitors), then one key. Esc leaves; a popup at the bottom shows the keys and the bar shows the group while it is open.

## super: go and open

| keys | action |
|---|---|
| h/j/k/l | focus left/down/up/right |
| 1..9 · left/right | view tag · previous/next tag |
| tab · o · u | overview cycling windows · overview of every window · previous window |
| return · shift+return | Ghostty · a floating Ghostty (800x600, a throwaway) |
| d | rofi launcher |
| b · e | Chrome · Thunar (GTK apps open floating at 720x480) |
| v | clipboard history (Enter copies, Shift+Delete removes) |
| w · p | wallpaper picker · theme picker |
| / | the cheatsheet (again closes it) |

alt+esc is the dropdown terminal: the one persistent shell, on the top edge of whatever tag you view; alt+esc again hides it and it keeps running (also alt+caps, since Caps Lock is Escape). alt+tab shows a hint on each window; its key focuses it.

## super+shift: carry the window

| keys | action |
|---|---|
| h/j/k/l | move the window that way |
| 1..9 · left/right | send it to tag · carry it to the previous/next tag |
| q | close |

## super+alt: window state

| keys | action |
|---|---|
| m | maximize |
| t · c | float/tile · center a floating window |
| z · shift+z · s | minimize · restore · show/hide minimized windows |
| o · p | keep on top · pin to all tags (the bar shows on top / pinned; minimized windows are counted too) |
| h/l · k/j | narrower/wider · shorter/taller (hold to repeat; on a tiled window it moves the split) |
| q | force kill |

There is no fullscreen key on purpose; maximize covers it.

## super+ctrl: layout and view

| keys | action |
|---|---|
| space | next layout |
| t · s · m · g · d | tile · scroller · monocle · grid · deck |
| z · = / - | swap with master · more/fewer master windows |
| w · [ / ] | cycle scroller widths · stack into the left/right column (scroller) |
| 1..9 · shift+1..9 | add the tag to the view · add the window to the tag |
| left/right · tab · a | previous/next tag with windows · back to the previous tags · all tags |

## Capture, media

| keys | action |
|---|---|
| Print · shift+Print | screenshot of the screen · of a region (clipboard + ~/Pictures/Screenshots) |
| ctrl+Print | start/stop screen recording (~/video) |
| media / brightness / mic-mute keys | `osd-volume`, `osd-brightness` (swayosd) + playerctl (`bindl`, work while locked and in every mode) |

## Two steps: super+key, then

| group | keys |
|---|---|
| super+esc session | **l** lock · **e** log out (`mango-quit`) · **p** power menu · **r** reload mango's config (it also reloads on save) · **b** show/hide the bar |
| super+n notifications | **r** restore the last · **d** dismiss all · **z** do not disturb |
| super+m monitor | **h**/**l** focus the left/right monitor · **shift+h**/**shift+l** send the window there · **p** laptop panel on/off (way-displays, until the lid changes) |

The second key works with super still held or released.

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

Left to apps on purpose, since mango takes every key and click a bind matches: plain alt (zsh's word motions and alt+., helix's alt commands), ctrl+alt, ctrl+shift, ctrl+1..9 and alt+1..9 (tab switching), alt+left/right (back/forward), ctrl+left/right (word jumps), ctrl+shift+arrows and ctrl+alt+arrows (word selection, Ghostty's tabs, prompt jumps and splits) and every click and wheel turn (paste, open in a new tab, waybar's click actions). Only alt+esc and alt+tab are mango's. Each action has one bind: the mouse only drags (super+drag moves a floating window, super+right-drag resizes it), and the touchpad has no gestures.

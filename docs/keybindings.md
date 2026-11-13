# Keybindings

Defined in `mango/.config/mango/bind.conf`. **super+/** shows all of them as keycaps (`mango-keys`, rofi); this page lists the everyday ones.

| keys | action |
|---|---|
| alt+return | Ghostty |
| alt+esc | dropdown terminal: the one persistent shell, on the top edge of whatever tag you view; alt+esc again hides it and it keeps running (also alt+caps, since Caps Lock is Escape) |
| alt+shift+t | floating terminal: a new 800x600 Ghostty, centered; super+shift+q closes it |
| super+d | rofi launcher |
| super+/ | all keybindings (`mango-keys`) |
| super+return | firefox |
| super+f | thunar (file manager; GTK apps open floating at 720x480) |
| super+v | clipboard history (Enter copies, Shift+Delete removes) |
| super+shift+q | close window |
| super+h/j/k/l | focus left/down/up/right |
| super+left/right | previous/next tag |
| super+1..9 / super+shift+1..9 | view tag / move window to tag (dwm's keys: +ctrl adds the tag to the view, +ctrl+shift adds the window to it) |
| super+n | next layout |
| ctrl+alt+a / Print | screenshot region / full (clipboard + ~/Pictures/Screenshots) |
| ctrl+alt+r | toggle screen recording (~/video) |
| ctrl+alt+l | lock |
| super+shift+escape | power menu (not super+escape: a slip from alt+esc must not open it, since its keys act at once) |
| super+shift+t | theme picker (rofi, `theme pick`) |
| super+w | wallpaper picker (waypaper; a pick stays across logins and `theme set`) |
| ctrl+alt+\\ / ctrl+alt+backspace | restore last / dismiss all notifications |
| ctrl+alt+shift+\\ | toggle do-not-disturb |
| super+b | toggle the bar (waybar) |
| super+r | reload config (also auto-reloads on save) |
| super+m | log out (`mango-quit`: stops session services, then quits mango) |
| super+p | laptop panel on/off (`mango-monitor`) |
| media / brightness / mic-mute keys | `osd-volume`, `osd-brightness` (swayosd) + playerctl (`bindl`, work while locked) |

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

Left to apps on purpose, since mango takes every key and click a bind matches: ctrl+1..9 and alt+1..9 (tab switching), alt+left/right (back/forward), ctrl+left/right (word jumps), ctrl+shift+arrows and ctrl+alt+arrows (word selection, Ghostty's tabs, prompt jumps and splits) and every click and wheel turn (paste, open in a new tab, waybar's click actions). Each action has one bind: the mouse only drags (super+drag moves a floating window, super+right-drag resizes it), and the touchpad has only 4-finger swipes (left/right: previous/next tag with windows, up/down: overview).

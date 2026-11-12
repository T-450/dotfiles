# Keybindings

Defined in `mango/.config/mango/bind.conf`. **super+/** shows all of them as keycaps (`mango-keys`, rofi); this page lists the everyday ones.

| keys | action |
|---|---|
| alt+return | Ghostty |
| alt+esc | dropdown terminal: the one persistent shell, on the top edge of whatever tag you view; alt+esc again hides it and it keeps running (also alt+caps, since Caps Lock is Escape) |
| alt+shift+t | floating terminal: a new 800x600 Ghostty, centered; alt+q closes it |
| super+d | rofi launcher |
| super+/ | all keybindings (`mango-keys`) |
| super+return | firefox |
| super+f | thunar (file manager; GTK apps open floating at 720x480) |
| super+v | clipboard history (Enter copies, Shift+Delete removes) |
| alt+q / super+shift+q | close window |
| alt+arrows | focus |
| super+left/right | previous/next tag |
| ctrl+1..9 / alt+1..9 | view tag / move window to tag |
| super+n | next layout |
| ctrl+alt+a / Print | screenshot region / full (clipboard + ~/Pictures/Screenshots) |
| super+j | toggle screen recording (~/video) |
| super+l | lock |
| super+shift+escape | power menu (not super+escape: a slip from alt+esc must not open it, since its keys act at once) |
| super+shift+t | theme picker (rofi, `theme pick`) |
| super+w | wallpaper picker (waypaper; a pick stays across logins and `theme set`) |
| ctrl+alt+\\ / ctrl+alt+backspace | restore last / dismiss all notifications |
| ctrl+alt+shift+\\ | toggle do-not-disturb |
| super+h | toggle the bar (waybar) |
| super+r | reload config (also auto-reloads on save) |
| super+m | log out (`mango-quit`: stops session services, then quits mango) |
| super+p | laptop panel on/off (`mango-monitor`) |
| media / brightness / mic-mute keys | `osd-volume`, `osd-brightness` (swayosd) + playerctl (`bindl`, work while locked) |

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

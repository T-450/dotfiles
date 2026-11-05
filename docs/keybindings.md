# Keybindings

Defined in `mango/.config/mango/bind.conf`.

| keys | action |
|---|---|
| alt+return | foot |
| alt+space / super+d | rofi launcher |
| super+return | firefox |
| super+v | clipboard history |
| alt+q / super+shift+q | close window |
| alt+arrows | focus |
| super+left/right | previous/next tag |
| ctrl+1..9 / alt+1..9 | view tag / move window to tag |
| super+n | next layout |
| ctrl+alt+a / Print | screenshot region / full (clipboard + ~/Pictures/Screenshots) |
| super+j | toggle screen recording (~/video) |
| super+l | lock |
| super+escape | power menu |
| super+shift+t | theme picker (rofi, `theme pick`) |
| ctrl+alt+\\ / ctrl+alt+backspace | restore last / dismiss all notifications |
| ctrl+alt+shift+\\ | toggle do-not-disturb |
| super+h | toggle the bar (waybar) |
| super+r | reload config (also auto-reloads on save) |
| super+m | log out (`mango-quit`: stops session services, then quits mango) |
| super+p | laptop panel on/off (`mango-monitor`) |
| media / brightness / mic-mute keys | `osd-volume`, `osd-brightness` (swayosd) + playerctl (`bindl`, work while locked) |

Caps Lock is Escape (`xkb_rules_options=caps:escape`).

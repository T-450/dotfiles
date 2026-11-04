# Theme: VS Code Dark 2026

Source: `microsoft/vscode` → `extensions/theme-defaults/themes/2026-dark.json` (includes `dark_modern.json`).
Terminal ANSI colors are not set by the theme; VS Code's defaults come from
`src/vs/workbench/contrib/terminal/common/terminalColorRegistry.ts`.

| role | VS Code key | hex | used in |
|---|---|---|---|
| desktop / deepest bg | `editor.background` | `#121314` | mango `root_color`, swaybg, swaylock, GTK view |
| surface | `statusBar/panel/sideBar.background`, `terminal.background` | `#191A1B` | mangobar, foot, GTK window |
| widget | `quickInput/notifications/menu.background` | `#202122` | rofi, mako, bar menus, wlogout hover |
| hover | `statusBarItem.hoverBackground` | `#323233` | bar tag hover |
| hairline | `widget.border`, `panel.border` | `#2A2B2C` | rofi/mako borders, swaylock ring |
| inactive border | `input.border` | `#333536` | mango `border_color` |
| text | `foreground` | `#bfbfbf` | bar title/clock, mako, GTK |
| secondary text | `descriptionForeground`, `statusBar.foreground` | `#8C8C8C` | bar modules, mako low |
| muted text | `editorLineNumber.foreground` | `#858889` | empty tags, rofi placeholder |
| accent (focus) | `focusBorder`, `tab.activeBorderTop` | `#3994BC` | mango focus, active tag, rofi input, swaylock |
| selection | `quickInputList.focusBackground` + `focusForeground` | `#297AA0` / `#FFFFFF` | rofi selected, foot selection, GTK accent bg |
| link / highlight | `textLink.foreground`, `list.highlightForeground` | `#48A0C7` | foot urls, rofi match highlight |
| error | `errorForeground` | `#f48771` | urgent, critical, wrong password |
| warning | `list.warningForeground` | `#e5ba7d` | network offline |
| success | `gitDecoration.addedResourceForeground` | `#73c991` | GTK success |

Terminal (foot): fg `#CCCCCC`, bg `#191A1B`, cursor `#bfbfbf`.

| | normal | bright |
|---|---|---|
| black | `#000000` | `#666666` |
| red | `#cd3131` | `#f14c4c` |
| green | `#0dbc79` | `#23d18b` |
| yellow | `#e5e510` | `#f5f543` |
| blue | `#2472c8` | `#3b8eea` |
| magenta | `#bc3fbc` | `#d670d6` |
| cyan | `#11a8cd` | `#29b8db` |
| white | `#e5e5e5` | `#e5e5e5` |

Fonts: Inter (UI), JetBrains Mono Nerd Font (mono).

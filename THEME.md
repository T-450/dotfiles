# Theming

Every color on the desktop comes from one **palette** (`theme/palettes/<name>.toml`).
`theme/theme` renders it into small colors-only files that each app includes, then
reloads the apps that can reload. Hex values live **only** in palettes; `theme lint`
fails if one shows up anywhere else in the repo.

```bash
theme/theme list                 # palettes (* = active)
theme/theme set light-2026       # switch everything (also: SUPER+SHIFT+t picker)
theme/theme init                 # render the active palette without reloading (link.sh)
theme/theme lint                 # no color literals outside theme/
theme/theme install-greeter      # login screen follows the palette (asks for sudo)
```

The default palette is **Dark 2026**, from VS Code's
`microsoft/vscode` → `extensions/theme-defaults/themes/2026-dark.json`.

## Roles

A palette names colors by what they do, not by app. The VS Code key is where
`theme import-vscode` reads each role from.

| role | VS Code key | used in |
|---|---|---|
| `bg_desktop` | `editor.background` | mango `root_color`, swaybg, swaylock, GTK view, wlogout backdrop, slurp dim, greeter bg |
| `bg_surface` | `statusBar.background` | mangobar, GTK window/headerbar/sidebar, rofi input |
| `bg_widget` | `quickInput.background` | rofi, mako, bar menus, wlogout hover, swayosd, GTK cards/popovers, greeter active |
| `bg_hover` | `statusBarItem.hoverBackground` | bar tag hover, swayosd trough |
| `border_hairline` | `widget.border` | rofi/mako/swayosd borders, swaylock ring, bar menus |
| `border_inactive` | `input.border` | mango `border_color`, rofi |
| `fg_text` | `foreground` | bar title/clock, mako, GTK, wlogout, swayosd, greeter |
| `fg_editor` | `editor.foreground` | GTK view text |
| `fg_secondary` | `descriptionForeground` | bar modules, mako low, mango global/overlay, swaylock clear ring |
| `fg_muted` | `editorLineNumber.foreground` | empty tags, rofi placeholder, greeter muted |
| `fg_bright` | `list.activeSelectionForeground` | bar tag hover text |
| `fg_disabled` | `disabledForeground` | bar invalid |
| `accent` | `focusBorder` (alpha dropped) | mango focus/drop/maximized, active tag, rofi input, swaylock, slurp, swayosd fill, greeter primary |
| `badge` | `badge.background` | mango scratchpad |
| `selection_bg` / `selection_fg` | `quickInputList.focusBackground` / `focusForeground` | rofi selected, foot selection, mango split, GTK accent, bar menu hover |
| `link` | `textLink.foreground` | foot urls, rofi match highlight, GTK4 accent, greeter accent |
| `error` | `errorForeground` | urgent, critical, wrong password |
| `warning` | `list.warningForeground` | network offline, greeter warning |
| `success` | `gitDecoration.addedResourceForeground` | GTK success |
| `shadow` | (constant black) | mango shadows |

`[terminal]` holds `fg`, `bg`, `cursor` and the 16 ANSI colors (foot; zsh, vim and
follow foot). VS Code themes rarely set ANSI colors, so the importer falls
back to VS Code's own defaults (`terminalColorRegistry.ts`). `[art]` (optional) colors
the greeter wallpaper planet; imported palettes derive it from `link`/`accent`/`warning`.
`meta.variant` (`dark`/`light`) drives GTK `color-scheme`/`gtk-theme`, GTK
`prefer-dark` and foot's `initial-color-theme`.

## Adding a theme

```bash
theme/theme import-vscode https://raw.githubusercontent.com/microsoft/vscode/main/extensions/theme-defaults/themes/2026-light.json light-2026
theme/theme import-omarchy <colors.toml file or URL> tokyo-night
theme/theme import-base24 <base16/base24 YAML file or URL> catppuccin-mocha
```

Imports follow VS Code `include` chains and flatten alpha onto the right background.
Missing tiers are derived with `mix`. Or copy `dark-2026.toml` and edit by hand.

## How it fits together

- `theme/targets.toml`: each template → the file it renders (all gitignored).
- `theme/templates/*`: `{{role}}` → `#rrggbb`. Filters: `|bare` (`rrggbb`),
  `|hex:88` / `|bare:88` (alpha), `|0x` / `|0x:33` (mango `0xRRGGBBAA`),
  `|rgb` (`r, g, b`), `|rgba:0.9`, `|mix:<role>:<0-1>` (chainable, before the format).
  Also `{{name}} {{slug}} {{variant}} {{prefer_dark}} {{gtk_theme}} {{color_scheme}}`.
  An unknown role or filter aborts before anything is written.
- `theme/hooks/*.sh` run in parallel after `theme set` with `THEME_NAME THEME_SLUG
  THEME_VARIANT THEME_ROOT`; failures show a critical notification.
- `theme/colors.sh` is the palette as `THEME_*` shell variables, for scripts
  (`. ~/.config/mango/theme/colors.sh`) and systemd (`EnvironmentFile=`).

| app | how it gets colors | applies |
|---|---|---|
| mango | `source=./colors.conf` | reload (hook) |
| foot | `include=~/.config/foot/colors.ini` | new windows |
| mangobar, wlogout, swayosd, GTK 3/4 | `@import "colors.css"` | bar/OSD restart (hook); wlogout next launch; GTK: apps started after the switch (GTK reads gtk.css once per process) |
| rofi | `@import "colors.rasi"` in `themes/quickinput.rasi` | next launch |
| mako | `include=~/.config/mako/colors` | `makoctl reload` (hook) |
| swaylock | whole `swaylock/config` rendered (no include support) | next lock |
| swaybg, slurp | `theme/colors.sh` | swaybg restart (hook); slurp next use |
| Firefox | `userChrome.css` in the profile | restart Firefox |
| greeter | `greeter/themes/mango.toml` + wallpaper, theme name "Mango" | `theme install-greeter` (sudo) |
| fastfetch | `fastfetch/config.jsonc` rendered (keys, title, bars, separators); the logo keeps its own colors | next run |
| zsh, vim | terminal ANSI colors (foot) | new terminals |
| Claude Code | custom theme `~/.claude/themes/mango.json` (copied by `hooks/agents.sh`), selected as `custom:mango` in `~/.claude/settings.json` | running sessions reload the file |
| opencode | custom theme `~/.config/opencode/themes/mango.json`, selected as `{"theme": {"name": "mango"}}` in `~/.config/opencode/cli.json`; code uses the terminal ANSI hues (palettes have no syntax roles) | next start |

To theme a new app: add a template, a `[[target]]`, its output to `.gitignore`, an
include line in the app's config, and a hook if it can reload live.

Claude Code and opencode are selected only by `link.sh` (`agents.sh --activate`) and only while
no theme was chosen in them (Claude `auto`/unset, opencode unset); after that `theme set` just
refreshes the theme file. To go back: `/theme` in either app.

Rendered files are gitignored. After a fresh clone or `git clean -X`, run
`theme/theme init` (link.sh does), or mako, swaybg, slurp and foot fail to load their colors.

Fonts: Inter (UI), JetBrains Mono Nerd Font (mono). They are not part of the palette.

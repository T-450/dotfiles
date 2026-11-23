# Theming

Every color on the desktop comes from one **palette** (`theme/palettes/<name>.toml`).
`theme` (`~/.local/bin/theme`, from `theme/.local/bin/theme`) renders it into small colors-only
files that each app includes, then reloads the apps that can reload. Hex values live **only** in
palettes; `theme lint` fails if one shows up anywhere else in the repo.

```bash
theme list                 # palettes (* = active)
theme set tokyo-night      # switch everything (also: super+shift+t picker)
theme init                 # render the active palette without reloading (install.sh)
theme lint                 # no color literals; rendered files gitignored; no secrets tracked
```

The default palette is **Colibri**, from `archseer/colibri.vim` (`colors/colibri.vim`, its dark
branch): each role, ANSI color and syntax color is one of that scheme's named colors (the comments
in `colibri.toml` name it and its highlight group), except two tiers it lacks (`bg_hover`,
`fg_secondary`), mixed from its own. The desktop (`bg_desktop`: bar, lock screen, GTK, browsers)
sits on its darkest shade, revolver, a step below the terminal and the editors on midnight, its
editor background. The others:

- Tokyo Night (`theme import-omarchy`).
- Cassette, by hand from a cassette J-card's tokens: black card, silver paper, a teal and a
  cobalt stripe.
- Written by hand the way Colibri is, each role named after its scheme's color and highlight
  group, with `[terminal]` from the scheme's own terminal colors (or ghostty's theme of the same
  name) and `[syntax]` and `[diff]` from its highlight groups: Doom One
  (`NTBBloodbath/doom-one.nvim`), Gruber Darker (`blazkowolf/gruber-darker.nvim`), Oxide
  (`oxidescheme/nvim`) and Alabaster (`tonsky/sublime-scheme-alabaster`), the one light palette.
  Alabaster's `warning` is derived: the scheme's orange is a highlight fill, unreadable as text.
- Deep Blue, Deep Blue Night and Deep Blue Flat (`kinqert/deep-blue-theme`): `theme
  import-vscode`, then corrected by hand where the importer fell back to VS Code's defaults. The
  three share Flat's terminal and git colors and one set of token colors.

None sets `[keycaps]`, so the cheatsheet derives its caps.

## Keycaps

An optional `[keycaps]` table gives the keybinding cheatsheet (`mango-keys`) its keycap colors, as
roles `key_mod`, `key_cap`, `key_accent`, `key_legend`, `key_frame` (and
`THEME_KEY_*` in `colors.sh`). Tokyo Night sets them from the NuPhy Air60 HE: black modifier
caps, grey letter caps, white legends, the aluminium frame. `key_accent` is the one lit cap, under
the selected row's action key only: the board's violet. A cap may be
translucent (`#rrggbbaa`): `theme` composites it over `bg_desktop`, as you see the plate through
the board's violet keys (85% on dark palettes; opaque on light ones, where blending would wash the
legend out). `theme` fails a palette whose legend reads
below WCAG AA (4.5:1) on any cap. A palette without the table
(an import) derives them from its own roles: modifiers on its hover grey, the selected row's
action key on its accent.

## Material 3 roles

An optional `[material]` table holds the 45 Material 3 color roles (`primary`, `on_primary`,
`primary_container` … `surface_container_highest`, `outline`, the `*_fixed` roles, `shadow`,
`scrim`), all of them or none; templates read them as `m3_<role>`. A palette without the table
derives them from its own roles, the legacy mapping of
[SPEC-theme](designs/material-shapeshifter/SPEC-theme.md) inverted: `primary` from `accent`,
`secondary` from `warning`, `tertiary` from `badge`, containers mixed 60% toward `bg_desktop`, and
every checked text role made legible, so any palette that loads today still loads.

`theme` fails a palette whose M3 pairs read below the floors (`MATERIAL_FLOORS`): 4.5:1 for
`on_X` on `X` (primary, secondary, tertiary, error and their containers), `on_surface` and
`on_surface_variant` on `surface`, `inverse_on_surface` on `inverse_surface`; 3:1 for `outline`
on `surface`. The fixed pairs and text on surface containers are left unchecked on purpose. One
failing palette fails every render, since per-palette templates load them all.

## System tokens

`theme/tokens.toml` holds the Material 3 system tokens, one set for every palette: corner sizes,
elevation, motion (Expressive springs, durations, easings), state-layer opacities and the type
scale. They come from Jetpack Compose `material3` 1.5.0's token sources (the file's header pins the
jar's URL and sha256); the shell's typeface is IBM Plex Sans. Templates read each as a word
`<table>_<key>`, with the unit added by the template: `{{shape_corner_large}}` is `16` (px),
`{{motion_duration_medium2}}` is `300` (ms), `{{motion_easing_emphasized_decelerate}}` is
`0.05, 0.7, 0.1, 1`, `{{type_label_large_size}}` is `14`. A state layer is a color:
`{{m3_surface|mix:m3_on_surface:state_hover}}`. The names are fixed by `SYSTEM_TOKENS` in `theme`
(the full list is in [SPEC-theme](designs/material-shapeshifter/SPEC-theme.md)); an unknown or
missing name fails the render.

## Syntax

An optional `[syntax]` table gives the editors (vim, helix) their syntax colors, as roles
`syn_keyword`, `syn_preproc`, `syn_type`, `syn_function`, `syn_identifier`, `syn_string`,
`syn_constant`, `syn_number`, `syn_boolean`, `syn_special`, `syn_operator`, `syn_comment`: for a
palette taken from an editor scheme that maps syntax its own way (Colibri: keywords almond, types
and functions white, strings silver, constants mint, numbers chamois, punctuation lilac). The
templates still push each to 4.5:1 on `term_bg` (`|legible`; Colibri's sirocco comments, 3.2:1
in colibri.vim, come out lighter). A palette without the table takes them from its terminal hues
and greys: keyword `ansi5`, type `ansi13`, function `ansi12`, string `ansi2`, constant `ansi3`,
special `ansi6`, identifier `fg_editor`, operator `fg_secondary`, comment `fg_muted`; preproc
follows keyword, number and boolean follow constant.

## Diff and info

An optional `[diff]` table (`add`, `remove`, `change`; roles `diff_add`, `diff_remove`,
`diff_change`) colors added, removed and changed lines in vim, helix, delta (git's pager and
lazygit's), Pi, Claude Code and Mousepad; without it they are `success`, `error` and `ansi4`. An
optional `info` in `[colors]` is the third diagnostic tier after error and warning (helix); without
it, `ansi4`. Colibri sets both from swatch.html: plus, minus and delta. Every editor (vim, helix,
Mousepad, Pi) takes its syntax from the `syn_*` roles.

## Roles

A palette names colors by what they do, not by app. The VS Code key is where
`theme import-vscode` reads each role from.

| role | VS Code key |
| --- | --- |
| `bg_desktop` | `editor.background` |
| `bg_surface` | `statusBar.background` |
| `bg_widget` | `quickInput.background` |
| `bg_hover` | `statusBarItem.hoverBackground` |
| `border_hairline` | `widget.border` |
| `border_inactive` | `input.border` |
| `fg_text` | `foreground` |
| `fg_editor` | `editor.foreground` |
| `fg_secondary` | `descriptionForeground` |
| `fg_muted` | `editorLineNumber.foreground` |
| `fg_bright` | `list.activeSelectionForeground` |
| `fg_disabled` | `disabledForeground` |
| `accent` | `focusBorder` (alpha dropped) |
| `badge` | `badge.background` |
| `selection_bg` / `selection_fg` | `quickInputList.focusBackground` / `focusForeground` |
| `link` | `textLink.foreground` |
| `error` | `errorForeground` |
| `warning` | `list.warningForeground` |
| `success` | `gitDecoration.addedResourceForeground` |
| `shadow` | (constant black) |

Which apps use each role (generated from the templates):

<!-- generated by tools/docs: roles -->
| role / word | used by |
|---|---|
| `accent` | claude, firefox, ghostty, gtk, helix, hyprlock, lazygit, mako, mango, pi, qutebrowser, rofi, theme, vim, waybar, wlogout |
| `ansi0` | ghostty |
| `ansi1` | fastfetch, ghostty |
| `ansi10` | ghostty, helix, mousepad |
| `ansi11` | ghostty, helix |
| `ansi12` | ghostty, helix, mousepad, vim |
| `ansi13` | claude, ghostty, helix, mousepad, pi |
| `ansi14` | ghostty, mousepad |
| `ansi15` | ghostty |
| `ansi2` | ghostty, helix, vim |
| `ansi3` | ghostty, helix |
| `ansi4` | ghostty, helix, vim, waybar |
| `ansi5` | ghostty, helix, vim, waybar |
| `ansi6` | ghostty, helix, vim, waybar |
| `ansi7` | ghostty |
| `ansi8` | ghostty |
| `ansi9` | ghostty, helix |
| `badge` | lazygit, mousepad, mpv, theme |
| `bg_desktop` | claude, firefox, gtk, hyprlock, imv, mango, mousepad, mpv, qutebrowser, theme, waybar, wlogout |
| `bg_hover` | claude, firefox, ghostty, helix, lazygit, mousepad, rofi, swayosd, theme, vim |
| `bg_surface` | claude, firefox, ghostty, gtk, helix, hyprlock, mako, mango, mousepad, qutebrowser, rofi, theme, vim |
| `bg_widget` | claude, firefox, gtk, helix, imv, mako, mpv, pi, qutebrowser, rofi, swayosd, theme, vim, wlogout |
| `border_hairline` | firefox, helix, pi, qutebrowser, rofi, theme |
| `border_inactive` | claude, fastfetch, firefox, ghostty, helix, lazygit, mako, mango, mousepad, pi, rofi, swayosd, theme, vim |
| `diff_add` | git, helix, mousepad, pi, vim |
| `diff_change` | helix, mousepad, vim |
| `diff_remove` | git, helix, mousepad, pi, vim |
| `error` | claude, fastfetch, gtk, helix, hyprlock, lazygit, mako, mango, mousepad, mpv, pi, qutebrowser, theme, vim, waybar |
| `fg_bright` | claude, fastfetch, firefox, helix, hyprlock, mango, mousepad, pi, qutebrowser, theme, vim |
| `fg_disabled` | claude, helix, mousepad, qutebrowser, theme, vim |
| `fg_editor` | gtk, helix, mousepad, pi, theme, vim, waybar |
| `fg_muted` | claude, helix, hyprlock, mousepad, pi, qutebrowser, rofi, theme, vim |
| `fg_secondary` | claude, firefox, ghostty, helix, lazygit, mako, mango, mousepad, pi, qutebrowser, rofi, theme, vim, wlogout |
| `fg_text` | claude, fastfetch, firefox, gtk, imv, mako, mousepad, mpv, pi, qutebrowser, rofi, swayosd, theme, vim, wlogout |
| `git_email` | git |
| `git_name` | git |
| `home` | helix, hyprlock, runner-up |
| `info` | helix |
| `key_accent` | theme |
| `key_cap` | theme |
| `key_frame` | theme |
| `key_legend` | theme |
| `key_mod` | theme |
| `link` | claude, ghostty, lazygit, mousepad, mpv, pi, qutebrowser, rofi, theme, vim |
| `name` | claude, fastfetch, firefox, ghostty, gtk, helix, hyprlock, mako, mango, mousepad, mpv, qutebrowser, rofi, swayosd, theme, vim, waybar, wlogout |
| `prefer_dark` | gtk, waybar |
| `repo` | runner-up |
| `selection_bg` | claude, firefox, ghostty, gtk, helix, mako, mango, mousepad, qutebrowser, rofi, theme, vim, waybar |
| `selection_fg` | firefox, ghostty, gtk, helix, mango, mousepad, qutebrowser, rofi, theme, vim, waybar, wlogout |
| `shadow` | hyprlock, mango, theme |
| `slug` | fastfetch, firefox, ghostty, gtk, hyprlock, mako, mango, mousepad, mpv, pi, rofi, swayosd, theme, waybar, wlogout |
| `success` | claude, fastfetch, gtk, mpv, pi, qutebrowser, theme, vim, waybar |
| `syn_boolean` | helix, mousepad, vim |
| `syn_comment` | helix, mako, mousepad, pi, vim |
| `syn_constant` | fastfetch, helix, mousepad, swayosd, vim |
| `syn_function` | helix, mousepad, pi, vim |
| `syn_identifier` | mousepad, vim |
| `syn_keyword` | fastfetch, helix, mako, mousepad, pi, vim |
| `syn_number` | helix, mousepad, pi, vim |
| `syn_operator` | helix, pi, vim |
| `syn_preproc` | helix, mousepad, vim |
| `syn_special` | fastfetch, helix, mousepad, vim |
| `syn_string` | helix, mousepad, pi, vim |
| `syn_type` | helix, mousepad, pi, vim |
| `term_bg` | claude, fastfetch, ghostty, helix, pi, theme, vim |
| `term_cursor` | ghostty, mousepad, theme |
| `term_fg` | ghostty, theme |
| `variant` | claude, lazygit, pi, qutebrowser, theme, vim |
| `warning` | claude, fastfetch, gtk, helix, hyprlock, lazygit, mango, mousepad, pi, qutebrowser, theme, vim, waybar |
<!-- end generated -->

`[terminal]` holds `fg`, `bg`, `cursor` and the 16 ANSI colors (Ghostty; zsh
follows Ghostty; helix's and vim's rendered themes take their syntax colors from them unless the palette has a `[syntax]` table, see [helix](apps/helix.md) and [vim](apps/vim.md)). VS Code themes rarely set ANSI colors, so the importer falls
back to VS Code's own defaults (`terminalColorRegistry.ts`). `meta.variant` (`dark`/`light`) drives GTK `color-scheme` and `prefer-dark` (Qt and Firefox follow
`color-scheme` through the settings portal).

## Adding a theme

```bash
theme import-vscode https://raw.githubusercontent.com/microsoft/vscode/main/extensions/theme-defaults/themes/2026-light.json light-2026
theme import-omarchy <colors.toml file or URL> tokyo-night
theme import-base24 <base16/base24 YAML file or URL> catppuccin-mocha
```

Imports follow VS Code `include` chains and flatten alpha onto the right background.
Missing tiers are derived with `mix`. Or copy `colibri.toml` and edit by hand.

## How it fits together

- Templates: any `<app>/**/NAME.tmpl` renders to `NAME` beside it (listed in `<app>/.gitignore`)
  from the active palette. A `NAME` with `{palette}` in it renders once per palette instead, each
  from its own palette, with the slug in place of `{palette}`: for an app that keeps a theme per
  palette and picks one itself (Pi's `{palette}.json.tmpl` → `colibri.json`, `tokyo-night.json`).
  `{{role}}` → `#rrggbb`. Filters: `|bare` (`rrggbb`), `|hex:88` / `|bare:88` (alpha), `|0x` /
  `|0x:33` (mango `0xRRGGBBAA`), `|rgb` (`r, g, b`), `|rgba:0.9`, `|mix:<role>:<0-1>` (chainable,
  before the format). Contrast filters, also chainable: `|ink` turns a background into its text
  color (`bg_desktop` or `fg_bright`, whichever reads better, pushed to WCAG AA 4.5:1), e.g.
  `{{accent|mix:bg_surface:0.3|ink}}`; `|legible:<role>` nudges a foreground until it reads at
  4.5:1 on that role (syntax colors from the ANSI set on a light palette). Also `{{name}} {{slug}} {{variant}} {{prefer_dark}} {{color_scheme}}`.
  An unknown role or filter aborts before anything is written; all files are swapped in at once.
- Reload hooks: every `<app>/reload.sh` runs in parallel after `theme set`, with `THEME_NAME
  THEME_SLUG THEME_VARIANT THEME_ROOT`; a failure shows a critical notification.
- `~/.config/theme/colors.sh` is the palette as `THEME_*` shell variables, for scripts
  (`. ~/.config/theme/colors.sh`) and units (`EnvironmentFile=%h/.config/theme/colors.sh`).
- The active palette's name is in `~/.local/state/theme/current` (default `colibri`).

| app | how it gets colors | applies |
|---|---|---|
| mango | `source=./colors.conf` | reload (`mango/reload.sh`) |
| Ghostty | `config-file = colors.ghostty`; tabs: `gtk-custom-css = tabs.css` | open windows reload both (`ghostty/reload.sh`, SIGUSR2) |
| waybar | `@import "colors.css"` | `systemctl --user reload waybar` (`waybar/reload.sh`) |
| wlogout, swayosd, GTK 3/4 | `@import "colors.css"` | swayosd restart (hook); wlogout next launch; GTK: apps started after the switch (GTK reads gtk.css once per process). The Thunar daemon, which owns every Thunar window, restarts when none is open (`thunar/reload.sh`); otherwise a notification asks to close them and set the theme again |
| rofi | `@import "colors.rasi"` in `themes/quickinput.rasi` | next launch |
| mako | `include=~/.config/mako/colors` | `makoctl reload` (hook) |
| swaylock | whole `config` rendered (no include support) | next lock |
| swaybg | `~/.config/swaybg/wallpaper.png` (`swaybg/render.sh`: the image on dark palettes, the desktop color on light ones), shown unless a waypaper pick replaced it | swaybg restart (hook) |
| slurp | `~/.config/theme/colors.sh` | next use |
| qutebrowser | `config.source("colors.py")` | `:config-source` in a running browser (hook) |
| Firefox | `chrome/userChrome.css` in the profile | restart Firefox (`firefox/reload.sh` says so while it runs) |
| fastfetch | `config.jsonc` rendered (group labels, icons, tree, bars) and `logo.svg`, which `fastfetch/render.sh` rasterizes to `logo.png` | next run |
| lazygit | `config.yml` rendered (borders, selection, cherry-pick and rebase marks; `colorScheme` and delta's `--dark`/`--light` from `variant`) | next start |
| zsh, vim | terminal ANSI colors (Ghostty) | at once (Ghostty reloads) |
| helix | `themes/palette.toml` rendered (syntax from the `syn_*` roles, interface from the roles), selected as `theme = "palette"` | at once (`helix/reload.sh`: SIGUSR1, helix's `:config-reload`) |
| Claude Code | `~/.claude/themes/mango.json` (linked), selected in the linked `settings.json` | next session (`claude/reload.sh` says so while one runs) |
| Pi | one theme per palette, `~/.pi/agent/themes/<slug>.json` (linked); `pi/setup.sh` selects `colibri` | at once (Pi hot-reloads its theme files) |

To theme a new app: add `NAME.tmpl` in its folder, the output to its `.gitignore`, an include
line in its config, and a `reload.sh`: one that reloads it live, or, for an app that reads its colors
only at startup, one that sends a notification while it runs.

Fonts: IBM Plex Sans (UI), Lilex Nerd Font (the terminal), JetBrains Mono Nerd Font (the rest of the character grid: bar, lock screen, notifications). They are not part of the palette.

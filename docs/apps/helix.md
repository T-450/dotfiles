# helix

Helix, a modal editor set up for every language in the toolchain, with Vim and AstroNvim keys added where helix binds nothing (four named exceptions), inline diagnostics, and a theme rendered from the active palette, which `theme set` reloads in running editors.

Helix here is [gj1118's fork](https://github.com/gj1118/helix): upstream helix (it reports itself as `helix 25.07.1`) with merged pull requests for a sidebar file tree, icons, inline git blame, breadcrumbs, code folding, a command-line popup and notifications. Neither Arch nor the AUR packages it, and the file tree came after its last release (26.09.02), so `pkg/helix-gj1118/PKGBUILD` builds a pinned master commit (`2610b17`, `pkgver` 26.09.02.r57.g2610b17) from source, the way Arch builds helix: the commit's tarball checked by SHA-256, cargo with the locked dependencies, and helix's build script, which fetches each of the 301 tree-sitter grammars at the git revision `languages.toml` pins and compiles it. The build takes about 8 minutes on this laptop; makepkg installs `cargo` and `git` for it and removes what it installed afterwards. It installs in Arch's own layout: `/usr/lib/helix-gj1118/hx` beside `runtime/`, `/usr/bin/helix` a link, the desktop file and completions renamed `hx` to `helix`. It replaces Arch's `helix` (`provides`/`conflicts`). It went in after a day of editing C#, TypeScript and Go showed no regression from its open issue [#94](https://github.com/gj1118/helix/issues/94) (completion and fuzzy matching). Its version is the PKGBUILD's `pkgver` (`docs/reference/installed.md` lists only `packages` entries). To move to another commit or a tag, change `_commit`, `pkgver` and the tarball's sha256 together, then check `helix --health` and the keys below against the new keymap.

`explorer-shift-keys.patch` fixes one bug of the fork: the file tree ignored every key that came with Shift, which a typed capital letter does, so `G`, `H`, `R` and `A` did nothing. The patch drops Shift from letter keys there, as helix's editor already does (`canonicalize_key`), and is proposed to the fork as [#104](https://github.com/gj1118/helix/pull/104). Once the fork changes those lines, the patch stops applying and the build fails: delete the patch and its `source` and `sha256sums` entries.

On a machine that has Arch's `helix`, swap once by hand: `sudo pacman -Rns helix`, then `./install.sh` (its makepkg runs with `--noconfirm`, which would refuse to remove the conflicting package). A fresh install never has Arch's `helix`. To go back: `sudo pacman -Rdd helix-gj1118 && sudo pacman -S helix`, then revert the fork's commits (`config.toml` without the fork's options loads on stock helix) and `./install.sh`.

mise installs the language servers, formatters and debuggers (yamlfmt for YAML, prettier for Markdown), except clangd and jdtls, which pacman installs. Start helix from a terminal, because only zsh puts mise's tools on `PATH` ([mise](mise.md#programs-started-outside-a-terminal-dont-see-the-tools)). `languages.toml` names a server only where helix's built-in choice is not the one installed:

- Python uses ty and ruff.
- TypeScript, TSX, JavaScript, JSX, JSON and JSONC format with biome (`biome lsp-proxy`). typescript-language-server and vscode-json-language-server still give hover, completion and diagnostics, with formatting off.
- typescript-language-server runs TypeScript 6's tsserver, because TypeScript 7 ships none. `tsc` on `PATH` is TypeScript 7.
- C# uses roslyn-language-server, TOML uses tombi, YAML uses yaml-language-server, and Markdown uses marksman. Markdown formats with prettier on `space l f` (tables and lists; prose wrapping and fenced code stay as written).
- CMake uses neocmakelsp; Meson (helix's built-in choice) uses mesonlsp. Both come from mise. mesonlsp's upstream was archived in August 2026 at 5.0.4; it still works, and no other Meson server exists.

Go, Rust, Zig, C, C++, Java and Bash use helix's built-in servers. `theme` renders `languages.toml` from `languages.toml.tmpl`, because the tsserver path contains your home directory.

Theme: `themes/palette.toml.tmpl` renders the active palette into a helix theme named `palette` (`theme = "palette"` in `config.toml`). Syntax comes from the palette's `syn_*` roles (its `[syntax]` table, see [Theming](../theming.md#syntax)); without one, text and punctuation keep the palette's greys and the syntax takes the terminal's hues, each made legible on the terminal's background `term_bg`, which is also helix's own, so it meets Ghostty's padding, so a light palette darkens them: keywords `ansi5`, types `ansi13`, functions `ansi12`, strings `ansi2`, constants `ansi3`, attributes and escapes `ansi6`, lifetimes and labels `ansi9`, comments `fg_muted`. The cursor is `accent`; selections, the picker's row and the selected menu item are `selection_bg`; popups sit on `bg_widget` with `border_inactive` borders. `reload.sh` sends running editors SIGUSR1 (helix's `:config-reload`), so `theme set` recolors them at once. The mode name (NOR/INS/SEL) stays uncolored because `color-modes` is off.

## Keys

Helix keeps its own grammar: select first, then act (`w d`, not Vim's `d w`). Keys for Vim and AstroNvim habits are added only where helix (gj1118's fork at 2610b17, checked against its keymap) binds nothing, so every helix key still does what helix's docs and `:tutor` say, with four named exceptions:

- **Ctrl+C** copies the selection to the system clipboard (helix's own Ctrl+C, toggle comments, stays on `space c`); Ghostty's Ctrl+V pastes. `space y`/`space p` still use the clipboard too.
- **`$`** goes to the line end, as in Vim. The command it replaces, `shell_keep_pipe` (keep the selections whose shell command succeeds), moves to **Alt+$**.
- **Ctrl+j/k** focus the split below/above (AstroNvim). The fork moves lines with them; moving lines goes to **Alt+j/k**, AstroNvim's own keys for it.
- **`space l`** is the LSP group (AstroNvim). The fork searches within the file there; that moves to **`space o`** (`space L`, its fuzzy variant, stays).

| Key | Does | AstroNvim | Helix's own key |
|---|---|---|---|
| `$` / `0` / `^` | line end / line start / first non-blank (select mode extends) | `$` `0` `^` | `gl` / `gh` / `gs` |
| `C-h` `C-j` `C-k` `C-l` | focus the split to the left / below / above / right | same | `C-w h/j/k/l` |
| `]b` / `[b` | next / previous buffer | same | `gn` / `gp` |
| `A-j` / `A-k` | move the line or selection down / up | same | (the fork's `C-j`/`C-k`) |
| `space o` | search within the file | `<leader>f/`-ish | (the fork's `space l`) |
| `space l a` `r` `f` | code action, rename, format | `<leader>la` `lr` `lf` | `space a`, `space r`, `=` |
| `space l s` `S` | document / workspace symbols | `<leader>ls` | `space s` `space S` |
| `space l d` `D` | file / workspace diagnostics | `<leader>lD` | `space d` `space D` |
| `space l h` / `R` | signature help / restart the language servers | `<leader>lh` / `lR` | `:lsp-restart` |
| `space u w` `n` `i` `h` `d` `c` `z` | toggle soft wrap, relative numbers, indent guides, inlay hints, end-of-line diagnostics, auto-completion, whitespace | `<leader>uw` `un` `ui` `uh` `ud` `uc` | `:toggle` |
| `space t t` / `f` / `l` | a Ghostty (tiled / floating) or lazygit in helix's working directory | `<leader>th` `tf` `tl` | none |
| `space q` / `Q` | quit the split / quit helix | `<leader>q` / `Q` | `:q` / `:qa` |
| `space n` | new scratch buffer | `<leader>n` | `:new` |

Unchanged on purpose, because helix uses those keys: `space e` (file explorer, the same key as AstroNvim's), `space f` `b` `d` `g` (pickers), `space c` (comment), `space w` (window menu), `space G` (debugger). `space x` and `space X` are the fork's file tree (below). Operators (`dd`, `yy`, `cc`) are not ported: they would make helix's `d`, `y`, `c` wait for a second key. `space ?` searches every command by name.

`space t` asks mango to start the window (`mmsg dispatch spawn`), so it is a new window and not a child of helix's terminal, which mango would swallow.

mango binds no Alt key but alt+esc and alt+tab, so every helix Alt command works: Alt+s (split selection on newlines), Alt+x (shrink to line bounds), Alt+a (select all siblings), Alt+e, Alt+arrows and Alt+o/i/p/n.

## The fork's options

The end of `config.toml` turns on gj1118's options (stock helix rejects them: going back means reverting them, see above), all checked in a running helix:

- **Breadcrumb** (`[editor.breadcrumb]`): the file name and the symbols around the cursor above the text, such as `setup-lib.sh >  enable_system`. Only the file name, since the full path crowds a half-screen tile.
- **Inline blame** (`[editor.inline-blame]`): who last changed the cursor's line, at its end (`T-450, 6 days ago • Reproducible install: …`), fetched in the background as the file opens (`auto-fetch`; otherwise it waits for `space B`).
- **Command line as a popup** (`[editor.cmdline] style = "popup"`): `:` opens a box in the middle, noice.nvim style.
- **File tree** (`[editor.explorer]`): `space x` opens a 30-column tree pinned on the left, which narrows the splits beside it, and `space X` the same tree floating. In it, `j`/`k` move, `l` or Enter opens, `h` folds, `/` filters (`*.rs` patterns too), `a`/`r`/`d` create, rename and delete (delete asks first), `H` shows or hides dotfiles, `Esc` goes back to the text and `q` closes it. Dotfiles are shown (`show-hidden`), since this repo's files live under `.config/`, and the tree opens on the current file (`auto-reveal`, like neo-tree's follow-current-file).
- **Icons** (`[icons.mime]`, `[icons.kind]`, JetBrains Mono Nerd Font): in the file tree, the buffer picker, the breadcrumb and completion. The file picker and the `space e` explorer don't draw them.
- **Square corners and rainbow brackets** (`rounded-corners = false`, `rainbow-brackets` under `[editor]`): popups and pickers keep square corners, like mango's window borders. Notification popups take theirs from `[editor.notifications.border] radius = 0`, and cast no shadow (`[editor.notifications.shadow] enable = false`: the fork paints it as a solid black block).

Left at the fork's defaults: the welcome screen and popup notifications (both on), and folding (`z f`/`z F`/`z A-f`, the fork's own keys). Not used: gradient picker borders, which take hex colors (the repo writes no color literals outside palettes; helix's colors come from the palette through `palette.toml.tmpl`).

## Diagnostics and debugging

Diagnostics show at the end of their line from hints up (`end-of-line-diagnostics`), and in full under the cursor's line from warnings up (`[editor.inline-diagnostics]`; the fork draws those lines only with `show-virtual-lines = true`), so a half-screen tile stays readable; `space u d` hides the end-of-line ones. Debugging uses helix's built-in templates for the debuggers mise installs (delve for Go, netcoredbg for C#; lldb-dap for Rust, C and C++ from `clang/`): `space G`.

To check a language, run `helix --health LANG` in a terminal. No language server, formatter or debugger line shows ✘, except javascript's debugger `''`, which is helix's own placeholder. `tests/unit.d/toolchain-test.sh` runs this check for every language.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`helix/packages`): `jdtls` (AUR: Java language server; no mise backend ships it (Eclipse's file names are timestamped)), `jre-openjdk` (jdtls's runtime: jdtls needs java-runtime>=21, which the headless JRE does not provide; without this yay picks jdk-openjdk)

**Built here** (`helix/pkg/*/PKGBUILD`, makepkg): `helix-gj1118`

**Linked into your home** (stow, `install.sh --link`):

- `~/.config/helix/config.toml`
- `~/.config/helix/languages.toml`
- `~/.config/helix/themes/palette.toml`

**Rendered from the palette** (`theme`):

- `helix/.config/helix/languages.toml.tmpl` → `helix/.config/helix/languages.toml`: `home`
- `helix/.config/helix/themes/palette.toml.tmpl` → `helix/.config/helix/themes/palette.toml`: `accent`, `ansi10`, `ansi11`, `ansi12`, `ansi13`, `ansi2`, `ansi3`, `ansi4`, `ansi5`, `ansi6`, `ansi9`, `bg_hover`, `bg_surface`, `bg_widget`, `border_hairline`, `border_inactive`, `diff_add`, `diff_change`, `diff_remove`, `error`, `fg_bright`, `fg_disabled`, `fg_editor`, `fg_muted`, `fg_secondary`, `info`, `name`, `selection_bg`, `selection_fg`, `syn_boolean`, `syn_comment`, `syn_constant`, `syn_function`, `syn_keyword`, `syn_number`, `syn_operator`, `syn_preproc`, `syn_special`, `syn_string`, `syn_type`, `term_bg`, `warning`

**`reload.sh`** (run by `theme set`): running helix editors re-read config.toml and the rendered themes/palette.toml; helix reloads its config on SIGUSR1, as :config-reload does. The process is `helix` (the /usr/bin link's name), not `hx`, the binary it points to.
<!-- end generated -->

# helix

Helix, a modal editor set up for every language in the toolchain, with Vim and AstroNvim keys added where helix binds nothing (four named exceptions), inline diagnostics, and VS Code's Dark+ theme (built into helix, with its own colors rather than the palette's).

Helix here is [gj1118's fork](https://github.com/gj1118/helix): upstream helix (it reports itself as `helix 25.07.1`) with merged pull requests for a sidebar file tree, icons, inline git blame, breadcrumbs, code folding, a command-line popup and notifications. Neither Arch nor the AUR packages it, and the file tree came after its last release (26.09.02), so `pkg/helix-gj1118/PKGBUILD` builds a pinned master commit (`2610b17`, `pkgver` 26.09.02.r57.g2610b17) from source, the way Arch builds helix: the commit's tarball checked by SHA-256, cargo with the locked dependencies, and helix's build script, which fetches each of the 301 tree-sitter grammars at the git revision `languages.toml` pins and compiles it. The build takes about 8 minutes on this laptop; makepkg installs `cargo` and `git` for it and removes what it installed afterwards. It installs in Arch's own layout: `/usr/lib/helix-gj1118/hx` beside `runtime/`, `/usr/bin/helix` a link, the desktop file and completions renamed `hx` to `helix`. It replaces Arch's `helix` (`provides`/`conflicts`). It went in after a day of editing C#, TypeScript and Go showed no regression from its open issue [#94](https://github.com/gj1118/helix/issues/94) (completion and fuzzy matching). Its version is the PKGBUILD's `pkgver` (`docs/reference/installed.md` lists only `packages` entries). To move to another commit or a tag, change `_commit`, `pkgver` and the tarball's sha256 together, then check `helix --health` and the keys below against the new keymap.

`explorer-shift-keys.patch` fixes one bug of the fork: the file tree ignored every key that came with Shift, which a typed capital letter does, so `G`, `H`, `R` and `A` did nothing. The patch drops Shift from letter keys there, as helix's editor already does (`canonicalize_key`), and is proposed to the fork as [#104](https://github.com/gj1118/helix/pull/104). Once the fork changes those lines, the patch stops applying and the build fails: delete the patch and its `source` and `sha256sums` entries.

On a machine that has Arch's `helix`, swap once by hand: `sudo pacman -Rns helix`, then `./install.sh` (its makepkg runs with `--noconfirm`, which would refuse to remove the conflicting package). A fresh install never has Arch's `helix`. To go back: `sudo pacman -Rdd helix-gj1118 && sudo pacman -S helix`, then revert the fork's commits (`config.toml` without the fork's options loads on stock helix) and `./install.sh`.

mise installs the language servers, formatters and debuggers (and yamlfmt, which the fork formats yaml with), except clangd and jdtls, which pacman installs. Start helix from a terminal, because only zsh puts mise's tools on `PATH` ([mise](mise.md#programs-started-outside-a-terminal-dont-see-the-tools)). `languages.toml` names a server only where helix's built-in choice is not the one installed:

- Python uses ty and ruff.
- TypeScript, TSX, JavaScript, JSX, JSON and JSONC format with biome (`biome lsp-proxy`). typescript-language-server and vscode-json-language-server still give hover, completion and diagnostics, with formatting off.
- typescript-language-server runs TypeScript 6's tsserver, because TypeScript 7 ships none. `tsc` on `PATH` is TypeScript 7.
- C# uses roslyn-language-server, TOML uses tombi, YAML uses yaml-language-server, and Markdown uses marksman.
- CMake uses neocmakelsp; Meson (helix's built-in choice) uses mesonlsp. Both come from mise. mesonlsp's upstream was archived in August 2026 at 5.0.4; it still works, and no other Meson server exists.

Go, Rust, Zig, C, C++, Java and Bash use helix's built-in servers. `theme` renders `languages.toml` from `languages.toml.tmpl`, because the tsserver path contains your home directory.

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

mango's Alt keys reach mango before helix, which hides four helix commands: Alt+s (split selection on newlines), Alt+e (end of the parent syntax node), Alt+x (shrink to line bounds) and Alt+a (select all siblings). Run them from `space ?` by name. Alt+o/i/p/n (expand, shrink, previous, next syntax node) stay helix's, so Alt+arrows, which mango also takes, lose nothing.

## The fork's options

The end of `config.toml` turns on gj1118's options (stock helix rejects them: going back means reverting them, see above), all checked in a running helix:

- **Breadcrumb** (`[editor.breadcrumb]`): the file name and the symbols around the cursor above the text, such as `setup-lib.sh >  enable_system`. Only the file name, since the full path crowds a half-screen tile.
- **Inline blame** (`[editor.inline-blame]`): who last changed the cursor's line, at its end (`T-450, 6 days ago • Reproducible install: …`), fetched in the background as the file opens (`auto-fetch`; otherwise it waits for `space B`).
- **Command line as a popup** (`[editor.cmdline] style = "popup"`): `:` opens a box in the middle, noice.nvim style.
- **File tree** (`[editor.explorer]`): `space x` opens a 30-column tree pinned on the left, which narrows the splits beside it, and `space X` the same tree floating. In it, `j`/`k` move, `l` or Enter opens, `h` folds, `/` filters (`*.rs` patterns too), `a`/`r`/`d` create, rename and delete (delete asks first), `H` shows or hides dotfiles, `Esc` goes back to the text and `q` closes it. Dotfiles are shown (`show-hidden`), since this repo's files live under `.config/`, and the tree opens on the current file (`auto-reveal`, like neo-tree's follow-current-file).
- **Icons** (`[icons.mime]`, `[icons.kind]`, JetBrains Mono Nerd Font): in the file tree, the buffer picker, the breadcrumb and completion. The file picker and the `space e` explorer don't draw them.
- **Square corners and rainbow brackets** (`rounded-corners = false`, `rainbow-brackets` under `[editor]`): popups and pickers keep square corners, like mango's window borders. Notification popups take theirs from `[editor.notifications.border] radius = 0`.

Left at the fork's defaults: the welcome screen and popup notifications (both on), and folding (`z f`/`z F`/`z A-f`, the fork's own keys). Not used: gradient picker borders, which take hex colors (the repo writes no color literals, and helix's colors come from `dark_plus`, not the palette).

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

**Rendered from the palette** (`theme`):

- `helix/.config/helix/languages.toml.tmpl` → `helix/.config/helix/languages.toml`: `home`
<!-- end generated -->

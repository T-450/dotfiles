# pi

Pi, the coding agent (`pi`), with the LazyPi extension catalog and a theme for every palette.

Pi comes from AUR (`pi-coding-agent-bin`, the release binary), so LazyPi doesn't install it with `npm -g`. `setup.sh` runs `npx @robzolkos/lazypi --yes` (pinned, through mise's node) to install the whole catalog through `pi install`: sub-agents, ask-user, web access, memory, plan, simplify, add-dir, prompt templates, the Claude Code CLI provider, plannotator, diff review, powerbar, usage, raw paste, tasks, side chat, shell overlays, the research loops, Compound Engineering (skipped without bun) and three theme packs. It runs again only when the pinned version changes (`pi/lazypi.stamp`); `npx @robzolkos/lazypi status`, `update`, `remove ID` and `doctor` manage it by hand.

Themes: `{palette}.json.tmpl` renders once per palette into `~/.pi/agent/themes/` (`dark-2026`, `light-2026`, `tokyo-night`); catppuccin-mocha isn't linked, because LazyPi's curated theme pack ships its own. `setup.sh` sets Pi's `theme` to `light-2026/dark-2026`, so Pi takes Light 2026 on a light terminal and Dark 2026 on a dark one, and switches when `theme set` changes Ghostty's background. Pi hot-reloads them; another palette's theme is one `/settings` pick away.

Look: Claude Code's, from `pi-claude-code-ui` (pinned; `setup.sh` installs it after the catalog). Consecutive tool calls fold into one line (`Read 2 files, ran 1 shell command`; Ctrl+O expands), edits show a syntax-highlighted diff with word-level marks, finished thinking collapses to `Thought for Ns`, prompts carry a `❯`, and the spinner names what runs. Bash rows show a label the model writes with each call (`bashIntent: model`, a few output tokens per call; `/cc-tools intent off` turns it off). `setup.sh` sets `terminalTheme: false` before the extension first loads, because it would otherwise switch Pi to its `system` theme over the palette pair, plus `themeAdaptive: true` so its diffs, connectors and spinner take the pair's colors, and `quietStartup: "header"` so a session opens on Pi's header without the list of every loaded resource.

The themes use the palette's whole terminal color set, each pushed to a 4.5:1 contrast on the background: your messages sit on an accent-tinted band; headings, list bullets, the `!` bash mode and the spinner's verb are the palette's yellow (`spinnerVerbColor: bashMode`; on Light 2026 the yellow that reads on white is amber); tool titles are teal, links blue, inline code orange, quote bars violet; code takes GitHub's syntax roles (keywords and operators red, functions purple, strings and numbers blue, types orange). The editor border heats up with the thinking level: grey, muted, teal, accent, purple, pink, orange.

Mascot: Zero (Mega Man X4 style) stands at the right end of the row above the editor and acts out the run: idle while Pi waits for you, arms crossed while the model thinks, gesturing while it writes, running for read/grep/find/ls, dashing for bash, saber slashes for edit, a combo for write, a jump for web tools, the crescent slash for subagents. One-off moments play over that: he beams in when Pi starts, draws his saber when a run starts, takes a hit when a tool fails, fumes when you abort a run, fires his giga attack when the context is compacted, and strikes his victory pose when a run finishes. `~/.pi/agent/extensions/mascot/index.ts` draws him with the Kitty graphics protocol (one image id, each frame replaces the last); a terminal without image support shows nothing. `/mascot` hides or shows him, `/mascot POSE` previews a pose, `PI_MASCOT_ROWS` sets his height (5 rows).

The sprites are Capcom's, so they never enter this public repo: `pi-mascot-import SHEET` cuts them from the 735x638 Zero sheet (white background) into `~/.local/share/pi-mascot/zero/` (`frames/*.png`, `poses.json`). The script holds each pose's frame rectangles on that sheet, keys out the white by flood fill from the frame edges (white inside the sprite stays; the saber's large light trail turns translucent) and aligns each pose's frames at the feet. Idle, talk and the moments the sheet lacks come from Fighters Generation's animated GIFs (X3-X5 era, lossless and already transparent, with their own frame timings), downloaded once into `~/.cache/pi-mascot` and cropped to Zero's height so he keeps his size under the teleport beam. Every frame is upscaled 4x with ffmpeg's xBR pixel-art filter (`xbr=4`: smooth contours, crisp highlights), the color and the alpha mask separately, after the sprite's edge colors are bled into the transparent area (a GIF's hidden key color would otherwise show as a fringe); frames from the JPEG sheet are denoised with `nlmeans` first so xBR doesn't trace compression noise. Pi reads the frames at startup: `/reload` after an import. Without the import, the extension stays off. Spriters Resource (for an official X4 sheet) refuses scripted downloads, so a sheet from there has to be saved from a browser.

Key: Pi reads the Anthropic key from `$ANTHROPIC_API` (`auth.json`: `"key": "!printenv ANTHROPIC_API"`, set by `setup.sh` unless `/login` already saved one). The key itself lives in `~/.config/zsh/private.zsh` (see [zsh](zsh.md)), so a Pi started outside a zsh session has none. Pi writes `settings.json` and `auth.json` itself, so the repo doesn't link them; `setup.sh` only sets those two keys.

## Reference

<!-- generated by tools/docs: reference -->
**Packages** (`pi/packages`): `pi-coding-agent-bin` (Pi, the coding agent (AUR: the npm release as one binary)), `ripgrep` (Pi's faster in-repository search (its optional dependency)), `python-pillow` (pi-mascot-import cuts the mascot's sprite sheet), `ffmpeg` (pi-mascot-import upscales the sprites with its xBR filter)

**Linked into your home** (stow, `install.sh --link`):

- `~/.local/bin/pi-mascot-import`
- `~/.pi/agent/extensions/mascot/index.ts`
- `~/.pi/agent/themes/{palette}.json`

**Rendered from the palette** (`theme`):

- `pi/.pi/agent/themes/{palette}.json.tmpl` → `pi/.pi/agent/themes/{palette}.json`: `accent`, `ansi1`, `ansi11`, `ansi12`, `ansi13`, `ansi3`, `ansi4`, `ansi5`, `ansi6`, `bg_widget`, `border_hairline`, `border_inactive`, `error`, `fg_bright`, `fg_editor`, `fg_muted`, `fg_secondary`, `fg_text`, `link`, `slug`, `success`, `term_bg`, `variant`, `warning`

**`setup.sh`** (run by `install.sh --setup`): Pi's extensions (the LazyPi catalog), its theme pair (the repo's palettes, rendered into ~/.pi/agent/themes) and its Anthropic key source. Pi writes settings.json and auth.json itself (/settings, /login, pi install), so the repo sets only these keys in them.
<!-- end generated -->

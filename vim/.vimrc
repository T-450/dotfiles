" vim, the fallback editor for quick edits and project file jumps (helix is the full one). Colors: the palette.
" A user vimrc stops vim loading defaults.vim by itself (syntax, mouse, incsearch, ...): keep them.
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

" Clipboard: Arch's vim is built without X11 and Wayland support, so the + and * registers go
" through wl-copy/wl-paste (a clipboard provider, :h clipboard-providers), and y/p use the system
" clipboard like every other app. In Ghostty, Ctrl+V pastes too (Ctrl+Shift+Alt+V is a literal ^V).
function s:Available()
	return !empty($WAYLAND_DISPLAY) && executable('wl-copy')
endfunction
function s:Copy(reg, type, lines)
	silent call system(a:reg == '*' ? 'wl-copy --primary' : 'wl-copy', a:lines)
endfunction
function s:Paste(reg)
	silent let lines = systemlist(a:reg == '*' ? 'wl-paste --primary --no-newline' : 'wl-paste --no-newline')
	return ['', lines]
endfunction
let v:clipproviders['wl'] = {
	\ 'available': function('s:Available'),
	\ 'copy': {'+': function('s:Copy'), '*': function('s:Copy')},
	\ 'paste': {'+': function('s:Paste'), '*': function('s:Paste')},
	\ }
set clipmethod^=wl
set clipboard=unnamedplus

" Editing: line numbers, case-smart search, splits open right and below.
set number cursorline ignorecase smartcase hlsearch splitright splitbelow
set termguicolors laststatus=2 noshowmode sidescrolloff=8
" No ~ past the end: a highlight cannot hide them, Ghostty's minimum-contrast redraws the ground color.
set fillchars+=eob:\ ,vert:│
" [3/12] after a search; long lines wrap at words, indented like their first line.
set shortmess-=S
set linebreak breakindent
let &showbreak = '↪ '
" Tabs show as an indent guide, trailing blanks as dots; space indents get guides from Guides().
set list listchars=tab:│\ ,trail:·,nbsp:␣,extends:…,precedes:…
" Completion: popup menus with fuzzy matching, on the : line as you type and in insert mode.
set wildmode=noselect:lastused,full wildoptions=pum,fuzzy pumheight=12
set completeopt=menuone,noselect,popup,fuzzy complete=.,w,b autocomplete autocompletedelay=150

" The statusline opens with the mode, in a color per mode (the palette's Status* groups).
let s:modes = {
	\ 'n': ['NORMAL', 'StatusNormal'], 'i': ['INSERT', 'StatusInsert'],
	\ 'v': ['VISUAL', 'StatusVisual'], 'V': ['V-LINE', 'StatusVisual'], "\<C-v>": ['V-BLOCK', 'StatusVisual'],
	\ 'R': ['REPLACE', 'StatusReplace'], 'c': ['COMMAND', 'StatusCommand'], 't': ['TERMINAL', 'StatusInsert'],
	\ 's': ['SELECT', 'StatusVisual'], 'S': ['S-LINE', 'StatusVisual'], "\<C-s>": ['S-BLOCK', 'StatusVisual'],
	\ }
function s:Statusline()
	let [name, group] = get(s:modes, mode(), ['NORMAL', 'StatusNormal'])
	let chip = g:statusline_winid == win_getid() ? '%#' .. group .. '# ' .. name .. ' %* ' : ' '
	return chip .. '%f %m%r%h%w%=%y  %l:%c/%L '
endfunction
let &statusline = '%!' .. expand('<SID>') .. 'Statusline()'

" Undo survives closing the file; undo, swap and backup files stay out of the file's directory.
for s:dir in ['undo', 'swap', 'backup']
	call mkdir(expand('~/.local/state/vim/' .. s:dir), 'p', 0o700)
endfor
set undofile undodir=~/.local/state/vim/undo//
set directory=~/.local/state/vim/swap// backupdir=~/.local/state/vim/backup//

" Bundled with vim: gc comments, .editorconfig, a flash on yank, search highlight clears itself.
packadd! comment
packadd! editorconfig
packadd! hlyank
packadd! nohlsearch

" Colors: the active palette, rendered by `theme`. Vim has no reload signal, so a running vim
" picks up `theme set` the next time its terminal gains focus (Ghostty reports focus).
let s:colors = expand('~/.vim/colors/palette.vim')
function s:Colors()
	if !filereadable(s:colors) || get(s:, 'stamp', -1) == getftime(s:colors)
		return
	endif
	let s:stamp = getftime(s:colors)
	colorscheme palette
endfunction
call s:Colors()

" Formatters and linters from mise, set only when vim can run them (started from zsh): gq and
" space f format, :make (space m) lints into the quickfix list. A linter is a compiler plugin
" (its errorformat); :make runs its makeprg on the file.
let s:tools = {
	\ 'sh': ['shfmt --filename=%:S', 'shellcheck'],
	\ 'bash': ['shfmt --filename=%:S', 'shellcheck'],
	\ 'python': ['ruff format --stdin-filename=%:S -', 'ruff'],
	\ 'javascript': ['biome format --stdin-file-path=%:S', 'biome'],
	\ 'typescript': ['biome format --stdin-file-path=%:S', 'biome'],
	\ 'json': ['biome format --stdin-file-path=%:S', 'biome'],
	\ 'jsonc': ['biome format --stdin-file-path=%:S', 'biome'],
	\ 'yaml': ['yamlfmt -', ''],
	\ 'markdown': ['prettier --stdin-filepath=%:S', ''],
	\ 'go': ['gofmt', 'go'],
	\ 'rust': ['rustfmt --edition=2024', 'cargo'],
	\ 'zig': ['zig fmt --stdin', 'zig'],
	\ 'toml': ['tombi format -', 'tombi'],
	\ }
" Linters whose plugin runs the wrong command: [the program, the whole command, an errorformat
" line to put first, for its own failures]. go's plugin runs
" `go build` (a binary left next to a main package); golangci-lint lints the file's package and must
" run inside its module. cargo's plugin runs plain cargo: clippy lints the crate, and reports paths
" from the workspace root, so vim should run from there. zig's plugin runs `zig <args> file`.
" vim's tombi plugin misreads tombi 1's version line and pipes through sed, which :make cannot run.
let s:makeprg = {
	\ 'go': ['golangci-lint', 'cd %:p:h:S && golangci-lint run --show-stats=false --path-mode=abs --output.text.print-issued-lines=false --output.text.colors=false .', 'level=error msg="%m"'],
	\ 'cargo': ['cargo', 'cargo clippy --quiet --message-format=short'],
	\ 'zig': ['zig', 'zig ast-check %:S'],
	\ 'tombi': ['tombi', 'env NO_COLOR=1 tombi lint %:S'],
	\ }

" The program a filetype's linter runs: the override's, or the compiler plugin's namesake.
function s:Linter()
	let compiler = get(s:tools, &filetype, ['', ''])[1]
	return get(s:makeprg, compiler, [compiler])[0]
endfunction

function s:Tools()
	let [fmt, compiler] = get(s:tools, &filetype, ['', ''])
	if !empty(fmt) && executable(split(fmt)[0])
		let &l:formatprg = fmt
	endif
	if !empty(compiler) && executable(s:Linter())
		execute 'compiler' compiler
		let [cmd, efm] = (get(s:makeprg, compiler, ['', &l:makeprg .. ' %:S']) + [''])[1:2]
		let &l:makeprg = cmd
		if !empty(efm)
			let &l:errorformat = efm .. ',' .. &l:errorformat
		endif
	endif
endfunction

" Why a filetype has no formatter or linter: none in s:tools, or its tool is not on PATH.
function s:Missing(kind)
	let tool = a:kind == 'formatter' ? get(s:tools, &filetype, [''])[0] : s:Linter()
	if empty(tool)
		return 'no ' .. a:kind .. ' for ' .. (empty(&filetype) ? 'this file' : &filetype)
	endif
	return split(tool)[0] .. ' is not on PATH: start vim from a terminal (mise)'
endfunction

" A formatter's error in one line: its first two lines without colors, rules or the file's
" directory (biome puts the location on one line and the reason on the next).
function s:Summary(lines)
	let lines = map(copy(a:lines), {_, l -> trim(substitute(substitute(l, '\e\[[0-9;]*m', '', 'g'), '━\+', '', 'g'))})
	let lines = filter(lines, '!empty(v:val)')[:1]
	return empty(lines) ? 'failed, the file is unchanged' : substitute(join(lines, ' · '), '\f*/', '', 'g')
endfunction

" One screen line, so a message never stops at a Press ENTER prompt.
function s:Fit(msg)
	return strdisplaywidth(a:msg) < v:echospace ? a:msg : strcharpart(a:msg, 0, v:echospace - 2) .. '…'
endfunction

function s:Say(group, msg)
	execute 'echohl' a:group | echo a:msg | echohl None
endfunction

" The whole buffer through formatprg; a failing formatter (a syntax error) leaves it as it was
" and says why, where gq would put the error text in the buffer. Every outcome is reported.
function s:Format()
	if empty(&l:formatprg)
		call s:Say('WarningMsg', s:Missing('formatter'))
		return
	endif
	if empty(bufname()) && stridx(&l:formatprg, '%') >= 0
		echo 'save the file first: the formatter reads its name'
		return
	endif
	" stderr apart: a formatter may warn on stderr and still succeed (systemlist would keep both)
	let err = tempname()
	let out = systemlist(expandcmd(&l:formatprg) .. ' 2>' .. shellescape(err), getline(1, '$'))
	let msg = filereadable(err) ? readfile(err) : []
	call delete(err)
	let tool = split(&l:formatprg)[0]
	if v:shell_error
		call s:Say('ErrorMsg', s:Fit(tool .. ': ' .. s:Summary(msg)))
		return
	endif
	if out ==# getline(1, '$')
		call s:Say('MoreMsg', tool .. ': already formatted')
		return
	endif
	let view = winsaveview()
	silent keepjumps call deletebufline('', len(out) + 1, '$')
	silent keepjumps call setline(1, out)
	call winrestview(view)
	call s:Say('MoreMsg', tool .. ': formatted')
endfunction

" Save, lint into the quickfix list (opened when there is something in it), and say the count.
function s:Lint()
	if empty(get(b:, 'current_compiler', ''))
		call s:Say('WarningMsg', s:Missing('linter'))
		return
	endif
	let linter = s:Linter()
	update
	silent make
	cwindow
	redraw!
	" a problem points into a file; an error that points nowhere is the linter itself failing
	" (cargo outside a crate, golangci-lint outside a module)
	let errors = filter(getqflist(), 'v:val.valid')
	let n = len(filter(copy(errors), 'v:val.bufnr'))
	if n
		call s:Say('WarningMsg', linter .. ': ' .. n .. (n == 1 ? ' problem' : ' problems'))
	elseif !empty(errors)
		call s:Say('ErrorMsg', s:Fit(linter .. ': ' .. s:Summary(map(errors, 'v:val.text'))))
	else
		call s:Say('MoreMsg', linter .. ': no problems')
	endif
endfunction

" Markdown: wraps at words, continues - * + lists and > quotes on Enter and o, and renders in
" place (markers hidden, links as their text) except on the cursor line; space r shows the source.
" Fenced code takes the language's colors; json's own conceal would hide its quotes there.
let g:markdown_fenced_languages = ['sh', 'bash=sh', 'zsh', 'python', 'py=python', 'json', 'jsonc',
	\ 'toml', 'yaml', 'go', 'rust', 'zig', 'javascript', 'js=javascript', 'typescript', 'ts=typescript',
	\ 'lua', 'vim', 'diff', 'ini=dosini', 'conf', 'systemd', 'html', 'css', 'sql']
let g:vim_json_conceal = 0
function s:Markdown()
	setlocal wrap conceallevel=2 concealcursor= comments=b:*,b:-,b:+,n:> formatoptions+=ro
endfunction

" Vim's markdown syntax hides emphasis and fence markers; this adds headings' #, code's backticks,
" a link's brackets and URL, and draws bullets as •.
function s:MarkdownSyntax()
	for n in range(1, 6)
		execute printf('syn region markdownH%d matchgroup=markdownH%dDelimiter start=" \{,3}%s\s" end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained concealends', n, n, repeat('#', n))
	endfor
	syn region markdownCode matchgroup=markdownCodeDelimiter start="``\@!" end="`" keepend contains=markdownLineStart concealends
	syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\_[^][]*\%(\[\_[^][]*\]\_[^][]*\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
	syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
	syn match markdownListMarker "[-*+]\%(\s\+\S\)\@=" contained conceal cchar=•
	" a nested marker: its indent stays, so the bullet is a separate item after it
	syn match markdownListIndent "\%(\t\| \{1,4\}\)\%([-*+]\s\+\S\)\@=" contained nextgroup=markdownListMarker
	syn cluster markdownBlock add=markdownListIndent
endfunction

" Enter on an empty list item ends the list instead of starting another.
function s:MarkdownEnter()
	return getline('.') =~ '^\s*\%([-*+]\|>\)\s*$' ? "\<C-u>" : "\<CR>"
endfunction

function s:Render()
	let &l:conceallevel = &l:conceallevel ? 0 : 2
	echo 'render ' .. (&l:conceallevel ? 'on' : 'off: the source')
endfunction

" Indent guides for space indents follow the buffer's shiftwidth (editorconfig may set it late).
function s:Guides()
	let width = shiftwidth()
	let &l:listchars = &g:listchars .. (width > 1 ? ',leadmultispace:│' .. repeat(' ', width - 1) : '')
endfunction

" :find (space space) fuzzy-matches the project's files: fd lists them (honoring .gitignore)
" once per command line, matchfuzzy ranks them as you type.
let s:files = []
function s:Find(arg, complete)
	if empty(s:files)
		let s:files = systemlist('fd --type file --hidden --exclude .git --strip-cwd-prefix --max-results 50000')
	endif
	return empty(a:arg) ? s:files : matchfuzzy(s:files, a:arg)
endfunction
if executable('fd')
	let &findfunc = expand('<SID>') .. 'Find'
endif

augroup vimrc
	autocmd!
	autocmd FileType * call s:Tools()
	autocmd FileType markdown call s:Markdown()
	autocmd FileType markdown inoremap <buffer> <expr> <CR> <SID>MarkdownEnter()
	autocmd Syntax markdown call s:MarkdownSyntax()
	autocmd BufWinEnter * call s:Guides()
	autocmd OptionSet shiftwidth,tabstop call s:Guides()
	autocmd FocusGained * call s:Colors()
	" with noshowmode, vim does not redraw the statusline's mode by itself
	autocmd ModeChanged * redrawstatus
	autocmd CmdlineEnter : let s:files = []
	autocmd CmdlineChanged : call wildtrigger()
augroup END

" Keys: one table makes both the mappings and the space ? cheatsheet. An entry without a command
" is vim's own key, listed so the sheet is complete; a : command stays visible to be completed.
let mapleader = ' '
let s:keys = [
	\ ['Files'],
	\ ['<Space><Space>', ':find ', 'open a project file (fuzzy)'],
	\ ['<Space>b', ':buffer ', 'switch to an open buffer (fuzzy)'],
	\ ['<Space>e', '<Cmd>Explore<CR>', 'browse the file''s directory (netrw)'],
	\ ['<Space>w', '<Cmd>update<CR>', 'save'],
	\ ['Code'],
	\ ['<Space>f', '<ScriptCmd>call s:Format()<CR>', 'format the file'],
	\ ['gq{motion}', '', 'format a range with the same formatter'],
	\ ['<Space>m', '<ScriptCmd>call s:Lint()<CR>', 'save and lint into the quickfix list'],
	\ [']q', '<Cmd>cnext<CR>', 'next quickfix entry'],
	\ ['[q', '<Cmd>cprevious<CR>', 'previous quickfix entry'],
	\ ['gcc / gc{motion}', '', 'comment or uncomment lines'],
	\ ['<C-n> / <C-p>', '', 'next / previous completion (insert mode)'],
	\ ['View'],
	\ ['<Space>r', '<ScriptCmd>call s:Render()<CR>', 'markdown: rendered or source'],
	\ ['<Space>?', '<ScriptCmd>call s:Cheatsheet()<CR>', 'this sheet'],
	\ ['j / k', '', 'move by screen line through wrapped text'],
	\ ['<C-w>v / <C-w>s', '', 'split right / below'],
	\ ['<C-o> / <C-i>', '', 'back / forward through jumps'],
	\ ]
for s:key in s:keys
	if len(s:key) > 2 && !empty(s:key[1])
		execute 'nnoremap' (s:key[1] =~ '^:' ? '' : '<silent>') s:key[0] s:key[1]
	endif
endfor
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

function s:Cheatsheet()
	let lines = []
	for key in s:keys
		if len(key) == 1
			let lines += (empty(lines) ? [] : ['']) + [key[0]]
		else
			let lines += [printf('  %-18s %s', substitute(key[0], '<Space>', 'space ', 'g'), key[2])]
		endif
	endfor
	let id = popup_create(lines, #{
		\ title: ' keys · any key closes ', border: [], padding: [0, 1, 0, 1],
		\ highlight: 'Pmenu', borderhighlight: ['PopupBorder'], borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
		\ mapping: 0, filter: {id, _ -> [popup_close(id), 1][1]},
		\ })
	call win_execute(id, 'syntax match Title /^\S.*/')
endfunction

" vim, the fallback editor for quick single-file edits (helix is the full one). Colors: the palette.
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
set number ignorecase smartcase hlsearch splitright splitbelow
set termguicolors laststatus=2
" No ~ past the end: a highlight cannot hide them, Ghostty's minimum-contrast redraws the ground color.
set fillchars+=eob:\ 
set statusline=\ %f\ %m%r%h%w%=%y\ \ %l:%c/%L\ 

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
" space f format, :make (space m) lints into the quickfix list.
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
	\ 'rust': ['rustfmt --edition=2024', ''],
	\ 'zig': ['zig fmt --stdin', ''],
	\ 'toml': ['tombi format -', 'tombi'],
	\ }
" go's compiler plugin runs `go build`, which leaves a binary next to a main package; vim's tombi
" plugin misreads tombi 1's version line and pipes through sed, which :make cannot run.
let s:makeprg = {'go': 'go vet', 'tombi': 'env NO_COLOR=1 tombi lint'}
function s:Tools()
	let [fmt, lint] = get(s:tools, &filetype, ['', ''])
	if !empty(fmt) && executable(split(fmt)[0])
		let &l:formatprg = fmt
	endif
	if !empty(lint) && executable(lint)
		execute 'compiler' lint
		if has_key(s:makeprg, lint)
			let &l:makeprg = s:makeprg[lint]
		endif
	endif
endfunction

" The whole buffer through formatprg; a failing formatter (a syntax error) leaves it as it was
" and says why, where gq would put the error text in the buffer.
function s:Format()
	if empty(&l:formatprg)
		echo 'no formatter for ' .. (empty(&filetype) ? 'this file' : &filetype)
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
	if v:shell_error
		echohl ErrorMsg | echo get(msg, 0, 'formatter failed') | echohl None
		return
	endif
	if out ==# getline(1, '$')
		return
	endif
	let view = winsaveview()
	silent keepjumps call deletebufline('', len(out) + 1, '$')
	silent keepjumps call setline(1, out)
	call winrestview(view)
endfunction

augroup vimrc
	autocmd!
	autocmd FileType * call s:Tools()
	autocmd FocusGained * call s:Colors()
augroup END

let mapleader = ' '
nnoremap <silent> <Leader>f <ScriptCmd>call s:Format()<CR>
nnoremap <silent> <Leader>m <Cmd>update <Bar> silent make %:S <Bar> cwindow <Bar> redraw!<CR>
nnoremap ]q <Cmd>cnext<CR>
nnoremap [q <Cmd>cprevious<CR>

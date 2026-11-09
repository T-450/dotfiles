" vim, the fallback editor. Colors follow the terminal's palette (kitty).
" A user vimrc stops vim loading defaults.vim by itself (syntax, mouse, incsearch, ...): keep them.
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

" Clipboard: Arch's vim is built without X11 and Wayland support, so the + and * registers go
" through wl-copy/wl-paste (a clipboard provider, :h clipboard-providers), and y/p use the system
" clipboard like every other app. In kitty, Ctrl+V pastes too (Ctrl+Shift+Alt+V is a literal ^V).
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

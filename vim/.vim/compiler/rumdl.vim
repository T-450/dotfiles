" rumdl, the markdown linter (mise): :make lints the file into the quickfix list.
if exists('current_compiler')
	finish
endif
let current_compiler = 'rumdl'
CompilerSet makeprg=rumdl\ check\ --quiet\ --color\ never
CompilerSet errorformat=%f:%l:%c:\ %m,%-G%.%#

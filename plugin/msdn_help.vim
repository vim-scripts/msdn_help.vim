" msdn_help.vim -- provide look up msdn(dexplorer.exe) help.
" 
" version : 0.0.1
" author : ampmmn(htmnymgw <delete>@<delete> gmail.com)
" url    : http://d.hatena.ne.jp/ampmmn

if exists('loaded_msdn_help') || &cp
  finish
endif
let loaded_msdn_help=1

if !has('python')
	echo "Error: Required Vim compiled with +python"
	finish
endif

python << END_OF_PY
# coding:cp932
def search_msdn(keyword):
	try: import win32com.client
	except: return 1

	versions = ( ("9.0","v90"),("8.0","v80"),("7","2003") )
	curVer=None
	for ver in versions:
		try:
			obj = win32com.client.GetActiveObject("DExplore.AppObj."+ver[0])
			curVer=ver
			break
		except: continue
	if curVer==None: return 2
	
	obj.SetCollection("ms-help://ms.vscc."+curVer[1], '')
	obj.Contents()
	obj.DisplayTopicFromF1Keyword(keyword)
	obj.SyncIndex(keyword,1)
	obj.IndexResults
	return 0
END_OF_PY

function! <SID>msdn_help(keyword)
	if !has('win32')
		echohl ErrorMsg
		echo "Error: msdn_help.vim is Windows only."
		echohl None
		return 1
	endif
	if a:keyword==''
		return 1
	endif

let g:msdnh_result = 0

python << END_OF_PY2
# coding:cp932
import vim
n = search_msdn(vim.eval("a:keyword"))
vim.command("let g:msdnh_result=" + str(n))
END_OF_PY2

if g:msdnh_result != 0
	echohl ErrorMsg
	if g:msdnh_result == 1| echo "Error: msdn_help.vim need Python Win32 Extensions." | endif
	if g:msdnh_result == 2| echo "Error: Can not detect DExplore.exe instance." | endif
	echohl None
endif

unlet g:msdnh_result

endfunction

" http://vim.g.hatena.ne.jp/keyword/%e9%81%b8%e6%8a%9e%e3%81%95%e3%82%8c%e3%81%9f%e3%83%86%e3%82%ad%e3%82%b9%e3%83%88%e3%81%ae%e5%8f%96%e5%be%97
function! s:getSelectedText()
  let [visual_p, pos] = [mode() =~# "[vV\<C-v>]", getpos('.')]
  let [r_, r_t] = [@@, getregtype('"')]
  let [r0, r0t] = [@0, getregtype('0')]
  if &cb == "unnamed"
	  let [rast, rastt] = [@*, getregtype('*')]
  endif


  if visual_p
    execute "normal! \<Esc>"
  endif
  silent normal! gvy
  let [_, _t] = [@@, getregtype('"')]

  call setreg('"', r_, r_t)
  call setreg('0', r0, r0t)
  " restore "* register in 'set cb=unnamed' environment.
  if &cb == "unnamed"
	  call setreg('*', rast, rastt)
  endif
  if visual_p
    normal! gv
  else
    call setpos('.', pos)
  endif
  return a:0 && a:1 ? [_, _t] : _
endfunction

command! MSDNHelpKeyword :call <SID>msdn_help(s:getSelectedText())
command! MSDNHelpCursorText :call <SID>msdn_help(expand("<cword>"))

nnoremap <silent><unique> <space>h :MSDNHelpCursorText<cr>
vnoremap <silent><unique> <space>h :<c-u>MSDNHelpKeyword<cr>



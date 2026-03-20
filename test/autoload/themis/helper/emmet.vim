let s:helper = {}

function! s:helper.setup() abort
  let g:user_emmet_settings = {'variables': {'indentation': "\t", 'use_selection': 1}}
  for f in split(globpath(getcwd(), 'autoload/**/*.vim'), "\n")
    if f =~# 'themis'
      continue
    endif
    silent! exe 'so' f
  endfor
  silent! exe 'so' getcwd() . '/plugin/emmet.vim'
endfunction

function! s:helper.expand_word(query, type) abort
  return emmet#expandWord(a:query, a:type, 0)
endfunction

function! s:helper.expand_in_buffer(query, type, result) abort
  silent! 1new
  silent! exe 'setlocal ft=' . a:type
  EmmetInstall
  let l:key = matchstr(a:query, '.*\$\$\$\$\zs.*\ze\$\$\$\$')
  if len(l:key) > 0
    exe printf('let l:key = "%s"', l:key)
  else
    let l:key = "\<c-y>,"
  endif
  let l:q = substitute(a:query, '\$\$\$\$.*\$\$\$\$', '$$$$', '')
  call setline(1, split(l:q, "\n"))
  let l:cmd = "normal gg0/\\$\\$\\$\\$\ri\<del>\<del>\<del>\<del>" . l:key
  if stridx(a:result, '$$$$') != -1
    let l:cmd .= '$$$$'
  endif
  silent! exe l:cmd
  let l:res = join(getline(1, line('$')), "\n")
  silent! bw!
  return l:res
endfunction

function! themis#helper#emmet#new(runner) abort
  return deepcopy(s:helper)
endfunction

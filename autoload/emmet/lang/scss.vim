function! emmet#lang#scss#findTokens(str) abort
  return emmet#lang#css#findTokens(a:str)
endfunction

function! emmet#lang#scss#parseIntoTree(abbr, type) abort
  if a:abbr =~# '>'
    return emmet#lang#html#parseIntoTree(a:abbr, a:type)
  else
    return emmet#lang#css#parseIntoTree(a:abbr, a:type)
  endif
endfunction

function! emmet#lang#scss#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:settings = a:settings
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = a:indent
  let l:str = ''

  let l:current_name = substitute(l:current.name, '\$$', l:itemno+1, '')
  if len(l:current.name) > 0
    let l:str .= l:current_name
    let l:tmp = ''
    for l:attr in keys(l:current.attr)
      let l:val = l:current.attr[l:attr]
      while l:val =~# '\$\([^#{]\|$\)'
        let l:val = substitute(l:val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
      endwhile
      let l:attr = substitute(l:attr, '\$$', l:itemno+1, '')
      if l:attr ==# 'id'
        let l:str .= '#' . l:val
      elseif l:attr ==# 'class'
        let l:str .= '.' . l:val
      else
        let l:tmp .= l:attr . ': ' . l:val . ';'
      endif
    endfor
    if len(l:tmp) > 0
      let l:str .= " {\n"
      for l:line in split(l:tmp, "\n")
        let l:str .= l:indent . l:line . "\n"
      endfor
    else
      let l:str .= " {\n"
    endif

    let l:inner = ''
    for l:child in l:current.child
      let l:inner .= emmet#toString(l:child, l:type, l:inline, l:filters, l:itemno)
    endfor
    let l:inner = substitute(l:inner, "\n", "\n" . escape(l:indent, '\'), 'g')
    let l:inner = substitute(l:inner, "\n" . escape(l:indent, '\') . '$', '', 'g')
    let l:str .= l:indent . l:inner . "${cursor}\n}\n"
  else
    return emmet#lang#css#toString(l:settings, l:current, l:type, l:inline, l:filters, l:itemno, l:indent)
  endif
  return l:str
endfunction

function! emmet#lang#scss#imageSize() abort
  call emmet#lang#css#imageSize()
endfunction

function! emmet#lang#scss#imageEncode() abort
  return emmet#lang#css#imageEncode()
endfunction

function! emmet#lang#scss#parseTag(tag) abort
  return emmet#lang#css#parseTag(a:tag)
endfunction

function! emmet#lang#scss#toggleComment() abort
  call emmet#lang#css#toggleComment()
endfunction

function! emmet#lang#scss#balanceTag(flag) range abort
  if a:flag == -2 || a:flag == 2
    let l:curpos = [0, line("'<"), col("'<"), 0]
    call setpos('.', l:curpos)
  else
    let l:curpos = emmet#util#getcurpos()
  endif
  if a:flag < 0
    let l:ret = searchpair('}', '', '.\zs{')
  else
    let l:ret = searchpair('{', '', '}', 'bW')
  endif
  if l:ret > 0
    let l:pos1 = emmet#util#getcurpos()[1:2]
    if a:flag < 0
      let l:pos2 = searchpairpos('{', '', '}')
    else
      let l:pos2 = searchpairpos('{', '', '}')
    endif
    let l:block = [l:pos1, l:pos2]
    if emmet#util#regionIsValid(l:block)
      call emmet#util#selectRegion(l:block)
      return
    endif
  endif
  if a:flag == -2 || a:flag == 2
    silent! exe 'normal! gv'
  else
    call setpos('.', l:curpos)
  endif
endfunction

function! emmet#lang#scss#moveNextPrevItem(flag) abort
  return emmet#lang#scss#moveNextPrev(a:flag)
endfunction

function! emmet#lang#scss#moveNextPrev(flag) abort
  call emmet#lang#css#moveNextPrev(a:flag)
endfunction

function! emmet#lang#scss#splitJoinTag() abort
  call emmet#lang#css#splitJoinTag()
endfunction

function! emmet#lang#scss#removeTag() abort
  call emmet#lang#css#removeTag()
endfunction

function! emmet#lang#scss#mergeLines() abort
  call emmet#lang#css#mergeLines()
endfunction

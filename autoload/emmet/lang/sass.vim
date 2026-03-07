function! emmet#lang#sass#findTokens(str) abort
  return emmet#lang#css#findTokens(a:str)
endfunction

function! emmet#lang#sass#parseIntoTree(abbr, type) abort
    return emmet#lang#css#parseIntoTree(a:abbr, a:type)
endfunction

function! emmet#lang#sass#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:settings = a:settings
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = a:indent
  let l:str = ''

  let l:current_name = l:current.name
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
        let l:tmp .= l:attr . ': ' . l:val
      endif
    endfor
    if len(l:tmp) > 0
      let l:str .= "\n"
      for l:line in split(l:tmp, "\n")
        let l:str .= l:indent . l:line . "\n"
      endfor
    else
      let l:str .= "\n"
    endif

    let l:inner = ''
    for l:child in l:current.child
      let l:tmp = emmet#toString(l:child, l:type, l:inline, l:filters, l:itemno, l:indent)
      let l:tmp = substitute(l:tmp, "\n", "\n" . escape(l:indent, '\'), 'g')
      let l:tmp = substitute(l:tmp, "\n" . escape(l:indent, '\') . '$', '${cursor}\n', 'g')
      let l:inner .= l:tmp
    endfor
    if len(l:inner) > 0
      let l:str .= l:indent . l:inner
    endif
  else
    let l:text = emmet#lang#css#toString(l:settings, l:current, l:type, l:inline, l:filters, l:itemno, l:indent)
    let l:text = substitute(l:text, '\s*;\ze\(\${[^}]\+}\)\?\(\n\|$\)', '', 'g')
    return l:text
  endif
  return l:str
endfunction

function! emmet#lang#sass#imageSize() abort
endfunction

function! emmet#lang#sass#imageEncode() abort
endfunction

function! emmet#lang#sass#parseTag(tag) abort
endfunction

function! emmet#lang#sass#toggleComment() abort
endfunction

function! emmet#lang#sass#balanceTag(flag) range abort
  let l:block = emmet#util#getVisualBlock()
  if a:flag == -2 || a:flag == 2
    let l:curpos = [0, line("'<"), col("'<"), 0]
  else
    let l:curpos = emmet#util#getcurpos()
  endif
  let l:n = l:curpos[1]
  let l:ml = len(matchstr(getline(l:n), '^\s*'))

  if a:flag > 0
    if a:flag == 1 || !emmet#util#regionIsValid(l:block)
      let l:n = line('.')
    else
      while l:n > 0
        let l:l = len(matchstr(getline(l:n), '^\s*\ze[a-z]'))
        if l:l > 0 && l:l < l:ml
          let l:ml = l:l
          break
        endif
        let l:n -= 1
      endwhile
    endif
    let l:sn = l:n
    if l:n == 0
      let l:ml = 0
    endif
    while l:n < line('$')
      let l:l = len(matchstr(getline(l:n), '^\s*[a-z]'))
      if l:l > 0 && l:l <= l:ml
        let l:n -= 1
        break
      endif
      let l:n += 1
    endwhile
    call setpos('.', [0, l:n, 1, 0])
    normal! V
    call setpos('.', [0, l:sn, 1, 0])
  else
    while l:n > 0
      let l:l = len(matchstr(getline(l:n), '^\s*\ze[a-z]'))
      if l:l > 0 && l:l > l:ml
        let l:ml = l:l
        break
      endif
      let l:n += 1
    endwhile
    let l:sn = l:n
    if l:n == 0
      let l:ml = 0
    endif
    while l:n < line('$')
      let l:l = len(matchstr(getline(l:n), '^\s*[a-z]'))
      if l:l > 0 && l:l <= l:ml
        let l:n -= 1
        break
      endif
      let l:n += 1
    endwhile
    call setpos('.', [0, l:n, 1, 0])
    normal! V
    call setpos('.', [0, l:sn, 1, 0])
  endif
endfunction

function! emmet#lang#sass#moveNextPrevItem(flag) abort
  return emmet#lang#sass#moveNextPrev(a:flag)
endfunction

function! emmet#lang#sass#moveNextPrev(flag) abort
  let l:pos = search('""\|\(^\s*|\s*\zs\)', a:flag ? 'Wpb' : 'Wp')
  if l:pos == 2
    startinsert!
  elseif l:pos != 0
    silent! normal! l
    startinsert
  endif
endfunction

function! emmet#lang#sass#splitJoinTag() abort
endfunction

function! emmet#lang#sass#removeTag() abort
endfunction

function! emmet#lang#sass#mergeLines() abort
endfunction

function! emmet#lang#slim#findTokens(str) abort
  return emmet#lang#html#findTokens(a:str)
endfunction

function! emmet#lang#slim#parseIntoTree(abbr, type) abort
  return emmet#lang#html#parseIntoTree(a:abbr, a:type)
endfunction

function! emmet#lang#slim#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = emmet#getIndentation(l:type)
  let l:dollar_expr = emmet#getResource(l:type, 'dollar_expr', 1)
  let l:str = ''

  let l:current_name = l:current.name
  if l:dollar_expr
    let l:current_name = substitute(l:current.name, '\$$', l:itemno+1, '')
  endif
  if len(l:current.name) > 0
    let l:str .= l:current_name
    for l:attr in emmet#util#unique(l:current.attrs_order + keys(l:current.attr))
      if !has_key(l:current.attr, l:attr)
        continue
      endif
      let l:Val = l:current.attr[l:attr]
      if type(l:Val) == 2 && l:Val == function('emmet#types#true')
        let l:str .= ' ' . l:attr . '=true'
      else
        if l:dollar_expr
          while l:Val =~# '\$\([^#{]\|$\)'
            let l:Val = substitute(l:Val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          endwhile
        endif
        let l:attr = substitute(l:attr, '\$$', l:itemno+1, '')
        let l:str .= ' ' . l:attr . '="' . l:Val . '"'
      endif
    endfor

    let l:inner = ''
    if len(l:current.value) > 0
      let l:str .= "\n"
      let l:text = l:current.value[1:-2]
      if l:dollar_expr
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
        let l:text = substitute(l:text, '\${nr}', "\n", 'g')
        let l:text = substitute(l:text, '\\\$', '$', 'g')
        let l:str = substitute(l:str, '\$#', l:text, 'g')
      endif
      for l:line in split(l:text, "\n")
        let l:str .= l:indent . '| ' . l:line . "\n"
      endfor
    elseif len(l:current.child) == 0
      let l:str .= '${cursor}'
    endif
    if len(l:current.child) == 1 && len(l:current.child[0].name) == 0
      let l:str .= "\n"
      let l:text = l:current.child[0].value[1:-2]
      if l:dollar_expr
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
        let l:text = substitute(l:text, '\${nr}', "\n", 'g')
        let l:text = substitute(l:text, '\\\$', '$', 'g')
      endif
      for l:line in split(l:text, "\n")
        let l:str .= l:indent . '| ' . l:line . "\n"
      endfor
    elseif len(l:current.child) > 0
      for l:child in l:current.child
        let l:inner .= emmet#toString(l:child, l:type, l:inline, l:filters, l:itemno, l:indent)
      endfor
      let l:inner = substitute(l:inner, "\n", "\n" . escape(l:indent, '\'), 'g')
      let l:inner = substitute(l:inner, "\n" . escape(l:indent, '\') . '$', '', 'g')
      let l:str .= "\n" . l:indent . l:inner
    endif
  else
    let l:str = l:current.value[1:-2]
    if l:dollar_expr
      let l:str = substitute(l:str, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
      let l:str = substitute(l:str, '\${nr}', "\n", 'g')
      let l:str = substitute(l:str, '\\\$', '$', 'g')
    endif
  endif
  if l:str !~# "\n$"
    let l:str .= "\n"
  endif
  return l:str
endfunction

function! emmet#lang#slim#imageSize() abort
  let l:line = getline('.')
  let l:current = emmet#lang#slim#parseTag(l:line)
  if empty(l:current) || !has_key(l:current.attr, 'src')
    return
  endif
  let l:fn = l:current.attr.src
  if l:fn =~# '^\s*$'
    return
  elseif l:fn !~# '^\(/\|http\)'
    let l:fn = simplify(expand('%:h') . '/' . l:fn)
  endif

  let [l:width, l:height] = emmet#util#getImageSize(l:fn)
  if l:width == -1 && l:height == -1
    return
  endif
  let l:current.attr.width = l:width
  let l:current.attr.height = l:height
  let l:current.attrs_order += ['width', 'height']
  let l:slim = emmet#toString(l:current, 'slim', 1)
  let l:slim = substitute(l:slim, '\${cursor}', '', '')
  call setline('.', substitute(matchstr(l:line, '^\s*') . l:slim, "\n", '', 'g'))
endfunction

function! emmet#lang#slim#imageEncode() abort
endfunction

function! emmet#lang#slim#parseTag(tag) abort
  let l:current = emmet#newNode()
  let l:mx = '\([a-zA-Z][a-zA-Z0-9]*\)\s\+\(.*\)'
  let l:match = matchstr(a:tag, l:mx)
  let l:current.name = substitute(l:match, l:mx, '\1', '')
  let l:attrs = substitute(l:match, l:mx, '\2', '')
  let l:mx = '\([a-zA-Z0-9]\+\)=\%(\([^"'' \t]\+\)\|"\([^"]\{-}\)"\|''\([^'']\{-}\)''\)'
  while len(l:attrs) > 0
    let l:match = matchstr(l:attrs, l:mx)
    if len(l:match) == 0
      break
    endif
    let l:attr_match = matchlist(l:match, l:mx)
    let l:name = l:attr_match[1]
    let l:value = len(l:attr_match[2]) ? l:attr_match[2] : l:attr_match[3]
    let l:current.attr[l:name] = l:value
    let l:current.attrs_order += [l:name]
    let l:attrs = l:attrs[stridx(l:attrs, l:match) + len(l:match):]
  endwhile
  return l:current
endfunction

function! emmet#lang#slim#toggleComment() abort
  let l:line = getline('.')
  let l:space = matchstr(l:line, '^\s*')
  if l:line =~# '^\s*/'
    call setline('.', l:space . l:line[len(l:space)+1:])
  elseif l:line =~# '^\s*[a-z]'
    call setline('.', l:space . '/' . l:line[len(l:space):])
  endif
endfunction

function! emmet#lang#slim#balanceTag(flag) range abort
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

function! emmet#lang#slim#moveNextPrevItem(flag) abort
  return emmet#lang#slim#moveNextPrev(a:flag)
endfunction

function! emmet#lang#slim#moveNextPrev(flag) abort
  let l:pos = search('""\|\(^\s*|\s*\zs\)', a:flag ? 'Wpb' : 'Wp')
  if l:pos == 2
    startinsert!
  elseif l:pos != 0
    silent! normal! l
    startinsert
  endif
endfunction

function! emmet#lang#slim#splitJoinTag() abort
  let l:n = line('.')
  while l:n > 0
    if getline(l:n) =~# '^\s*\ze[a-z]'
      let l:sn = l:n
      let l:n += 1
      if getline(l:n) =~# '^\s*|'
        while l:n <= line('$')
          if getline(l:n) !~# '^\s*|'
            break
          endif
          exe l:n 'delete'
        endwhile
        call setpos('.', [0, l:sn, 1, 0])
      else
        let l:spaces = matchstr(getline(l:sn), '^\s*')
        call append(l:sn, l:spaces . '  | ')
        call setpos('.', [0, l:sn+1, 1, 0])
        startinsert!
      endif
      break
    endif
    let l:n -= 1
  endwhile
endfunction

function! emmet#lang#slim#removeTag() abort
  let l:n = line('.')
  let l:ml = 0
  while l:n > 0
    if getline(l:n) =~# '^\s*\ze[a-z]'
      let l:ml = len(matchstr(getline(l:n), '^\s*[a-z]'))
      break
    endif
    let l:n -= 1
  endwhile
  let l:sn = l:n
  while l:n < line('$')
    let l:l = len(matchstr(getline(l:n), '^\s*[a-z]'))
    if l:l > 0 && l:l <= l:ml
      let l:n -= 1
      break
    endif
    let l:n += 1
  endwhile
  if l:sn == l:n
    exe 'delete'
  else
    exe l:sn ',' (l:n-1) 'delete'
  endif
endfunction

function! emmet#lang#slim#mergeLines() abort
endfunction

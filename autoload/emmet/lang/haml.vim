function! emmet#lang#haml#findTokens(str) abort
  return emmet#lang#html#findTokens(a:str)
endfunction

function! emmet#lang#haml#parseIntoTree(abbr, type) abort
  return emmet#lang#html#parseIntoTree(a:abbr, a:type)
endfunction

function! emmet#lang#haml#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:settings = a:settings
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = emmet#getIndentation(l:type)
  let l:dollar_expr = emmet#getResource(l:type, 'dollar_expr', 1)
  let l:attribute_style = emmet#getResource('haml', 'attribute_style', 'hash')
  let l:str = ''

  let l:current_name = l:current.name
  if l:dollar_expr
    let l:current_name = substitute(l:current.name, '\$$', l:itemno+1, '')
  endif
  if len(l:current.name) > 0
    let l:str .= '%' . l:current_name
    let l:tmp = ''
    for l:attr in emmet#util#unique(l:current.attrs_order + keys(l:current.attr))
      if !has_key(l:current.attr, l:attr)
        continue
      endif
      let l:Val = l:current.attr[l:attr]
      if type(l:Val) == 2 && l:Val == function('emmet#types#true')
        if l:attribute_style ==# 'hash'
          let l:tmp .= ' :' . l:attr . ' => true'
        elseif l:attribute_style ==# 'html'
          let l:tmp .= l:attr . '=true'
        end
      else
        if l:dollar_expr
          while l:Val =~# '\$\([^#{]\|$\)'
            let l:Val = substitute(l:Val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          endwhile
          let l:attr = substitute(l:attr, '\$$', l:itemno+1, '')
        endif
        let l:valtmp = substitute(l:Val, '\${cursor}', '', '')
        if l:attr ==# 'id' && len(l:valtmp) > 0
          let l:str .= '#' . l:Val
        elseif l:attr ==# 'class' && len(l:valtmp) > 0
          let l:str .= '.' . substitute(l:Val, ' ', '.', 'g')
        else
          if len(l:tmp) > 0
            if l:attribute_style ==# 'hash'
              let l:tmp .= ','
            elseif l:attribute_style ==# 'html'
              let l:tmp .= ' '
            endif
          endif
          if l:attribute_style ==# 'hash'
            let l:tmp .= ' :' . l:attr . ' => "' . l:Val . '"'
          elseif l:attribute_style ==# 'html'
            let l:tmp .= l:attr . '="' . l:Val . '"'
          end
        endif
      endif
    endfor
    if len(l:tmp)
      if l:attribute_style ==# 'hash'
        let l:str .= '{' . l:tmp . ' }'
      elseif l:attribute_style ==# 'html'
        let l:str .= '(' . l:tmp . ')'
      end
    endif
    if stridx(','.l:settings.html.empty_elements.',', ','.l:current_name.',') != -1 && len(l:current.value) == 0
      let l:str .= '/'
    endif

    let l:inner = ''
    if len(l:current.value) > 0
      let l:text = l:current.value[1:-2]
      if l:dollar_expr
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
        let l:text = substitute(l:text, '\${nr}', "\n", 'g')
        let l:text = substitute(l:text, '\\\$', '$', 'g')
        let l:str = substitute(l:str, '\$#', l:text, 'g')
      endif
      let l:lines = split(l:text, "\n")
      if len(l:lines) == 1
        let l:str .= ' ' . l:text
      else
        for l:line in l:lines
          let l:str .= "\n" . l:indent . l:line . ' |'
        endfor
      endif
    elseif len(l:current.child) == 0
      let l:str .= '${cursor}'
    endif
    if len(l:current.child) == 1 && len(l:current.child[0].name) == 0
      let l:text = l:current.child[0].value[1:-2]
      if l:dollar_expr
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
        let l:text = substitute(l:text, '\${nr}', "\n", 'g')
        let l:text = substitute(l:text, '\\\$', '$', 'g')
      endif
      let l:lines = split(l:text, "\n")
      if len(l:lines) == 1
        let l:str .= ' ' . l:text
      else
        for l:line in l:lines
          let l:str .= "\n" . l:indent . l:line . ' |'
        endfor
      endif
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
  let l:str .= "\n"
  return l:str
endfunction

function! emmet#lang#haml#imageSize() abort
  let l:line = getline('.')
  let l:current = emmet#lang#haml#parseTag(l:line)
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
  let l:haml = emmet#toString(l:current, 'haml', 1)
  let l:haml = substitute(l:haml, '\${cursor}', '', '')
  call setline('.', substitute(matchstr(l:line, '^\s*') . l:haml, "\n", '', 'g'))
endfunction

function! emmet#lang#haml#imageEncode() abort
endfunction

function! emmet#lang#haml#parseTag(tag) abort
  let l:current = emmet#newNode()
  let l:mx = '%\([a-zA-Z][a-zA-Z0-9]*\)\s*\%({\(.*\)}\)'
  let l:match = matchstr(a:tag, l:mx)
  let l:current.name = substitute(l:match, l:mx, '\1', '')
  let l:attrs = substitute(l:match, l:mx, '\2', '')
  let l:mx = '\([a-zA-Z0-9]\+\)\s*=>\s*\%(\([^"'' \t]\+\)\|"\([^"]\{-}\)"\|''\([^'']\{-}\)''\)'
  while len(l:attrs) > 0
    let l:match = matchstr(l:attrs, l:mx)
    if len(l:match) ==# 0
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

function! emmet#lang#haml#toggleComment() abort
  let l:line = getline('.')
  let l:space = matchstr(l:line, '^\s*')
  if l:line =~# '^\s*-#'
    call setline('.', l:space . matchstr(l:line[len(l:space)+2:], '^\s*\zs.*'))
  elseif l:line =~# '^\s*%[a-z]'
    call setline('.', l:space . '-# ' . l:line[len(l:space):])
  endif
endfunction

function! emmet#lang#haml#balanceTag(flag) range abort
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
        let l:l = len(matchstr(getline(l:n), '^\s*\ze%[a-z]'))
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
      let l:l = len(matchstr(getline(l:n), '^\s*%[a-z]'))
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
      let l:l = len(matchstr(getline(l:n), '^\s*%[a-z]'))
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

function! emmet#lang#haml#moveNextPrevItem(flag) abort
  return emmet#lang#haml#moveNextPrev(a:flag)
endfunction

function! emmet#lang#haml#moveNextPrev(flag) abort
  let l:pos = search('""', a:flag ? 'Wb' : 'W')
  if l:pos != 0
    silent! normal! l
    startinsert
  endif
endfunction

function! emmet#lang#haml#splitJoinTag() abort
  let l:n = line('.')
  let l:sml = len(matchstr(getline(l:n), '^\s*%[a-z]'))
  while l:n > 0
    if getline(l:n) =~# '^\s*\ze%[a-z]'
      if len(matchstr(getline(l:n), '^\s*%[a-z]')) < l:sml
        break
      endif
      let l:line = getline(l:n)
      call setline(l:n, substitute(l:line, '^\s*%\w\+\%(\s*{[^}]*}\|\s\)\zs.*', '', ''))
      let l:sn = l:n
      let l:n += 1
      let l:ml = len(matchstr(getline(l:n), '^\s*%[a-z]'))
      if len(matchstr(getline(l:n), '^\s*')) > l:ml
        while l:n <= line('$')
          let l:l = len(matchstr(getline(l:n), '^\s*'))
          if l:l <= l:ml
            break
          endif
          exe l:n 'delete'
        endwhile
        call setpos('.', [0, l:sn, 1, 0])
      else
        let l:tag = matchstr(getline(l:sn), '^\s*%\zs\(\w\+\)')
        let l:spaces = matchstr(getline(l:sn), '^\s*')
        let l:settings = emmet#getSettings()
        if stridx(','.l:settings.html.inline_elements.',', ','.l:tag.',') == -1
          call append(l:sn, l:spaces . '   ')
          call setpos('.', [0, l:sn+1, 1, 0])
        else
          call setpos('.', [0, l:sn, 1, 0])
        endif
        startinsert!
      endif
      break
    endif
    let l:n -= 1
  endwhile
endfunction

function! emmet#lang#haml#removeTag() abort
  let l:n = line('.')
  let l:ml = 0
  while l:n > 0
    if getline(l:n) =~# '^\s*\ze[a-z]'
      let l:ml = len(matchstr(getline(l:n), '^\s*%[a-z]'))
      break
    endif
    let l:n -= 1
  endwhile
  let l:sn = l:n
  while l:n < line('$')
    let l:l = len(matchstr(getline(l:n), '^\s*%[a-z]'))
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

function! emmet#lang#haml#mergeLines() abort
endfunction

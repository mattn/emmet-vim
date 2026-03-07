function! emmet#lang#css#findTokens(str) abort
  let l:tmp = substitute(substitute(a:str, '^.*[;{]\s*', '', ''), '}\s*$', '', '')
  if l:tmp =~ '/' && l:tmp =~ '^[a-zA-Z0-9/_.]\+$'
    " maybe path or something
    return ''
  endif
  return substitute(substitute(a:str, '^.*[;{]\s*', '', ''), '}\s*$', '', '')
endfunction

function! emmet#lang#css#parseIntoTree(abbr, type) abort
  let l:abbr = a:abbr
  let l:type = a:type
  let l:prefix = 0
  let l:value = ''

  let l:indent = emmet#getIndentation(l:type)
  let l:aliases = emmet#getResource(l:type, 'aliases', {})
  let l:snippets = emmet#getResource(l:type, 'snippets', {})
  let l:use_pipe_for_cursor = emmet#getResource(l:type, 'use_pipe_for_cursor', 1)

  let l:root = emmet#newNode()

  " emmet
  let l:tokens = split(l:abbr, '+\ze[^+)!]')
  let l:block = emmet#util#searchRegion('{', '}')
  if l:abbr !~# '^@' && emmet#getBaseType(l:type) ==# 'css' && l:type !=# 'sass' && l:type !=# 'styled' && l:block[0] ==# [0,0] && l:block[1] ==# [0,0]
    let l:current = emmet#newNode()
    let l:current.snippet = substitute(l:abbr, '\s\+$', '', '') . " {\n" . l:indent . "${cursor}\n}"
    let l:current.name = ''
    call add(l:root.child, deepcopy(l:current))
  else
    for l:n in range(len(l:tokens))
      let l:token = l:tokens[l:n]
      let l:prop = matchlist(l:token, '^\(-\{0,1}[a-zA-Z]\+\|[a-zA-Z0-9]\++\{0,1}\|([a-zA-Z0-9]\++\{0,1})\)\(\%([0-9.-]\+\%(p\|e\|em\|x\|vh\|vw\|re\|rem\|%\)\{0,}-\{0,1}\|-auto\)*\)$')
      if len(l:prop)
        let l:token = substitute(l:prop[1], '^(\(.*\))', '\1', '')
        if l:token =~# '^-'
          let l:prefix = 1
          let l:token = l:token[1:]
        endif
        let l:value = ''
        for l:vt in split(l:prop[2], '\a\+\zs')
          let l:ut = matchstr(l:vt, '[a-z]\+$')
          if l:ut == 'auto'
            let l:ut = ''
          endif
          for l:v in split(l:vt, '\d\zs-')
            if len(l:value) > 0
              let l:value .= ' '
            endif
            if l:v !~ '[a-z]\+$'
              let l:v .= l:ut
            endif
            if l:token =~# '^[z]'
              " TODO
              let l:value .= substitute(l:v, '[^0-9.]*$', '', '')
            elseif l:v =~# 'em$'
              let l:value .= l:v
            elseif l:v =~# 'ex$'
              let l:value .= l:v
            elseif l:v =~# 'vh$'
              let l:value .= l:v
            elseif l:v =~# 'vw$'
              let l:value .= l:v
            elseif l:v =~# 'rem$'
              let l:value .= l:v
            elseif l:v ==# 'auto'
              let l:value .= l:v
            elseif l:v =~# 'p$'
              let l:value .= substitute(l:v, 'p$', '%', '')
            elseif l:v =~# '%$'
              let l:value .= l:v
            elseif l:v =~# 'e$'
              let l:value .= substitute(l:v, 'e$', 'em', '')
            elseif l:v =~# 'x$'
              let l:value .= substitute(l:v, 'x$', 'ex', '')
            elseif l:v =~# 're$'
              let l:value .= substitute(l:v, 're$', 'rem', '')
            elseif l:v =~# '\.'
              let l:value .= l:v . 'em'
            elseif l:v ==# '0'
              let l:value .= '0'
            else
              let l:value .= l:v . 'px'
            endif
          endfor
        endfor
      endif

      let l:tag_name = l:token
      if l:tag_name =~# '.!$'
        let l:tag_name = l:tag_name[:-2]
        let l:important = 1
      else
        let l:important = 0
      endif
      " make default node
      let l:current = emmet#newNode()
      let l:current.important = l:important
      let l:current.name = l:tag_name

      " aliases
      if has_key(l:aliases, l:tag_name)
        let l:current.name = l:aliases[l:tag_name]
      endif

      " snippets
      if !empty(l:snippets)
        let l:snippet_name = l:tag_name
        if !has_key(l:snippets, l:snippet_name)
          let l:pat = '^' . join(split(l:tag_name, '\zs'), '\%(\|[^:-]\+-\)')
          let l:vv = filter(sort(keys(l:snippets)), 'l:snippets[v:val] =~ l:pat')
          if len(l:vv) == 0
            let l:vv = filter(sort(keys(l:snippets)), 'substitute(v:val, ":", "", "g") == l:snippet_name')
          endif
          if len(l:vv) > 0
            let l:snippet_name = l:vv[0]
          else
            let l:pat = '^' . join(split(l:tag_name, '\zs'), '\%(\|[^:-]\+-*\)')
            let l:vv = filter(sort(keys(l:snippets)), 'l:snippets[v:val] =~ l:pat')
            if len(l:vv) == 0
              let l:pat = '^' . join(split(l:tag_name, '\zs'), '[^:]\{-}')
              let l:vv = filter(sort(keys(l:snippets)), 'l:snippets[v:val] =~ l:pat')
              if len(l:vv) == 0
                let l:pat = '^' . join(split(l:tag_name, '\zs'), '.\{-}')
                let l:vv = filter(sort(keys(l:snippets)), 'l:snippets[v:val] =~ l:pat')
              endif
            endif
            let l:minl = -1
            for l:vk in l:vv
              let l:vvs = l:snippets[l:vk]
              if l:minl == -1 || len(l:vvs) < l:minl
                let l:snippet_name = l:vk
                let l:minl = len(l:vvs)
              endif
            endfor
          endif
        endif
        if has_key(l:snippets, l:snippet_name)
          let l:snippet = l:snippets[l:snippet_name]
          if l:use_pipe_for_cursor
            let l:snippet = substitute(l:snippet, '|', '${cursor}', 'g')
          endif
          let l:lines = split(l:snippet, "\n")
          call map(l:lines, 'substitute(v:val, "\\(    \\|\\t\\)", escape(l:indent, "\\\\"), "g")')
          let l:current.snippet = join(l:lines, "\n")
          let l:current.name = ''
          let l:current.snippet = substitute(l:current.snippet, ';', l:value . ';', '')
          if l:use_pipe_for_cursor && len(l:value) > 0
            let l:current.snippet = substitute(l:current.snippet, '\${cursor}', '', 'g')
          endif
          if l:n < len(l:tokens) - 1
            let l:current.snippet .= "\n"
          endif
        endif
      endif

      let l:current.pos = 0
      let l:lg = matchlist(l:token, '^\%(linear-gradient\|lg\)(\s*\(\S\+\)\s*,\s*\([^,]\+\)\s*,\s*\([^)]\+\)\s*)$')
      if len(l:lg) == 0
        let l:lg = matchlist(l:token, '^\%(linear-gradient\|lg\)(\s*\(\S\+\)\s*,\s*\([^,]\+\)\s*)$')
        if len(l:lg)
          let [l:lg[1], l:lg[2], l:lg[3]] = ['linear', l:lg[1], l:lg[2]]
        endif
      endif
      if len(l:lg)
        let l:current.name = ''
        let l:current.snippet = printf("background-image:-webkit-gradient(%s, 0 0, 0 100%%, from(%s), to(%s));\n", l:lg[1], l:lg[2], l:lg[3])
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = printf("background-image:-webkit-linear-gradient(%s, %s);\n", l:lg[2], l:lg[3])
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = printf("background-image:-moz-linear-gradient(%s, %s);\n", l:lg[2], l:lg[3])
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = printf("background-image:-o-linear-gradient(%s, %s);\n", l:lg[2], l:lg[3])
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = printf("background-image:linear-gradient(%s, %s);\n", l:lg[2], l:lg[3])
        call add(l:root.child, deepcopy(l:current))
      elseif l:prefix
        let l:snippet = l:current.snippet
        let l:current.snippet = '-webkit-' . l:snippet . "\n"
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = '-moz-' . l:snippet . "\n"
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = '-o-' . l:snippet . "\n"
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = '-ms-' . l:snippet . "\n"
        call add(l:root.child, deepcopy(l:current))
        let l:current.snippet = l:snippet
        call add(l:root.child, l:current)
      elseif l:token =~# '^c#\([0-9a-fA-F]\{3}\|[0-9a-fA-F]\{6}\)\(\.[0-9]\+\)\?'
        let l:cs = split(l:token, '\.')
        let l:current.name = ''
        let [l:r,l:g,l:b] = [0,0,0]
        if len(l:cs[0]) == 5
          let l:rgb = matchlist(l:cs[0], 'c#\(.\)\(.\)\(.\)')
          let l:r = eval('0x'.l:rgb[1].l:rgb[1])
          let l:g = eval('0x'.l:rgb[2].l:rgb[2])
          let l:b = eval('0x'.l:rgb[3].l:rgb[3])
        elseif len(l:cs[0]) == 8
          let l:rgb = matchlist(l:cs[0], 'c#\(..\)\(..\)\(..\)')
          let l:r = eval('0x'.l:rgb[1])
          let l:g = eval('0x'.l:rgb[2])
          let l:b = eval('0x'.l:rgb[3])
        endif
        if len(l:cs) == 1
          let l:current.snippet = printf('color:rgb(%d, %d, %d);', l:r, l:g, l:b)
        else
          let l:current.snippet = printf('color:rgb(%d, %d, %d, %s);', l:r, l:g, l:b, string(str2float('0.'.l:cs[1])))
        endif
        call add(l:root.child, l:current)
      elseif l:token =~# '^c#'
        let l:current.name = ''
        let l:current.snippet = 'color:\${cursor};'
        call add(l:root.child, l:current)
      else
        call add(l:root.child, l:current)
      endif
    endfor
  endif
  return l:root
endfunction

function! emmet#lang#css#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:current = a:current
  let l:value = l:current.value[1:-2]
  let l:tmp = substitute(l:value, '\${cursor}', '', 'g')
  if l:tmp !~ '.*{[ \t\r\n]*}$'
    if emmet#useFilter(a:filters, 'fc')
      let l:value = substitute(l:value, '\([^:]\+\):\([^;]*\)', '\1: \2', 'g')
    else
      let l:value = substitute(l:value, '\([^:]\+\):\([^;]*\)', '\1:\2', 'g')
    endif
    if l:current.important
      let l:value = substitute(l:value, ';', ' !important;', '')
    endif
  endif
  return l:value
endfunction

function! emmet#lang#css#imageSize() abort
  let l:img_region = emmet#util#searchRegion('{', '}')
  if !emmet#util#regionIsValid(l:img_region) || !emmet#util#cursorInRegion(l:img_region)
    return
  endif
  let l:content = emmet#util#getContent(l:img_region)
  let l:fn = matchstr(l:content, '\<url(\zs[^)]\+\ze)')
  let l:fn = substitute(l:fn, '[''" \t]', '', 'g')
  if l:fn =~# '^\s*$'
    return
  elseif l:fn !~# '^\(/\|http\)'
    let l:fn = simplify(expand('%:h') . '/' . l:fn)
  endif
  let [l:width, l:height] = emmet#util#getImageSize(l:fn)
  if l:width == -1 && l:height == -1
    return
  endif
  let l:indent = emmet#getIndentation('css')
  if l:content =~# '.*\<width\s*:[^;]*;.*'
    let l:content = substitute(l:content, '\<width\s*:[^;]*;', 'width: ' . l:width . 'px;', '')
  else
    let l:content = substitute(l:content, '}', l:indent . 'width: ' . l:width . "px;\n}", '')
  endif
  if l:content =~# '.*\<height\s*:[^;]*;.*'
    let l:content = substitute(l:content, '\<height\s*:[^;]*;', 'height: ' . l:height . 'px;', '')
  else
    let l:content = substitute(l:content, '}', l:indent . 'height: ' . l:height . "px;\n}", '')
  endif
  call emmet#util#setContent(l:img_region, l:content)
endfunction

function! emmet#lang#css#imageEncode() abort
  let l:img_region = emmet#util#searchRegion('url(', ')')
  if !emmet#util#regionIsValid(l:img_region) || !emmet#util#cursorInRegion(l:img_region)
    return
  endif
  let l:content = emmet#util#getContent(l:img_region)
  let l:fn = matchstr(l:content, '\<url(\zs[^)]\+\ze)')
  let l:fn = substitute(l:fn, '[''" \t]', '', 'g')
  if l:fn =~# '^\s*$'
    return
  elseif l:fn !~# '^\(/\|http\)'
    let l:fn = simplify(expand('%:h') . '/' . l:fn)
  endif
  let l:encoded = emmet#util#imageEncodeDecode(l:fn, 0)
  call emmet#util#setContent(l:img_region, 'url(' . l:encoded . ')')
endfunction

function! emmet#lang#css#parseTag(tag) abort
  return {}
endfunction

function! emmet#lang#css#toggleComment() abort
  let l:line = getline('.')
  let l:mx = '^\(\s*\)/\*\s*\(.*\)\s*\*/\s*$'
  if l:line =~# '{\s*$'
    let l:block = emmet#util#searchRegion('/\*', '\*/\zs')
    if emmet#util#regionIsValid(l:block)
      let l:content = emmet#util#getContent(l:block)
      let l:content = substitute(l:content, '/\*\s\(.*\)\s\*/', '\1', '')
      call emmet#util#setContent(l:block, l:content)
    else
      let l:node = expand('<cword>')
      if len(l:node)
        exe "normal ciw\<c-r>='/* '.l:node.' */'\<cr>"
      endif
    endif
  else
    if l:line =~# l:mx
      let l:space = substitute(matchstr(l:line, l:mx), l:mx, '\1', '')
      let l:line = substitute(matchstr(l:line, l:mx), l:mx, '\2', '')
      let l:line = l:space . substitute(l:line, '^\s*\|\s*$', '\1', 'g')
    else
      let l:mx = '^\(\s*\)\(''[^'']*''\|[^'']*\|;\)\s*$'
      " TODO multi-property
      "let l:mx = '^\(\s*\)\(\%(''[^'']*''\|[^'';]\+\)*;\{0,1}\)'
      let l:line = substitute(l:line, l:mx, '\1/* \2 */', '')
    endif
    call setline('.', l:line)
  endif
endfunction

function! emmet#lang#css#balanceTag(flag) range abort
  if a:flag == -2 || a:flag == 2
    let l:curpos = [0, line("'<"), col("'<"), 0]
  else
    let l:curpos = emmet#util#getcurpos()
  endif
  let l:block = emmet#util#getVisualBlock()
  if !emmet#util#regionIsValid(l:block)
    if a:flag > 0
      let l:block = emmet#util#searchRegion('^', ';')
      if emmet#util#regionIsValid(l:block)
        call emmet#util#selectRegion(l:block)
        return
      endif
    endif
  else
    if a:flag > 0
      let l:content = emmet#util#getContent(l:block)
      if l:content !~# '^{.*}$'
        let l:block = emmet#util#searchRegion('{', '}')
        if emmet#util#regionIsValid(l:block)
          call emmet#util#selectRegion(l:block)
          return
        endif
      endif
    else
      let l:pos = searchpos('.*;', 'nW')
      if l:pos[0] != 0
        call setpos('.', [0, l:pos[0], l:pos[1], 0])
        let l:block = emmet#util#searchRegion('^', ';')
        if emmet#util#regionIsValid(l:block)
          call emmet#util#selectRegion(l:block)
          return
        endif
      endif
    endif
  endif
  if a:flag == -2 || a:flag == 2
    silent! exe 'normal! gv'
  else
    call setpos('.', l:curpos)
  endif
endfunction

function! emmet#lang#css#moveNextPrevItem(flag) abort
  return emmet#lang#css#moveNextPrev(a:flag)
endfunction

function! emmet#lang#css#moveNextPrev(flag) abort
  call search('""\|()\|\(:\s*\zs;\{1,0}$\)', a:flag ? 'Wbp' : 'Wp')
  return ''
endfunction

function! emmet#lang#css#splitJoinTag() abort
  " nothing to do
endfunction

function! emmet#lang#css#removeTag() abort
  " nothing to do
endfunction

function! emmet#lang#css#mergeLines() abort
  " nothing to do
endfunction

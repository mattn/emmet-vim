let s:bx = '{\%("[^"]*"\|''[^'']*''\|\$#\|\${\w\+}\|\$\+\|{[^{]\+\|[^{}]\)\{-}}'
let s:mx = '\([+>]\|[<^]\+\)\{-}'
\     .'\((*\)\{-}'
\       .'\([@#.]\{-}[a-zA-Z_\!][a-zA-Z0-9:_\!\-$]*\|' . s:bx . '\|\[[^\]]\+\]\)'
\       .'\('
\         .'\%('
\           .'\%(#{[{}a-zA-Z0-9_\-\$]\+\|#[a-zA-Z0-9_\-\$]\+\)'
\           .'\|\%(\[\%(\[[^\]]*\]\|"[^"]*"\|[^"\[\]]*\)\+\]\)'
\           .'\|\%(\.{[{}a-zA-Z0-9_\-\$\.]\+\|\.[a-zA-Z0-9_\-\$]\+\)'
\         .'\)*'
\       .'\)'
\       .'\%(\(' . s:bx . '\+\)\)\{0,1}'
\         .'\%(\(@-\{0,1}[0-9]*\)\{0,1}\*\([0-9]\+\)\)\{0,1}'
\     .'\(\%()\%(\(@-\{0,1}[0-9]*\)\{0,1}\*[0-9]\+\)\{0,1}\)*\)'

function! emmet#lang#html#findTokens(str) abort
  let l:str = a:str
  let [l:pos, l:last_pos] = [0, 0]
  while 1
    let l:tag = matchstr(l:str, '<[a-zA-Z].\{-}>', l:pos)
    if len(l:tag) == 0
      break
    endif
    let l:pos = stridx(l:str, l:tag, l:pos) + len(l:tag)
  endwhile
  while 1
    let l:tag = matchstr(l:str, '{%[^%]\{-}%}', l:pos)
    if len(l:tag) == 0
      break
    endif
    let l:pos = stridx(l:str, l:tag, l:pos) + len(l:tag)
  endwhile
  let l:last_pos = l:pos
  while len(l:str) > 0
    let l:white = matchstr(l:str, '^\s\+', l:pos)
    if l:white != ''
      let l:last_pos = l:pos + len(l:white)
	  let l:pos = l:last_pos
    endif
    let l:token = matchstr(l:str, s:mx, l:pos)
    if l:token ==# ''
      break
    endif
    let l:pos = stridx(l:str, l:token, l:pos) + len(l:token)
  endwhile
  let l:str = a:str[l:last_pos :-1]
  if l:str =~# '^\w\+="[^"]*$'
    return ''
  endif
  return l:str
endfunction

function! emmet#lang#html#parseIntoTree(abbr, type) abort
  let l:abbr = a:abbr
  let l:type = a:type

  let l:settings = emmet#getSettings()
  if !has_key(l:settings, l:type)
    let l:type = 'html'
  endif
  if len(l:type) == 0 | let l:type = 'html' | endif

  let l:indent = emmet#getIndentation(l:type)
  let l:pmap = {
  \'p': 'span',
  \'ul': 'li',
  \'ol': 'li',
  \'table': 'tr',
  \'tr': 'td',
  \'tbody': 'tr',
  \'thead': 'tr',
  \'tfoot': 'tr',
  \'colgroup': 'col',
  \'select': 'option',
  \'optgroup': 'option',
  \'audio': 'source',
  \'video': 'source',
  \'object': 'param',
  \'map': 'area'
  \}

  let l:inlineLevel = split('a,abbr,acronym,applet,b,basefont,bdo,big,br,button,cite,code,del,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,object,q,s,samp,select,small,span,strike,strong,sub,sup,textarea,tt,u,var',',')

  let l:custom_expands = emmet#getResource(l:type, 'custom_expands', {})
  if empty(l:custom_expands) && has_key(l:settings, 'custom_expands')
    let l:custom_expands = l:settings['custom_expands']
  endif

  " try 'foo' to (foo-x)
  let l:rabbr = emmet#getExpandos(l:type, l:abbr)
  if l:rabbr == l:abbr
    " try 'foo+(' to (foo-x)
    let l:rabbr = substitute(l:abbr, '\%(+\|^\)\([a-zA-Z][a-zA-Z0-9+]\+\)+\([(){}>]\|$\)', '\="(".emmet#getExpandos(l:type, submatch(1)).")".submatch(2)', 'i')
  endif
  let l:abbr = l:rabbr

  let l:root = emmet#newNode()
  let l:root['variables'] = {}
  let l:parent = l:root
  let l:last = l:root
  let l:pos = []
  while len(l:abbr)
    " parse line
    let l:match = matchstr(l:abbr, s:mx)
    let l:str = substitute(l:match, s:mx, '\0', 'ig')
    let l:operator = substitute(l:match, s:mx, '\1', 'ig')
    let l:block_start = substitute(l:match, s:mx, '\2', 'ig')
    let l:tag_name = substitute(l:match, s:mx, '\3', 'ig')
    let l:attributes = substitute(l:match, s:mx, '\4', 'ig')
    let l:value = substitute(l:match, s:mx, '\5', 'ig')
    let l:basevalue = substitute(l:match, s:mx, '\6', 'ig')
    let l:multiplier = 0 + substitute(l:match, s:mx, '\7', 'ig')
    let l:block_end = substitute(l:match, s:mx, '\8', 'ig')
    let l:custom = ''
    let l:important = 0
    if len(l:str) == 0
      break
    endif
    if l:tag_name =~# '^#'
      let l:attributes = l:tag_name . l:attributes
      let l:tag_name = ''
    endif
    if l:tag_name =~# '[^!]!$'
      let l:tag_name = l:tag_name[:-2]
      let l:important = 1
    endif
    if l:tag_name =~# '^\.'
      let l:attributes = l:tag_name . l:attributes
      let l:tag_name = ''
    endif
    if l:tag_name =~# '^\[.*\]$'
      let l:attributes = l:tag_name . l:attributes
      let l:tag_name = ''
    endif

    for l:k in keys(l:custom_expands)
      if l:tag_name =~ l:k
        let l:custom = l:tag_name
        let l:tag_name = ''
        break
      endif
    endfor

    if empty(l:tag_name)
      let l:pname = len(l:parent.child) > 0 ? l:parent.child[0].name : ''
      if !empty(l:pname) && has_key(l:pmap, l:pname) && l:custom == ''
        let l:tag_name = l:pmap[l:pname]
      elseif !empty(l:pname) && index(l:inlineLevel, l:pname) > -1
        let l:tag_name = 'span'
      elseif len(l:custom) == 0
        let l:tag_name = 'div'
      elseif len(l:custom) != 0 && l:multiplier > 1
        let l:tag_name = 'div'
      else
        let l:tag_name = l:custom
      endif
    endif

    if l:basevalue != ''
      let l:basedirect = l:basevalue[1] ==# '-' ? -1 : 1
      let l:basevalue = 0 + abs(l:basevalue[1:])
    else
      let l:basedirect = 1
      let l:basevalue = 1
    endif
    if l:multiplier <= 0 | let l:multiplier = 1 | endif

    " make default node
    let l:current = emmet#newNode()

    let l:current.name = l:tag_name
    let l:current.important = l:important

    " aliases
    let l:aliases = emmet#getResource(l:type, 'aliases', {})
    if has_key(l:aliases, l:tag_name)
      let l:current.name = l:aliases[l:tag_name]
    endif

    let l:use_pipe_for_cursor = emmet#getResource(l:type, 'use_pipe_for_cursor', 1)

    " snippets
    let l:snippets = emmet#getResource(l:type, 'snippets', {})
    if !empty(l:snippets)
      let l:snippet_name = l:tag_name
      if has_key(l:snippets, l:snippet_name)
        let l:snippet = l:snippet_name
        while has_key(l:snippets, l:snippet)
          let l:snippet = l:snippets[l:snippet]
        endwhile
        if l:use_pipe_for_cursor
          let l:snippet = substitute(l:snippet, '|', '${cursor}', 'g')
        endif
        " just redirect to expanding
        if l:type == 'html' && l:snippet !~ '^\s*[{\[<]'
           return emmet#lang#html#parseIntoTree(l:snippet, a:type)
        endif
        let l:lines = split(l:snippet, "\n", 1)
        call map(l:lines, 'substitute(v:val, "\\(    \\|\\t\\)", escape(l:indent, "\\\\"), "g")')
        let l:current.snippet = join(l:lines, "\n")
        let l:current.name = ''
      endif
    endif

    for l:k in keys(l:custom_expands)
      if l:tag_name =~# l:k
        let l:snippet = '${' . (empty(l:custom) ? l:tag_name : l:custom) . '}'
        let l:current.name = ''
        let l:current.snippet = l:snippet
        break
      elseif l:custom =~# l:k
        let l:snippet = '${' . l:custom . '}'
        let l:current.snippet = '${' . l:custom . '}'
        if l:current.name != ''
          let l:snode = emmet#newNode()
          let l:snode.snippet = l:snippet
          let l:snode.parent = l:current
          call add(l:current.child, l:snode)
        else
          let l:current.snippet = l:snippet
        endif
        break
      endif
    endfor

    " default_attributes
    let l:default_attributes = emmet#getResource(l:type, 'default_attributes', {})
    if !empty(l:default_attributes)
      for l:pat in [l:current.name, l:tag_name]
        if has_key(l:default_attributes, l:pat)
          if type(l:default_attributes[l:pat]) == 4
            let l:a = l:default_attributes[l:pat]
            let l:current.attrs_order += keys(l:a)
            if l:use_pipe_for_cursor
              for l:k in keys(l:a)
                if type(l:a[l:k]) == 7
                  call remove(l:current.attr, l:k)
                  continue
                endif
                let l:current.attr[l:k] = len(l:a[l:k]) ? substitute(l:a[l:k], '|', '${cursor}', 'g') : '${cursor}'
              endfor
            else
              for l:k in keys(l:a)
                if type(l:a[l:k]) == 7
                  call remove(l:current.attr, l:k)
                  continue
                endif
                let l:current.attr[l:k] = l:a[l:k]
              endfor
            endif
          else
            for l:a in l:default_attributes[l:pat]
              let l:current.attrs_order += keys(l:a)
              if l:use_pipe_for_cursor
                for l:k in keys(l:a)
                  if type(l:a[l:k]) == 7
                    call remove(l:current.attr, l:k)
                    continue
                  endif
                  let l:current.attr[l:k] = len(l:a[l:k]) ? substitute(l:a[l:k], '|', '${cursor}', 'g') : '${cursor}'
                endfor
              else
                for l:k in keys(l:a)
                  if type(l:a[l:k]) == 7
                    call remove(l:current.attr, l:k)
                    continue
                  endif
                  let l:current.attr[l:k] = l:a[l:k]
                endfor
              endif
            endfor
          endif
          if has_key(l:settings.html.default_attributes, l:current.name)
            let l:current.name = substitute(l:current.name, ':.*$', '', '')
          endif
          break
        endif
      endfor
    endif

    " parse attributes
    if len(l:attributes)
      let l:attr = l:attributes
      while len(l:attr)
        let l:item = matchstr(l:attr, '\(\%(\%(#[{}a-zA-Z0-9_\-\$]\+\)\|\%(\[\%(\[[^\]]*\]\|"[^"]*"\|[^"\[\]]*\)\+\]\)\|\%(\.[{}a-zA-Z0-9_\-\$]\+\)*\)\)')
        if g:emmet_debug > 1
          echomsg 'attr=' . l:item
        endif
        if len(l:item) == 0
          break
        endif
        if l:item[0] ==# '#'
          let l:current.attr.id = l:item[1:]
          let l:root['variables']['id'] = l:current.attr.id
        endif
        if l:item[0] ==# '.'
          let l:current.attr.class = substitute(l:item[1:], '\.', ' ', 'g')
          let l:root['variables']['class'] = l:current.attr.class
        endif
        if l:item[0] ==# '['
          let l:atts = l:item[1:-2]
          if matchstr(l:atts, '^\s*\zs[0-9a-zA-Z_\-:]\+\(="[^"]*"\|=''[^'']*''\|=[^ ''"]\+\)') ==# ''
            let l:ks = []
			if has_key(l:default_attributes, l:current.name)
              let l:dfa = l:default_attributes[l:current.name]
              let l:ks = type(l:dfa) == 3 ? len(l:dfa) > 0 ? keys(l:dfa[0]) : [] : keys(l:dfa)
            endif
            if len(l:ks) == 0 && has_key(l:default_attributes, l:current.name . ':src')
              let l:dfa = l:default_attributes[l:current.name . ':src']
              let l:ks = type(l:dfa) == 3 ? len(l:dfa) > 0 ? keys(l:dfa[0]) : [] : keys(l:dfa)
            endif
            if len(l:ks) > 0
              let l:current.attr[l:ks[0]] = l:atts
            elseif l:atts =~# '\.$'
              let l:current.attr[l:atts[:-2]] = function('emmet#types#true')
            else
              let l:current.attr[l:atts] = ''
            endif
          else
            while len(l:atts)
              let l:amat = matchstr(l:atts, '^\s*\zs\([0-9a-zA-Z-:]\+\%(={{.\{-}}}\|="[^"]*"\|=''[^'']*''\|=[^ ''"]\+\|[^ ''"\]]*\)\{0,1}\)')
              if len(l:amat) == 0
                break
              endif
              let l:key = split(l:amat, '=')[0]
              let l:Val = l:amat[len(l:key)+1:]
              if l:key =~# '\.$' && l:Val ==# ''
                let l:key = l:key[:-2]
                unlet l:Val
                let l:Val = function('emmet#types#true')
              elseif l:Val =~# '^["'']'
                let l:Val = l:Val[1:-2]
              endif
              let l:current.attr[l:key] = l:Val
              if index(l:current.attrs_order, l:key) == -1
                let l:current.attrs_order += [l:key]
              endif
              let l:atts = l:atts[stridx(l:atts, l:amat) + len(l:amat):]
              unlet l:Val
            endwhile
          endif
        endif
        let l:attr = substitute(strpart(l:attr, len(l:item)), '^\s*', '', '')
      endwhile
    endif

    " parse text
    if l:tag_name =~# '^{.*}$'
      let l:current.name = ''
      let l:current.value = l:tag_name
    else
      let l:current.value = l:value
    endif
    let l:current.basedirect = l:basedirect
    let l:current.basevalue = l:basevalue
    let l:current.multiplier = l:multiplier

    " parse step inside/outside
    if !empty(l:last)
      if l:operator =~# '>'
        unlet! l:parent
        let l:parent = l:last
        let l:current.parent = l:last
        let l:current.pos = l:last.pos + 1
      else
        let l:current.parent = l:parent
        let l:current.pos = l:last.pos
      endif
    else
      let l:current.parent = l:parent
      let l:current.pos = 1
    endif
    if l:operator =~# '[<^]'
      for l:c in range(len(l:operator))
        let l:tmp = l:parent.parent
        if empty(l:tmp)
          break
        endif
        let l:parent = l:tmp
        let l:current.parent = l:tmp
      endfor
    endif

    call add(l:parent.child, l:current)
    let l:last = l:current

    " parse block
    if l:block_start =~# '('
      if l:operator =~# '>'
        let l:last.pos += 1
      endif
      let l:last.block = 1
      for l:n in range(len(l:block_start))
        let l:pos += [l:last.pos]
      endfor
    endif
    if l:block_end =~# ')'
      for l:n in split(substitute(substitute(l:block_end, ' ', '', 'g'), ')', ',),', 'g'), ',')
        if l:n ==# ')'
          if len(l:pos) > 0 && l:last.pos >= l:pos[-1]
            for l:c in range(l:last.pos - l:pos[-1])
              let l:tmp = l:parent.parent
              if !has_key(l:tmp, 'parent')
                break
              endif
              let l:parent = l:tmp
            endfor
            if len(l:pos) > 0
              call remove(l:pos, -1)
            endif
            let l:last = l:parent
            let l:last.pos += 1
          endif
        elseif len(l:n)
          let l:st = 0
          for l:nc in range(len(l:last.child))
            if l:last.child[l:nc].block
              let l:st = l:nc
              break
            endif
          endfor
          let l:cl = l:last.child[l:st :]
          let l:cls = []
          for l:c in range(l:n[1:])
            for l:cc in l:cl
              if l:cc.multiplier > 1
                let l:cc.basedirect = l:c + 1
              else
                let l:cc.basevalue = l:c + 1
              endif
            endfor
            let l:cls += deepcopy(l:cl)
          endfor
          if l:st > 0
            let l:last.child = l:last.child[:l:st-1] + l:cls
          else
            let l:last.child = l:cls
          endif
        endif
      endfor
    endif
    let l:abbr = l:abbr[stridx(l:abbr, l:match) + len(l:match):]
    if l:abbr == '/'
      let l:current.empty = 1
    endif

    if g:emmet_debug > 1
      echomsg 'str='.l:str
      echomsg 'block_start='.l:block_start
      echomsg 'tag_name='.l:tag_name
      echomsg 'operator='.l:operator
      echomsg 'attributes='.l:attributes
      echomsg 'value='.l:value
      echomsg 'basevalue='.l:basevalue
      echomsg 'multiplier='.l:multiplier
      echomsg 'block_end='.l:block_end
      echomsg 'abbr='.l:abbr
      echomsg 'pos='.string(l:pos)
      echomsg '---'
    endif
  endwhile
  return l:root
endfunction

function! s:dollar_add(base,no) abort
  if a:base > 0
    return a:base + a:no - 1
  elseif a:base < 0
    return a:base - a:no + 1
  else
    return a:no
  endif
endfunction

function! emmet#lang#html#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:settings = a:settings
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = a:indent
  let l:dollar_expr = emmet#getResource(l:type, 'dollar_expr', 1)
  let l:q = emmet#getResource(l:type, 'quote_char', '"')
  let l:ct = emmet#getResource(l:type, 'comment_type', 'both')
  let l:an = emmet#getResource(l:type, 'attribute_name', {})
  let l:empty_elements = emmet#getResource(l:type, 'empty_elements', l:settings.html.empty_elements)
  let l:empty_element_suffix = emmet#getResource(l:type, 'empty_element_suffix', l:settings.html.empty_element_suffix)

  if emmet#useFilter(l:filters, 'haml')
    return emmet#lang#haml#toString(l:settings, l:current, l:type, l:inline, l:filters, l:itemno, l:indent)
  endif
  if emmet#useFilter(l:filters, 'slim')
    return emmet#lang#slim#toString(l:settings, l:current, l:type, l:inline, l:filters, l:itemno, l:indent)
  endif

  let l:comment = ''
  let l:current_name = l:current.name
  if l:dollar_expr
    let l:current_name = substitute(l:current_name, '\$$', l:itemno+1, '')
  endif

  let l:str = ''
  if len(l:current_name) == 0
    let l:text = l:current.value[1:-2]
    if l:dollar_expr
      " TODO: regexp engine specified
      let l:nr = l:itemno + 1
      if exists('&regexpengine')
        let l:text = substitute(l:text, '\%#=1\%(\\\)\@\<!\(\$\+\)\(@-\?[0-9]\+\)\{0,1}\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d",s:dollar_add(submatch(2)[1:],l:nr)).submatch(3)', 'g')
      else
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\(@-\?[0-9]\+\)\{0,1}\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d",s:dollar_add(submatch(2)[1:],l:nr).submatch(3)', 'g')
      endif
      let l:text = substitute(l:text, '\${nr}', "\n", 'g')
      let l:text = substitute(l:text, '\\\$', '$', 'g')
    endif
    return l:text
  endif
  if len(l:current_name) > 0
    let l:str .= '<' . l:current_name
  endif
  for l:attr in emmet#util#unique(l:current.attrs_order + keys(l:current.attr))
    if !has_key(l:current.attr, l:attr)
      continue
    endif
    let l:Val = l:current.attr[l:attr]
    if type(l:Val) == 2 && l:Val == function('emmet#types#true')
      unlet l:Val
      let l:Val = 'true'
      if g:emmet_html5
        let l:str .= ' ' . l:attr
      else
        let l:str .= ' ' . l:attr . '=' . l:q . l:attr . l:q
      endif
      if emmet#useFilter(l:filters, 'c')
        if l:attr ==# 'id' | let l:comment .= '#' . l:Val | endif
        if l:attr ==# 'class' | let l:comment .= '.' . l:Val | endif
      endif
    else
      if l:dollar_expr
        while l:Val =~# '\$\([^#{]\|$\)'
          " TODO: regexp engine specified
          if exists('&regexpengine')
            let l:Val = substitute(l:Val, '\%#=1\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          else
            let l:Val = substitute(l:Val, '\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          endif
        endwhile
        let l:attr = substitute(l:attr, '\$$', l:itemno+1, '')
      endif
      if l:attr ==# 'class' && emmet#useFilter(l:filters, 'bem')
        let l:vals = split(l:Val, '\s\+')
        let l:Val = ''
        let l:lead = ''
        for l:_val in l:vals
          if len(l:Val) > 0
            let l:Val .= ' '
          endif
          if l:_val =~# '^_'
            if has_key(l:current.parent.attr, 'class')
              let l:lead = l:current.parent.attr["class"]
              if l:_val =~# '^__'
                let l:Val .= l:lead . l:_val
              else
                let l:Val .= l:lead . ' ' . l:lead . l:_val
              endif
            else
              let l:lead = split(l:vals[0], '_')[0]
              let l:Val .= l:lead . l:_val
            endif
          elseif l:_val =~# '^-'
            for l:l in split(l:_val, '_')
              if len(l:Val) > 0
                let l:Val .= ' '
              endif
              let l:l = substitute(l:l, '^-', '__', '')
              if len(l:lead) == 0
                let l:pattr = l:current.parent.attr
                if has_key(l:pattr, 'class')
                  let l:lead = split(l:pattr['class'], '\s\+')[0]
                endif
              endif
              let l:Val .= l:lead . l:l
              let l:lead .= l:l . '_'
            endfor
          else
            let l:Val .= l:_val
          endif
        endfor
      endif
      if has_key(l:an, l:attr)
        let l:attr = l:an[l:attr]
      endif
      if emmet#isExtends(l:type, 'jsx') && l:Val =~ '^{.*}$'
        let l:str .= ' ' . l:attr . '=' . l:Val
      else
        let l:str .= ' ' . l:attr . '=' . l:q . l:Val . l:q
      endif
      if emmet#useFilter(l:filters, 'c')
        if l:attr ==# 'id' | let l:comment .= '#' . l:Val | endif
        if l:attr ==# 'class' | let l:comment .= '.' . l:Val | endif
      endif
    endif
    unlet l:Val
  endfor
  if len(l:comment) > 0 && l:ct ==# 'both'
    let l:str = '<!-- ' . l:comment . " -->\n" . l:str
  endif
  if l:current.empty
    let l:str .= ' />'
  elseif stridx(','.l:empty_elements.',', ','.l:current_name.',') != -1
    let l:str .= l:empty_element_suffix
  else
    let l:str .= '>'
    let l:text = l:current.value[1:-2]
    if l:dollar_expr
      " TODO: regexp engine specified
      let l:nr = l:itemno + 1
      if exists('&regexpengine')
        let l:text = substitute(l:text, '\%#=1\%(\\\)\@\<!\(\$\+\)\(@-\?[0-9]\+\)\{0,1}\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d",s:dollar_add(submatch(2)[1:],l:nr)).submatch(3)', 'g')
      else
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\(@-\?[0-9]\+\)\{0,1}\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d",s:dollar_add(submatch(2)[1:],l:nr)).submatch(3)', 'g')
      endif
      let l:text = substitute(l:text, '\${nr}', "\n", 'g')
      let l:text = substitute(l:text, '\\\$', '$', 'g')
      if l:text != ''
        let l:str = substitute(l:str, '\("\zs$#\ze"\|\s\zs\$#"\|"\$#\ze\s\)', l:text, 'g')
      endif
    endif
    let l:str .= l:text
    let l:nc = len(l:current.child)
    let l:dr = 0
    if l:nc > 0
      for l:n in range(l:nc)
        let l:child = l:current.child[l:n]
        if l:child.multiplier > 1 || (l:child.multiplier == 1 && len(l:child.child) > 0 && stridx(','.l:settings.html.inline_elements.',', ','.l:current_name.',') == -1) || l:settings.html.block_all_childless
          let l:str .= "\n" . l:indent
          let l:dr = 1
        elseif len(l:current_name) > 0 && stridx(','.l:settings.html.inline_elements.',', ','.l:current_name.',') == -1
          if l:nc > 1 || (len(l:child.name) > 0 && stridx(','.l:settings.html.inline_elements.',', ','.l:child.name.',') == -1)
            let l:str .= "\n" . l:indent
            let l:dr = 1
          elseif l:current.multiplier == 1 && l:nc == 1 && len(l:child.name) == 0
            let l:str .= "\n" . l:indent
            let l:dr = 1
          endif
        endif
        let l:inner = emmet#toString(l:child, l:type, 0, l:filters, l:itemno, l:indent)
        let l:inner = substitute(l:inner, "^\n", '', 'g')
        let l:inner = substitute(l:inner, "\n", "\n" . escape(l:indent, '\'), 'g')
        let l:inner = substitute(l:inner, "\n" . escape(l:indent, '\') . '$', '', 'g')
        let l:str .= l:inner
      endfor
    else
      if l:settings.html.indent_blockelement && len(l:current_name) > 0 && stridx(','.l:settings.html.inline_elements.',', ','.l:current_name.',') == -1 || l:settings.html.block_all_childless
        let l:str .= "\n" . l:indent . '${cursor}' . "\n"
      else
        let l:str .= '${cursor}'
      endif
    endif
    if l:dr
      let l:str .= "\n"
    endif
    let l:str .= '</' . l:current_name . '>'
  endif
  if len(l:comment) > 0
    if l:ct ==# 'lastonly'
      let l:str .= '<!-- ' . l:comment . ' -->'
    else
      let l:str .= "\n<!-- /" . l:comment . ' -->'
    endif
  endif
  if len(l:current_name) > 0 && l:current.multiplier > 0 || stridx(','.l:settings.html.block_elements.',', ','.l:current_name.',') != -1
    let l:str .= "\n"
  endif
  return l:str
endfunction

function! emmet#lang#html#imageSize() abort
  let l:img_region = emmet#util#searchRegion('<img\s', '>')
  if !emmet#util#regionIsValid(l:img_region) || !emmet#util#cursorInRegion(l:img_region)
    return
  endif
  let l:content = emmet#util#getContent(l:img_region)
  if l:content !~# '^<img[^><]\+>$'
    return
  endif
  let l:current = emmet#lang#html#parseTag(l:content)
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
  let l:html = substitute(emmet#toString(l:current, 'html', 1), '\n', '', '')
  let l:html = substitute(l:html, '\${cursor}', '', '')
  call emmet#util#setContent(l:img_region, l:html)
endfunction

function! emmet#lang#html#imageEncode() abort
  let l:img_region = emmet#util#searchRegion('<img\s', '>')
  if !emmet#util#regionIsValid(l:img_region) || !emmet#util#cursorInRegion(l:img_region)
    return
  endif
  let l:content = emmet#util#getContent(l:img_region)
  if l:content !~# '^<img[^><]\+>$'
    return
  endif
  let l:current = emmet#lang#html#parseTag(l:content)
  if empty(l:current) || !has_key(l:current.attr, 'src')
    return
  endif
  let l:fn = l:current.attr.src
  if l:fn =~# '^\s*$'
    return
  elseif l:fn !~# '^\(/\|http\)'
    let l:fn = simplify(expand('%:h') . '/' . l:fn)
  endif

  let l:encoded = emmet#util#imageEncodeDecode(l:fn, 0)
  let l:current.attr.src = l:encoded
  let l:content = substitute(emmet#toString(l:current, 'html', 1), '\n', '', '')
  let l:content = substitute(l:content, '\${cursor}', '', '')
  call emmet#util#setContent(l:img_region, l:content)
endfunction

function! emmet#lang#html#parseTag(tag) abort
  let l:current = emmet#newNode()
  let l:mx = '<\([a-zA-Z][a-zA-Z0-9-]*\)\(\%(\s[a-zA-Z][a-zA-Z0-9-]\+=\?\%([^"'' \t]\+\|"[^"]\{-}"\|''[^'']\{-}''\)\s*\)*\)\(/\{0,1}\)>'
  let l:match = matchstr(a:tag, l:mx)
  let l:current.name = substitute(l:match, l:mx, '\1', 'i')
  let l:attrs = substitute(l:match, l:mx, '\2', 'i')
  let l:mx = '\([a-zA-Z0-9-]\+\)\(\(=[^"'' \t]\+\)\|="\([^"]\{-}\)"\|=''\([^'']\{-}\)''\)\?'
  while len(l:attrs) > 0
    let l:match = matchstr(l:attrs, l:mx)
    if len(l:match) == 0
      break
    endif
    let l:attr_match = matchlist(l:match, l:mx)
    let l:name = l:attr_match[1]
    if len(l:attr_match[2])
      let l:Val = len(l:attr_match[3]) ? l:attr_match[3] : l:attr_match[4]
    else
      let l:Val = function('emmet#types#true')
    endif
    let l:current.attr[l:name] = l:Val
    let l:current.attrs_order += [l:name]
    let l:attrs = l:attrs[stridx(l:attrs, l:match) + len(l:match):]
  endwhile
  return l:current
endfunction

function! emmet#lang#html#toggleComment() abort
  let l:orgpos = getpos('.')
  let l:curpos = getpos('.')
  let l:mx = '<\%#[^>]*>'
  while 1
    let l:block = emmet#util#searchRegion('<!--', '-->')
    if emmet#util#regionIsValid(l:block)
      let l:block[1][1] += 2
      let l:content = emmet#util#getContent(l:block)
      let l:content = substitute(l:content, '^<!--\s\(.*\)\s-->$', '\1', '')
      call emmet#util#setContent(l:block, l:content)
      silent! call setpos('.', l:orgpos)
      return
    endif
    let l:block = emmet#util#searchRegion('<[^>]', '>')
    if !emmet#util#regionIsValid(l:block)
      let l:pos1 = searchpos('<', 'bcW')
      if l:pos1[0] == 0 && l:pos1[1] == 0
        return
      endif
      let l:curpos = getpos('.')
      continue
    endif
    let l:pos1 = l:block[0]
    let l:pos2 = l:block[1]
    let l:content = emmet#util#getContent(l:block)
    let l:tag_name = matchstr(l:content, '^<\zs/\{0,1}[^ \r\n>]\+')
    if l:tag_name[0] ==# '/'
      call setpos('.', [0, l:pos1[0], l:pos1[1], 0])
      let l:pos2 = searchpairpos('<'. l:tag_name[1:] . '\>[^/>]*>', '', '</' . l:tag_name[1:] . '>', 'bnW')
      let l:pos1 = searchpos('>', 'cneW')
      let l:block = [l:pos2, l:pos1]
    elseif l:tag_name =~# '/$'
      if !emmet#util#pointInRegion(l:orgpos[1:2], l:block)
        " it's broken tree
        call setpos('.', l:orgpos)
        let l:block = emmet#util#searchRegion('>', '<')
        let l:content = '><!-- ' . emmet#util#getContent(l:block)[1:-2] . ' --><'
        call emmet#util#setContent(l:block, l:content)
        silent! call setpos('.', l:orgpos)
        return
      endif
    else
      call setpos('.', [0, l:pos2[0], l:pos2[1], 0])
      let l:pos3 = searchpairpos('<'. l:tag_name . '\>[^/>]*>', '', '</' . l:tag_name . '>', 'nW')
      if l:pos3 == [0, 0]
        let l:block = [l:pos1, l:pos2]
      else
        call setpos('.', [0, l:pos3[0], l:pos3[1], 0])
        let l:pos2 = searchpos('>', 'neW')
        let l:block = [l:pos1, l:pos2]
      endif
    endif
    if !emmet#util#regionIsValid(l:block)
      silent! call setpos('.', l:orgpos)
      return
    endif
    if emmet#util#pointInRegion(l:curpos[1:2], l:block)
      let l:content = '<!-- ' . emmet#util#getContent(l:block) . ' -->'
      call emmet#util#setContent(l:block, l:content)
      silent! call setpos('.', l:orgpos)
      return
    endif
  endwhile
endfunction

function! emmet#lang#html#balanceTag(flag) range abort
  let l:vblock = emmet#util#getVisualBlock()
  let l:curpos = emmet#util#getcurpos()
  let l:settings = emmet#getSettings()

  if a:flag > 0
    let l:mx = '<\([a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*'
    let l:last = l:curpos[1:2]
    while 1
      let l:pos1 = searchpos(l:mx, 'bW')
      let l:content = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
      let l:tag_name = matchstr(l:content, '^<\zs[a-zA-Z0-9:_\-]*\ze')
      if stridx(','.l:settings.html.empty_elements.',', ','.l:tag_name.',') != -1
        let l:pos2 = searchpos('>', 'nW')
      else
        let l:pos2 = searchpairpos('<' . l:tag_name . '[^>]*>', '', '</'. l:tag_name . '\zs>', 'nW')
      endif
      let l:block = [l:pos1, l:pos2]
      if l:pos1 == [0, 0]
        break
      endif
      if emmet#util#pointInRegion(l:last, l:block) && emmet#util#regionIsValid(l:block)
        call emmet#util#selectRegion(l:block)
        return
      endif
      if l:pos1 == l:last
        break
      endif
      let l:last = l:pos1
    endwhile
  else
    let l:mx = '<\([a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*>'
    while 1
      let l:pos1 = searchpos(l:mx, 'W')
      if l:pos1 == [0, 0] || l:pos1 == l:curpos[1:2]
        let l:pos1 = searchpos('>\zs', 'W')
        let l:pos2 = searchpos('.\ze<', 'W')
        let l:block = [l:pos1, l:pos2]
        if emmet#util#regionIsValid(l:block)
          call emmet#util#selectRegion(l:block)
          return
        endif
      endif
      let l:content = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
      let l:tag_name = matchstr(l:content, '^<\zs[a-zA-Z0-9:_\-]*\ze')
      if stridx(','.l:settings.html.empty_elements.',', ','.l:tag_name.',') != -1
        let l:pos2 = searchpos('>', 'nW')
      else
        let l:pos2 = searchpairpos('<' . l:tag_name . '[^>]*>', '', '</'. l:tag_name . '\zs>', 'nW')
      endif
      let l:block = [l:pos1, l:pos2]
      if l:pos1 == [0, 0]
        break
      endif
      if emmet#util#regionIsValid(l:block)
        call emmet#util#selectRegion(l:block)
        return
      endif
    endwhile
  endif
  call setpos('.', l:curpos)
endfunction

function! emmet#lang#html#moveNextPrevItem(flag) abort
  silent! exe "normal \<esc>"
  let l:mx = '\%([0-9a-zA-Z-:]\+\%(="[^"]*"\|=''[^'']*''\|[^ ''">\]]*\)\{0,1}\)'
  let l:pos = searchpos('\s'.l:mx.'\zs', '')
  if l:pos != [0,0]
    call feedkeys('v?\s\zs'.l:mx."\<cr>", '')
  endif
  return ''
endfunction

function! emmet#lang#html#moveNextPrev(flag) abort
  let l:pos = search('\%(</\w\+\)\@<!\zs><\/\|\(""\)\|^\(\s*\)$', a:flag ? 'Wpb' : 'Wp')
  if l:pos == 3
    startinsert!
  elseif l:pos != 0
    silent! normal! l
    startinsert
  endif
  return ''
endfunction

function! emmet#lang#html#splitJoinTag() abort
  let l:curpos = emmet#util#getcurpos()
  let l:mx = '<\(/\{0,1}[a-zA-Z][-a-zA-Z0-9:_\-]*\)\%(\%(\s[a-zA-Z][a-zA-Z0-9]\+=\%([^"'' \t]\+\|"[^"]\{-}"\|''[^'']\{-}''\)\s*\)*\)\s*\%(/\{0,1}\)>'
  while 1
    let l:old = getpos('.')[1:2]
    let l:pos1 = searchpos(l:mx, 'bcnW')
    let l:content = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
    let l:tag_name = substitute(l:content, '^<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\).*$', '\1', '')
    let l:block = [l:pos1, [l:pos1[0], l:pos1[1] + len(l:content) - 1]]
    if l:content[-2:] ==# '/>' && emmet#util#cursorInRegion(l:block)
      let l:content = substitute(l:content[:-3], '\s*$', '', '')  . '></' . l:tag_name . '>'
      call emmet#util#setContent(l:block, l:content)
      call setpos('.', [0, l:block[0][0], l:block[0][1], 0])
      return
    endif
    if l:tag_name[0] ==# '/'
      let l:pos1 = searchpos('<' . l:tag_name[1:] . '[^a-zA-Z0-9]', 'bcnW')
      call setpos('.', [0, l:pos1[0], l:pos1[1], 0])
      let l:pos2 = searchpairpos('<'. l:tag_name[1:] . '\>[^/>]*>', '', '</' . l:tag_name[1:] . '>', 'W')
    else
      let l:pos2 = searchpairpos('<'. l:tag_name . '[^/>]*>', '', '</' . l:tag_name . '>', 'W')
    endif
    if l:pos2 == [0, 0]
      return
    endif
    let l:pos2 = searchpos('>', 'neW')
    let l:block = [l:pos1, l:pos2]
    if emmet#util#pointInRegion(l:curpos[1:2], l:block)
      let l:content = matchstr(l:content, l:mx)[:-2] . ' />'
      call emmet#util#setContent(l:block, l:content)
      call setpos('.', [0, l:block[0][0], l:block[0][1], 0])
      return
    endif
    if l:block[0][0] > 0
      call setpos('.', [0, l:block[0][0]-1, l:block[0][1], 0])
    else
      call setpos('.', l:curpos)
      return
    endif
    if l:pos1 == l:old
      call setpos('.', l:curpos)
      return
    endif
  endwhile
endfunction

function! emmet#lang#html#removeTag() abort
  let l:curpos = emmet#util#getcurpos()
  let l:mx = '<\(/\{0,1}[a-zA-Z][-a-zA-Z0-9:_\-]*\)\%(\%(\s[a-zA-Z][a-zA-Z0-9]\+=\%([^"'' \t]\+\|"[^"]\{-}"\|''[^'']\{-}''\)\s*\)*\)\s*\%(/\{0,1}\)>'

  let l:pos1 = searchpos(l:mx, 'bcnW')
  let l:content = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
  let l:tag_name = substitute(l:content, '^<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\).*$', '\1', '')
  let l:block = [l:pos1, [l:pos1[0], l:pos1[1] + len(l:content) - 1]]
  if l:content[-2:] ==# '/>' && emmet#util#cursorInRegion(l:block)
    call emmet#util#setContent(l:block, '')
    call setpos('.', [0, l:block[0][0], l:block[0][1], 0])
    return
  endif
  if l:tag_name[0] ==# '/'
    let l:pos1 = searchpos('<' . l:tag_name[1:] . '[^a-zA-Z0-9]', 'bcnW')
    call setpos('.', [0, l:pos1[0], l:pos1[1], 0])
    let l:pos2 = searchpairpos('<'. l:tag_name[1:] . '\>[^/>]*>', '', '</' . l:tag_name[1:] . '>', 'W')
  else
    let l:pos2 = searchpairpos('<'. l:tag_name . '[^/>]*>', '', '</' . l:tag_name . '>', 'W')
  endif
  if l:pos2 == [0, 0]
    return
  endif
  let l:pos2 = searchpos('>', 'neW')
  let l:block = [l:pos1, l:pos2]
  if emmet#util#pointInRegion(l:curpos[1:2], l:block)
    call emmet#util#setContent(l:block, '')
    call setpos('.', [0, l:block[0][0], l:block[0][1], 0])
    return
  endif
  if l:block[0][0] > 0
    call setpos('.', [0, l:block[0][0]-1, l:block[0][1], 0])
  else
    call setpos('.', l:curpos)
  endif
endfunction

function! emmet#lang#html#mergeLines() abort
  let l:curpos = emmet#util#getcurpos()
  let l:settings = emmet#getSettings()

  let l:mx = '<\([a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*>'
  let l:last = l:curpos[1:2]
  while 1
    let l:pos1 = searchpos(l:mx, 'bcW')
    let l:content = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
	echomsg string(l:content)
    let l:tag_name = matchstr(l:content, '^<\zs[a-zA-Z0-9:_\-]*\ze')
    if stridx(','.l:settings.html.empty_elements.',', ','.l:tag_name.',') != -1
      let l:pos2 = searchpos('>', 'nW')
    else
      let l:pos2 = searchpairpos('<' . l:tag_name . '[^>]*>', '', '</'. l:tag_name . '\zs>', 'nW')
    endif
    if l:pos1 == [0, 0] || l:pos2 == [0, 0]
      call setpos('.', l:curpos)
      return
    endif
    let l:block = [l:pos1, l:pos2]
    if emmet#util#pointInRegion(l:last, l:block) && emmet#util#regionIsValid(l:block)
      break
    endif
    if l:pos1 == l:last
      call setpos('.', l:curpos)
      return
    endif
    let l:last = l:pos1
  endwhile

  let l:content = emmet#util#getContent(l:block)
  let l:mx = '<\(/\{0,1}[a-zA-Z][-a-zA-Z0-9:_\-]*\)\%(\%(\s[a-zA-Z][a-zA-Z0-9]\+=\%([^"'' \t]\+\|"[^"]\{-}"\|''[^'']\{-}''\)\s*\)*\)\s*\%(/\{0,1}\)>'
  let l:content = join(map(split(l:content, l:mx . '\zs\s*'), 'trim(v:val)'), '')
  call emmet#util#setContent(l:block, l:content)
  if l:block[0][0] > 0
    call setpos('.', [0, l:block[0][0], l:block[0][1], 0])
  else
    call setpos('.', l:curpos)
  endif
endfunction

"let s:mx = '\([+>]\|<\+\)\{-}\((*\)\{-}\([@#.]\{-}[a-zA-Z\!][a-zA-Z0-9:_\!\-$]*\|'
let s:mx = '\([+>]\|<\+\)\{-}\s*\((*\)\{-}\s*\([@#.]\{-}[a-zA-Z\!][a-zA-Z0-9:_\!\-$]*\|'
\       .'{.\{-}}[ \t\r\n}]*\)\(\%(\%(#{[{}a-zA-Z0-9_\-\$]\+\|'
\       .'#[a-zA-Z0-9_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|'
\       .'\%(\.{[{}a-zA-Z0-9_\-\$]\+\|'
\       .'\.[a-zA-Z0-9_\-\$]\+\)\)*\)\%(\({[^}]\+}\+\)\)\{0,1}\%(\*\([0-9]\+\)\)\{0,1}\(\%()\%(\*[0-9]\+\)\{0,1}\)*\)'

function! zencoding#html#findTokens(str)
  let str = a:str
  let [pos, last_pos] = [0, 0]
  while len(str) > 0
    let token = matchstr(str, s:mx, pos)
    if token == ''
      break
    endif
	if token =~ '^\s'
      let token = matchstr(token, '^\s*\zs.*')
      let last_pos = stridx(str, token)
    endif
    let pos = stridx(str, token, pos) + len(token)
  endwhile
  return a:str[last_pos :-1]
endfunction

function! zencoding#html#parseIntoTree(abbr, type)
  let abbr = a:abbr
  let type = a:type

  let settings = zencoding#getSettings()
  if !has_key(settings, type)
    let type = 'html'
  endif
  if len(type) == 0 | let type = 'html' | endif

  let settings = zencoding#getSettings()

  if has_key(settings[type], 'indentation')
    let indent = settings[type].indentation
  else
    let indent = settings.indentation
  endif

  " try 'foo' to (foo-x)
  let rabbr = zencoding#getExpandos(type, abbr)
  if rabbr == abbr
    " try 'foo+(' to (foo-x)
    let rabbr = substitute(abbr, '\%(+\|^\)\([a-zA-Z][a-zA-Z0-9+]\+\)+\([(){}>]\|$\)', '\="(".zencoding#getExpandos(type, submatch(1)).")".submatch(2)', 'i')
  endif
  let abbr = rabbr

  let root = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0 }
  let parent = root
  let last = root
  let pos = []
  while len(abbr)
    " parse line
    let match = matchstr(abbr, s:mx)
    let str = substitute(match, s:mx, '\0', 'ig')
    let operator = substitute(match, s:mx, '\1', 'ig')
    let block_start = substitute(match, s:mx, '\2', 'ig')
    let tag_name = substitute(match, s:mx, '\3', 'ig')
    let attributes = substitute(match, s:mx, '\4', 'ig')
    let value = substitute(match, s:mx, '\5', 'ig')
    let multiplier = 0 + substitute(match, s:mx, '\6', 'ig')
    let block_end = substitute(match, s:mx, '\7', 'ig')
    let important = 0
    if len(str) == 0
      break
    endif
    if tag_name =~ '^#'
      let attributes = tag_name . attributes
      let tag_name = 'div'
    endif
    if tag_name =~ '.!$'
      let tag_name = tag_name[:-2]
      let important = 1
    endif
    if tag_name =~ '^\.'
      let attributes = tag_name . attributes
      let tag_name = 'div'
    endif
    if multiplier <= 0 | let multiplier = 1 | endif

    " make default node
    let current = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0 }
    let current.name = tag_name

    let current.important = important

    " aliases
    let aliases = zencoding#getResource(type, 'aliases', {})
    if has_key(aliases, tag_name)
      let current.name = aliases[tag_name]
    endif

    let use_pipe_for_cursor = zencoding#getResource(type, 'use_pipe_for_cursor', 1)

    " snippets
    let snippets = zencoding#getResource(type, 'snippets', {})
    if !empty(snippets) && has_key(snippets, tag_name)
      let snippet = snippets[tag_name]
      if use_pipe_for_cursor
        let snippet = substitute(snippet, '|', '${cursor}', 'g')
      endif
      let lines = split(snippet, "\n")
      call map(lines, 'substitute(v:val, "\\(    \\|\\t\\)", indent, "g")')
      let current.snippet = join(lines, "\n")
      let current.name = ''
    endif

    " default_attributes
    let default_attributes = zencoding#getResource(type, 'default_attributes', {})
    if !empty(default_attributes)
      for pat in [current.name, tag_name]
        if has_key(default_attributes, pat)
          if type(default_attributes[pat]) == 4
            let a = default_attributes[pat]
            if use_pipe_for_cursor
              for k in keys(a)
                let current.attr[k] = len(a[k]) ? substitute(a[k], '|', '${cursor}', 'g') : '${cursor}'
              endfor
            else
              for k in keys(a)
                let current.attr[k] = a[k]
              endfor
            endif
          else
            for a in default_attributes[pat]
              if use_pipe_for_cursor
                for k in keys(a)
                  let current.attr[k] = len(a[k]) ? substitute(a[k], '|', '${cursor}', 'g') : '${cursor}'
                endfor
              else
                for k in keys(a)
                  let current.attr[k] = a[k]
                endfor
              endif
            endfor
          endif
          if has_key(settings.html.default_attributes, current.name)
            let current.name = substitute(current.name, ':.*$', '', '')
          endif
          break
        endif
      endfor
    endif

    " parse attributes
    if len(attributes)
      let attr = attributes
      while len(attr)
        let item = matchstr(attr, '\(\%(\%(#[{}a-zA-Z0-9_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|\%(\.[{}a-zA-Z0-9_\-\$]\+\)*\)\)')
        if len(item) == 0
          break
        endif
        if item[0] == '#'
          let current.attr.id = item[1:]
        endif
        if item[0] == '.'
          let current.attr.class = substitute(item[1:], '\.', ' ', 'g')
        endif
        if item[0] == '['
          let atts = item[1:-2]
          while len(atts)
            let amat = matchstr(atts, '\(\w\+\%(="[^"]*"\|=''[^'']*''\|[^ ''"\]]*\)\{0,1}\)')
            if len(amat) == 0
              break
            endif
            let key = split(amat, '=')[0]
            let val = amat[len(key)+1:]
            if val =~ '^["'']'
              let val = val[1:-2]
            endif
            let current.attr[key] = val
            let atts = atts[stridx(atts, amat) + len(amat):]
          endwhile
        endif
        let attr = substitute(strpart(attr, len(item)), '^\s*', '', '')
      endwhile
    endif

    " parse text
    if tag_name =~ '^{.*}$'
      let current.name = ''
      let current.value = tag_name
    else
      let current.value = value
    endif
    let current.multiplier = multiplier

    " parse step inside/outside
    if !empty(last)
      if operator =~ '>'
        unlet! parent
        let parent = last
        let current.parent = last
        let current.pos = last.pos + 1
      else
        let current.parent = parent
        let current.pos = last.pos
      endif
    else
      let current.parent = parent
      let current.pos = 1
    endif
    if operator =~ '<'
      for c in range(len(operator))
        let tmp = parent.parent
        if empty(tmp)
          break
        endif
        let parent = tmp
      endfor
    endif

    call add(parent.child, current)
    let last = current

    " parse block
    if block_start =~ '('
      if operator =~ '>'
        let last.pos += 1
      endif
      for n in range(len(block_start))
        let pos += [last.pos]
      endfor
    endif
    if block_end =~ ')'
      for n in split(substitute(substitute(block_end, ' ', '', 'g'), ')', ',),', 'g'), ',')
        if n == ')'
          if len(pos) > 0 && last.pos >= pos[-1]
            for c in range(last.pos - pos[-1])
              let tmp = parent.parent
              if !has_key(tmp, 'parent')
                break
              endif
              let parent = tmp
            endfor
            if operator =~ '>'
              call remove(pos, -1)
            endif
            let last = parent
            let last.pos += 1
          endif
        elseif len(n)
          let cl = last.child
          let cls = []
          for c in range(n[1:])
            let cls += cl
          endfor
          let last.child = cls
        endif
      endfor
    endif
    let abbr = abbr[stridx(abbr, match) + len(match):]

    if g:zencoding_debug > 1
      echomsg "str=".str
      echomsg "block_start=".block_start
      echomsg "tag_name=".tag_name
      echomsg "operator=".operator
      echomsg "attributes=".attributes
      echomsg "value=".value
      echomsg "multiplier=".multiplier
      echomsg "block_end=".block_end
      echomsg "abbr=".abbr
      echomsg "pos=".string(pos)
      echomsg "---"
    endif
  endwhile
  return root
endfunction

function! zencoding#html#toString(settings, current, type, inline, filters, itemno, indent)
  let settings = a:settings
  let current = a:current
  let type = a:type
  let inline = a:inline
  let filters = a:filters
  let itemno = a:itemno
  let indent = a:indent
  let str = ""

  if zencoding#useFilter(filters, 'haml')
    return zencoding#haml#toString(settings, current, type, inline, filters, itemno, indent)
  endif
  if zencoding#useFilter(filters, 'slim')
    return zencoding#slim#toString(settings, current, type, inline, filters, itemno, indent)
  endif

  let comment_indent = ''
  let comment = ''
  if zencoding#useFilter(filters, 'c')
    let comment_indent = substitute(str, '^.*\(\s*\)$', '\1', '')
  endif
  let current_name = current.name
  let current_name = substitute(current.name, '\$$', itemno+1, '')
  let tmp = '<' . current_name
  for attr in keys(current.attr)
    if current_name =~ '^\(xsl:with-param\|xsl:variable\)$' && zencoding#useFilter(filters, 'xsl') && len(current.child) && attr == 'select'
      continue
    endif
    let val = current.attr[attr]
    while val =~ '\$\([^#{]\|$\)'
      let val = substitute(val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
    endwhile
    let attr = substitute(attr, '\$$', itemno+1, '')
    let tmp .= ' ' . attr . '="' . val . '"'
    if zencoding#useFilter(filters, 'c')
      if attr == 'id' | let comment .= '#' . val | endif
      if attr == 'class' | let comment .= '.' . val | endif
    endif
  endfor
  if len(comment) > 0
    let tmp = "<!-- " . comment . " -->" . (inline ? "" : "\n") . comment_indent . tmp
  endif
  let str .= tmp
  let inner = current.value[1:-2]
  if stridx(','.settings.html.inline_elements.',', ','.current_name.',') != -1
    let child_inline = 1
  else
    let child_inline = 0
  endif
  for child in current.child
    let html = zencoding#toString(child, type, child_inline, filters)
    if child.name == 'br'
      let inner = substitute(inner, '\n\s*$', '', '')
    endif
    let inner .= html
  endfor
  if len(current.child) == 1 && current.child[0].name == ''
    if stridx(','.settings.html.inline_elements.',', ','.current_name.',') == -1
      let str .= ">" . inner . "</" . current_name . ">\n"
    else
      let str .= ">" . inner . "</" . current_name . ">"
    endif
  elseif len(current.child)
    if inline == 0
      if stridx(','.settings.html.inline_elements.',', ','.current_name.',') == -1
        if inner =~ "\n$"
          let inner = substitute(inner, "\n", "\n" . indent, 'g')
          let inner = substitute(inner, indent . "$", "", 'g')
          let str .= ">\n" . indent . inner . "</" . current_name . ">\n"
        else
          let str .= ">\n" . indent . inner . indent . "\n</" . current_name . ">\n"
        endif
      else
        let str .= ">" . inner . "</" . current_name . ">\n"
      endif
    else
      let str .= ">" . inner . "</" . current_name . ">"
    endif
  else
    if inline == 0
      if stridx(','.settings.html.empty_elements.',', ','.current_name.',') != -1
        let str .= " />\n"
      else
        if stridx(','.settings.html.inline_elements.',', ','.current_name.',') == -1 && len(current.child)
          let str .= ">\n" . inner . '${cursor}</' . current_name . ">\n"
        else
          let str .= ">" . inner . '${cursor}</' . current_name . ">\n"
        endif
      endif
    else
      if stridx(','.settings.html.empty_elements.',', ','.current_name.',') != -1
        let str .= " />"
      else
        let str .= ">" . inner . '${cursor}</' . current_name . ">"
      endif
    endif
  endif
  if len(comment) > 0
    let str .= "<!-- /" . comment . " -->" . (inline ? "" : "\n") . comment_indent
  endif
  return str
endfunction

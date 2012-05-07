"=============================================================================
" zencoding.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 07-May-2012.

let s:save_cpo = &cpo
set cpo&vim

function! s:zen_getExpandos(type, key)
  let expandos = s:zen_getResource(a:type, 'expandos', {})
  if has_key(expandos, a:key)
    return expandos[a:key]
  endif
  return a:key
endfunction

function! s:zen_useFilter(filters, filter)
  for f in a:filters
    if f == a:filter
      return 1
    endif
  endfor
  return 0
endfunction

function! s:zen_isExtends(type, extend)
  if a:type == a:extend
    return 1
  endif
  if !has_key(s:zen_settings, a:type)
    return 0
  endif
  if !has_key(s:zen_settings[a:type], 'extends')
    return 0
  endif
  let extends = s:zen_settings[a:type].extends
  if type(extends) == 1
    let tmp = split(extends, '\s*,\s*')
    unlet! extends
    let extends = tmp
  endif
  for ext in extends
    if a:extend == ext
      return 1
    endif
  endfor
  return 0
endfunction

function! s:zen_parseIntoTree(abbr, type)
  let abbr = a:abbr
  let type = a:type
  if !has_key(s:zen_settings, type)
    let type = 'html'
  endif
  if len(type) == 0 | let type = 'html' | endif

  if has_key(s:zen_settings[type], 'indentation')
    let indent = s:zen_settings[type].indentation
  else
    let indent = s:zen_settings.indentation
  endif

  if s:zen_isExtends(type, "html")
    " try 'foo' to (foo-x)
    let rabbr = s:zen_getExpandos(type, abbr)
    if rabbr == abbr
      " try 'foo+(' to (foo-x)
      let rabbr = substitute(abbr, '\%(+\|^\)\([a-zA-Z][a-zA-Z0-9+]\+\)+\([(){}>]\|$\)', '\="(".s:zen_getExpandos(type, submatch(1)).")".submatch(2)', 'i')
    endif
    let abbr = rabbr
    let mx = '\([+>]\|<\+\)\{-}\s*\((*\)\{-}\s*\([@#.]\{-}[a-zA-Z\!][a-zA-Z0-9:_\!\-$]*\|'
    \       .'{.\{-}}[ \t\r\n}]*\)\(\%(\%(#{[{}a-zA-Z0-9_\-\$]\+\|'
    \       .'#[a-zA-Z0-9_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|'
    \       .'\%(\.{[{}a-zA-Z0-9_\-\$]\+\|'
    \       .'\.[a-zA-Z0-9_\-\$]\+\)\)*\)\%(\({[^}]\+}\+\)\)\{0,1}\%(\s*\*\s*\([0-9]\+\)\s*\)\{0,1}\(\%(\s*)\%(\s*\*\s*[0-9]\+\s*\)\{0,1}\)*\)'
  else
    let mx = '\([+>]\|<\+\)\{-}\s*\((*\)\{-}\s*\([@#.]\{-}[a-zA-Z\!][a-zA-Z0-9:_\!\+\-]*\|'
    \       .'{\+.\{-}}[ \t\r\n}]*\)\(\%(\%(#{[{}a-zA-Z0-9_\-\$]\+\|'
    \       .'#[a-zA-Z0-9_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|'
    \       .'\%(\.{[{}a-zA-Z0-9_\-\$]\+\|'
    \       .'\.[a-zA-Z0-9_\-\$]\+\)\)*\)\%(\({[^}]\+}\+\)\)\{0,1}\%(\s*\*\s*\([0-9]\+\)\s*\)\{0,1}\(\%(\s*)\%(\s*\*\s*[0-9]\+\s*\)\{0,1}\)*\)'
  endif
  let root = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0 }
  let parent = root
  let last = root
  let pos = []
  while len(abbr)
    " parse line
    let match = matchstr(abbr, mx)
    let str = substitute(match, mx, '\0', 'ig')
    let operator = substitute(match, mx, '\1', 'ig')
    let block_start = substitute(match, mx, '\2', 'ig')
    let tag_name = substitute(match, mx, '\3', 'ig')
    let attributes = substitute(match, mx, '\4', 'ig')
    let value = substitute(match, mx, '\5', 'ig')
    let multiplier = 0 + substitute(match, mx, '\6', 'ig')
    let block_end = substitute(match, mx, '\7', 'ig')
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
    let current = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0 }
    let current.name = tag_name

    let current.important = important

    " aliases
    let aliases = s:zen_getResource(type, 'aliases', {})
    if has_key(aliases, tag_name)
      let current.name = aliases[tag_name]
    endif

    let use_pipe_for_cursor = s:zen_getResource(type, 'use_pipe_for_cursor', 1)

    " snippets
    let snippets = s:zen_getResource(type, 'snippets', {})
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
    let default_attributes = s:zen_getResource(type, 'default_attributes', {})
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
          if has_key(s:zen_settings.html.default_attributes, current.name)
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

function! s:zen_parseTag(tag)
  let current = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0 }
  let mx = '<\([a-zA-Z][a-zA-Z0-9]*\)\(\%(\s[a-zA-Z][a-zA-Z0-9]\+=\%([^"'' \t]\+\|"[^"]\{-}"\|''[^'']\{-}''\)\s*\)*\)\(/\{0,1}\)>'
  let match = matchstr(a:tag, mx)
  let current.name = substitute(match, mx, '\1', 'i')
  let attrs = substitute(match, mx, '\2', 'i')
  let mx = '\([a-zA-Z0-9]\+\)=\%(\([^"'' \t]\+\)\|"\([^"]\{-}\)"\|''\([^'']\{-}\)''\)'
  while len(attrs) > 0
    let match = matchstr(attrs, mx)
    if len(match) == 0
      break
    endif
    let attr_match = matchlist(match, mx)
    let name = attr_match[1]
    let value = len(attr_match[2]) ? attr_match[2] : attr_match[3]
    let current.attr[name] = value
    let attrs = attrs[stridx(attrs, match) + len(match):]
  endwhile
  return current
endfunction

function! s:zen_mergeConfig(lhs, rhs)
  if type(a:lhs) == 3 && type(a:rhs) == 3
    let a:lhs += a:rhs
    if len(a:lhs)
      call remove(a:lhs, 0, len(a:lhs)-1)
    endif
    for rhi in a:rhs
      call add(a:lhs, a:rhs[rhi])
    endfor
  elseif type(a:lhs) == 4 && type(a:rhs) == 4
    for key in keys(a:rhs)
      if type(a:rhs[key]) == 3
        if !has_key(a:lhs, key)
          let a:lhs[key] = []
        endif
        let a:lhs[key] += a:rhs[key]
      elseif type(a:rhs[key]) == 4
        if has_key(a:lhs, key)
          call s:zen_mergeConfig(a:lhs[key], a:rhs[key])
        else
          let a:lhs[key] = a:rhs[key]
        endif
      else
        let a:lhs[key] = a:rhs[key]
      endif
    endfor
  endif
endfunction

function! s:zen_toString_haml(settings, current, type, inline, filters, itemno, indent)
  let settings = a:settings
  let current = a:current
  let type = a:type
  let inline = a:inline
  let filters = a:filters
  let itemno = a:itemno
  let indent = a:indent
  let str = ""

  let comment_indent = ''
  let comment = ''
  let current_name = current.name
  let current_name = substitute(current.name, '\$$', itemno+1, '')
  if len(current.name) > 0
    let str .= '%' . current_name
    let tmp = ''
    for attr in keys(current.attr)
      let val = current.attr[attr]
      while val =~ '\$\([^#{]\|$\)'
        let val = substitute(val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
      endwhile
      let attr = substitute(attr, '\$$', itemno+1, '')
      if attr == 'id'
        let str .= '#' . val
      elseif attr == 'class'
        let str .= '.' . substitute(val, ' ', '.', 'g')
      else
        if len(tmp) > 0 | let tmp .= ',' | endif
        let tmp .= ' :' . attr . ' => "' . val . '"'
      endif
    endfor
    if len(tmp)
      let str .= '{' . tmp . ' }'
    endif
    if stridx(','.settings.html.empty_elements.',', ','.current_name.',') != -1 && len(current.value) == 0
      let str .= "/"
    endif

    let inner = ''
    if len(current.value) > 0
      let lines = split(current.value[1:-2], "\n")
      let str .= " " . lines[0]
      for line in lines[1:]
        let str .= " |\n" . line
      endfor
    endif
    if len(current.child) == 1 && len(current.child[0].name) == 0
      let lines = split(current.child[0].value[1:-2], "\n")
      let str .= " " . lines[0]
      for line in lines[1:]
        let str .= " |\n" . line
      endfor
    elseif len(current.child) > 0
      for child in current.child
        let inner .= s:zen_toString(child, type, inline, filters)
      endfor
      let inner = substitute(inner, "\n", "\n  ", 'g')
      let inner = substitute(inner, "\n  $", "", 'g')
      let str .= "\n  " . inner
    endif
  endif
  let str .= "\n"
  return str
endfunction

function! s:zen_toString_css(settings, current, type, inline, filters, itemno, indent)
  return ''
endfunction

function! s:zen_toString_html(settings, current, type, inline, filters, itemno, indent)
  let settings = a:settings
  let current = a:current
  let type = a:type
  let inline = a:inline
  let filters = a:filters
  let itemno = a:itemno
  let indent = a:indent
  let str = ""

  let comment_indent = ''
  let comment = ''
  if s:zen_useFilter(filters, 'c')
    let comment_indent = substitute(str, '^.*\(\s*\)$', '\1', '')
  endif
  let current_name = current.name
  let current_name = substitute(current.name, '\$$', itemno+1, '')
  let tmp = '<' . current_name
  for attr in keys(current.attr)
    if current_name =~ '^\(xsl:with-param\|xsl:variable\)$' && s:zen_useFilter(filters, 'xsl') && len(current.child) && attr == 'select'
      continue
    endif
    let val = current.attr[attr]
    while val =~ '\$\([^#{]\|$\)'
      let val = substitute(val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
    endwhile
    let attr = substitute(attr, '\$$', itemno+1, '')
    let tmp .= ' ' . attr . '="' . val . '"'
    if s:zen_useFilter(filters, 'c')
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
    let html = s:zen_toString(child, type, child_inline, filters)
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

function! s:zen_toString(...)
  let current = a:1
  if a:0 > 1
    let type = a:2
  else
    let type = &ft
  endif
"  if !has_key(s:zen_settings, type)
"    let type = 'html'
"  endif
  if len(type) == 0 | let type = 'html' | endif
  if a:0 > 2
    let inline = a:3
  else
    let inline = 0
  endif
  if a:0 > 3
    if type(a:4) == 1
      let filters = split(a:4, '\s*,\s*')
    else
      let filters = a:4
    endif
  else
    let filters = ['html']
  endif

  if has_key(s:zen_settings, type) && has_key(s:zen_settings[type], 'indentation')
    let indent = s:zen_settings[type].indentation
  else
    let indent = s:zen_settings.indentation
  endif
  let itemno = 0
  let str = ''
  let use_pipe_for_cursor = s:zen_getResource(type, 'use_pipe_for_cursor', 1)
  while itemno < current.multiplier
    if len(current.name)
      let inner = ''
      if exists('*g:zen_toString_'.type)
        let inner = function('g:zen_toString_'.type)(s:zen_settings, current, type, inline, filters, itemno, indent)
      elseif s:zen_isExtends(type, "css")
        let inner = s:zen_toString_css(s:zen_settings, current, type, inline, filters, itemno, indent)
      elseif s:zen_useFilter(filters, 'haml')
        let inner = s:zen_toString_haml(s:zen_settings, current, type, inline, filters, itemno, indent)
      else
        let inner = s:zen_toString_html(s:zen_settings, current, type, inline, filters, itemno, indent)
      endif
      if current.multiplier > 1
        let inner = substitute(inner, '\$#', '$line'.(itemno+1).'$', 'g')
      endif
      let str .= inner
    else
      let snippet = current.snippet
      if len(current.snippet) == 0
        let snippets = s:zen_getResource(type, 'snippets', {})
        if !empty(snippets) && has_key(snippets, 'zensnippet')
          let snippet = snippets['zensnippet']
        endif
      endif
      if len(snippet) > 0
        let tmp = snippet
        if use_pipe_for_cursor
          let tmp = substitute(tmp, '|', '${cursor}', 'g')
        endif
        let tmp = substitute(tmp, '\${zenname}', current.name, 'g')
        if s:zen_isExtends(type, "css") && s:zen_useFilter(filters, 'fc')
          let tmp = substitute(tmp, '^\([^:]\+\):\([^;]*;\)', '\1: \2', '')
          if current.important
            let tmp = substitute(tmp, ';', ' !important;', '')
          endif
        endif
        for attr in keys(current.attr)
          let val = current.attr[attr]
          let tmp = substitute(tmp, '\${' . attr . '}', val, 'g')
        endfor
        let str .= tmp
      else
        if len(current.name)
          let str .= current.name
        endif
        if len(current.value)
          let str .= current.value[1:-2]
        endif
      endif
      let inner = ''
      if len(current.child)
        for n in current.child
          let inner .= s:zen_toString(n, type, inline, filters)
        endfor
        let inner = substitute(inner, "\n", "\n" . indent, 'g')
      endif
      let str = substitute(str, '\${child}', inner, '')
    endif
    let itemno = itemno + 1
  endwhile
  if s:zen_useFilter(filters, 'e')
    let str = substitute(str, '&', '\&amp;', 'g')
    let str = substitute(str, '<', '\&lt;', 'g')
    let str = substitute(str, '>', '\&gt;', 'g')
  endif
  return str
endfunction

function! s:zen_getResource(type, name, default)
  if !has_key(s:zen_settings, a:type)
    return a:default
  endif
  let ret = a:default

  if has_key(s:zen_settings[a:type], a:name)
    let v = s:zen_settings[a:type][a:name]
    if type(ret) == 3 || type(ret) == 4
      call s:zen_mergeConfig(ret, s:zen_settings[a:type][a:name])
    else
      let ret = s:zen_settings[a:type][a:name]
    endif
  endif

  if has_key(s:zen_settings[a:type], 'extends')
    let extends = s:zen_settings[a:type].extends
    if type(extends) == 1
      let tmp = split(extends, '\s*,\s*')
      unlet! extends
      let extends = tmp
    endif
    for ext in extends
      if has_key(s:zen_settings, ext) && has_key(s:zen_settings[ext], a:name)
        call s:zen_mergeConfig(ret, s:zen_settings[ext][a:name])
      endif
    endfor
  endif
  return ret
endfunction

function! s:zen_getFileType()
  let type = &ft
  if type == 'xslt' | let type = 'xsl' | endif
  if type == 'htmldjango' | let type = 'html' | endif
  if type == 'html.django_template' | let type = 'html' | endif
  if type == 'scss' | let type = 'css' | endif
  if synIDattr(synID(line("."), col("."), 1), "name") =~ '^css'
    let type = 'css'
  endif
  if synIDattr(synID(line("."), col("."), 1), "name") =~ '^html'
    let type = 'html'
  endif
  if synIDattr(synID(line("."), col("."), 1), "name") =~ '^javaScript'
    let type = 'javascript'
  endif
  if len(type) == 0 && synIDattr(synID(line("."), col("."), 1), "name") =~ '^xml'
    let type = 'xml'
  endif
  if len(type) == 0 | let type = 'html' | endif
  return type
endfunction

function! zencoding#expandAbbr(mode) range
  let type = s:zen_getFileType()
  let expand = ''
  let filters = ['html']
  let line = ''
  let part = ''
  let rest = ''

  if has_key(s:zen_settings, type) && has_key(s:zen_settings[type], 'filters')
    let filters = split(s:zen_settings[type].filters, '\s*,\s*')
  endif

  if a:mode == 2
    let leader = substitute(input('Tag: ', ''), '^\s*\(.*\)\s*$', '\1', 'g')
    if len(leader) == 0
      return
    endif
    let mx = '|\(\%(html\|haml\|e\|c\|fc\|xsl\|t\)\s*,\{0,1}\s*\)*$'
    if leader =~ mx
      let filters = split(matchstr(leader, mx)[1:], '\s*,\s*')
      let leader = substitute(leader, mx, '', '')
    endif
    if leader =~ '\*'
      let query = substitute(leader, '*', '*' . (a:lastline - a:firstline + 1), '')
      if query !~ '}\s*$'
        let query .= '>{$#}'
      endif
      let items = s:zen_parseIntoTree(query, type).child
      for item in items
        let expand .= s:zen_toString(item, type, 0, filters)
      endfor
      let line = getline(a:firstline)
      let part = substitute(line, '^\s*', '', '')
      for n in range(a:firstline, a:lastline)
        let lline = getline(n)
        let lpart = substitute(lline, '^\s\+', '', '')
        if s:zen_useFilter(filters, 't')
          let lpart = substitute(lpart, '^[0-9.-]\+\s\+', '', '')
          let lpart = substitute(lpart, '\s\+$', '', '')
        endif
        let expand = substitute(expand, '\$line'.(n-a:firstline+1).'\$', '\=lpart', 'g')
      endfor
      let expand = substitute(expand, '\$line\d*\$', '', 'g')
      let content = join(getline(a:firstline, a:lastline), "\n")
      if stridx(expand, '$#') < len(expand)-2
        let expand = substitute(expand, '^\(.*\)\$#\s*$', '\1', '')
      endif
      let expand = substitute(expand, '\$#', '\=content', 'g')
    else
      let str = ''
      if visualmode() ==# 'V'
        let line = getline(a:firstline)
        let part = substitute(line, '^\s*', '', '')
        for n in range(a:firstline, a:lastline)
          if len(leader) > 0
            let str .= getline(n) . "\n"
          else
            let lpart = substitute(getline(n), '^\s*', '', '')
            let str .= lpart . "\n"
          endif
        endfor
        let leader .= (str =~ "\n" ? ">{\n" : "{") . str . "}"
        let items = s:zen_parseIntoTree(leader, type).child
      else
        let save_regcont = @"
        let save_regtype = getregtype('"')
        silent! normal! gvygv
        let str = @"
        call setreg('"', save_regcont, save_regtype)
        let items = s:zen_parseIntoTree(leader . "{".str."}", type).child
      endif
      for item in items
        let expand .= s:zen_toString(item, type, 0, filters)
      endfor
    endif
  else
    let line = getline('.')
    if col('.') < len(line)
      let line = matchstr(line, '^\(.*\%'.col('.').'c.\)')
    endif
    if a:mode == 1
      let part = matchstr(line, '\([a-zA-Z0-9:_\-\@|]\+\)$')
    else
      let part = matchstr(line, '\(\S.*\)$')
      if s:zen_isExtends(type, "html")
        while part =~ '<.\{-}>'
          let part = substitute(part, '^.*<.\{-}>', '', '')
        endwhile
      elseif s:zen_isExtends(type, "css")
        let part = substitute(part, '^.*[;{]\s*', '', '')
      endif
    endif
    let rest = getline('.')[len(line):]
    let str = part
    let mx = '|\(\%(html\|haml\|e\|c\|fc\|xsl\|t\)\s*,\{0,1}\s*\)*$'
    if str =~ mx
      let filters = split(matchstr(str, mx)[1:], '\s*,\s*')
      let str = substitute(str, mx, '', '')
    endif
    let items = s:zen_parseIntoTree(str, type).child
    for item in items
      let expand .= s:zen_toString(item, type, 0, filters)
    endfor
    let expand = substitute(expand, '\$line\([0-9]\+\)\$', '\=submatch(1)', 'g')
  endif
  if len(expand)
    if expand !~ '\${cursor}'
      if a:mode == 2 |
        let expand = '${cursor}' . expand
      else
        let expand .= '${cursor}'
      endif
    endif
    let expand = substitute(expand, '${lang}', s:zen_settings.lang, 'g')
    let expand = substitute(expand, '${charset}', s:zen_settings.charset, 'g')
    if has_key(s:zen_settings, 'timezone') && len(s:zen_settings.timezone)
      let expand = substitute(expand, '${datetime}', strftime("%Y-%m-%dT%H:%M:%S") . s:zen_settings.timezone, 'g')
    else
      " TODO: on windows, %z/%Z is 'Tokyo(Standard)'
      let expand = substitute(expand, '${datetime}', strftime("%Y-%m-%dT%H:%M:%S %z"), 'g')
    endif
    if a:mode == 2 && visualmode() ==# 'v'
      if a:firstline == a:lastline
        let expand = substitute(expand, '\n\s*', '', 'g')
      else
        let expand = substitute(expand, '\n$', '', 'g')
      endif
      let expand = substitute(expand, '\${cursor}', '$cursor$', '')
      let expand = substitute(expand, '\${cursor}', '', 'g')
      silent! normal! gv
      let col = col("'<")
      silent! normal! c
      let line = getline('.')
      let lhs = matchstr(line, '.*\%'.(col-1).'c.')
      let rhs = matchstr(line, '\%>'.(col-1).'c.*')
      let expand = lhs.expand.rhs
      let lines = split(expand, '\n')
      call setline(line('.'), lines[0])
      if len(lines) > 1
        call append(line('.'), lines[1:])
      endif
    else
      let expand = substitute(expand, '\${cursor}', '$cursor$', '')
      let expand = substitute(expand, '\${cursor}', '', 'g')
      if line[:-len(part)-1] =~ '^\s\+$'
        let indent = line[:-len(part)-1]
      else
        let indent = ''
      endif
      let expand = substitute(expand, '\n\s*$', '', 'g')
      let expand = line[:-len(part)-1] . substitute(expand, "\n", "\n" . indent, 'g') . rest
      let lines = split(expand, '\n')
      if a:mode == 2
        silent! exe "normal! gvc"
      endif
      call setline(line('.'), lines[0])
      if len(lines) > 1
        call append(line('.'), lines[1:])
      endif
    endif
  endif
  if search('\$cursor\$', 'e')
    let oldselection = &selection
    let &selection = 'inclusive'
    silent! exe "normal! v7h\"_s"
    let &selection = oldselection
  endif
  if g:zencoding_debug > 1
    call getchar()
  endif
endfunction

function! zencoding#moveNextPrev(flag)
  if search('><\/\|\(""\)\|^\s*$', a:flag ? 'Wpb' : 'Wp') == 3
    startinsert!
  else
    silent! normal! l
    startinsert
  endif
endfunction

function! zencoding#imageSize()
  let img_region = s:search_region('<img\s', '>')
  if !s:region_is_valid(img_region) || !s:cursor_in_region(img_region)
    return
  endif
  let content = s:get_content(img_region)
  if content !~ '^<img[^><]\+>$'
    return
  endif
  let current = s:zen_parseTag(content)
  let fn = current.attr.src
  if fn !~ '^\(/\|http\)'
    let fn = simplify(expand('%:h') . '/' . fn)
  endif
  let [type, width, height] = ['', -1, -1]

  if filereadable(fn)
    let hex = substitute(system('xxd -p "'.fn.'"'), '\n', '', 'g')
  else
    let hex = substitute(system(g:zencoding_curl_command.' "'.fn.'" | xxd -p'), '\n', '', 'g')
  endif

  if hex =~ '^89504e470d0a1a0a'
    let type = 'png'
    let width = eval('0x'.hex[32:39])
    let height = eval('0x'.hex[40:47])
  endif
  if hex =~ '^ffd8'
    let pos = match(hex, 'ffc[02]')
    let type = 'jpg'
    let height = eval('0x'.hex[pos+10:pos+11])*256 + eval('0x'.hex[pos+12:pos+13])
    let width = eval('0x'.hex[pos+14:pos+15])*256 + eval('0x'.hex[pos+16:pos+17])
  endif
  if hex =~ '^47494638'
    let type = 'gif'
    let width = eval('0x'.hex[14:15].hex[12:13])
    let height = eval('0x'.hex[18:19].hex[16:17])
  endif

  if width == -1 && height == -1
    return
  endif
  let current.attr.width = width
  let current.attr.height = height
  let html = s:zen_toString(current, 'html', 1)
  call s:change_content(img_region, html)
endfunction

function! zencoding#toggleComment()
  if s:zen_getFileType() == 'css'
    let line = getline('.')
    let mx = '^\(\s*\)/\*\s*\(.*\)\s*\*/\s*$'
    if line =~ mx
      let space = substitute(matchstr(line, mx), mx, '\1', '')
      let line = substitute(matchstr(line, mx), mx, '\2', '')
      let line = space . substitute(line, '^\s*\|\s*$', '\1', 'g')
    else
      let mx = '^\(\s*\)\(.*\)\s*$'
      let line = substitute(line, mx, '\1/* \2 */', '')
    endif
    call setline('.', line)
    return
  endif

  let orgpos = getpos('.')
  let curpos = getpos('.')
  let mx = '<\%#[^>]*>'
  while 1
    let block = s:search_region('<!--', '-->')
    if s:region_is_valid(block)
      let block[1][1] += 2
      let content = s:get_content(block)
      let content = substitute(content, '^<!--\s\(.*\)\s-->$', '\1', '')
      call s:change_content(block, content)
      silent! call setpos('.', orgpos)
      return
    endif
    let block = s:search_region('<[^>]', '>')
    if !s:region_is_valid(block)
      let pos1 = searchpos('<', 'bcW')
      if pos1[0] == 0 && pos1[1] == 0
        return
      endif
      let curpos = getpos('.')
      continue
    endif
    let pos1 = block[0]
    let pos2 = block[1]
    let content = s:get_content(block)
    let tag_name = matchstr(content, '^<\zs/\{0,1}[^ \r\n>]\+')
    if tag_name[0] == '/'
      call setpos('.', [0, pos1[0], pos1[1], 0])
      let pos2 = searchpairpos('<'. tag_name[1:] . '>', '', '</' . tag_name[1:] . '>', 'bnW')
      let pos1 = searchpos('>', 'cneW')
      let block = [pos2, pos1]
    elseif tag_name =~ '/$'
      if !s:point_in_region(orgpos[1:2], block)
        " it's broken tree
        call setpos('.', orgpos)
        let block = s:search_region('>', '<')
        let content = '><!-- ' . s:get_content(block)[1:-2] . ' --><'
        call s:change_content(block, content)
        silent! call setpos('.', orgpos)
        return
      endif
    else
      call setpos('.', [0, pos2[0], pos2[1], 0])
      let pos2 = searchpairpos('<'. tag_name . '>', '', '</' . tag_name . '>', 'nW')
      call setpos('.', [0, pos2[0], pos2[1], 0])
      let pos2 = searchpos('>', 'cneW')
      let block = [pos1, pos2]
    endif
    if !s:region_is_valid(block)
      silent! call setpos('.', orgpos)
      return
    endif
    if s:point_in_region(curpos[1:2], block)
      let content = '<!-- ' . s:get_content(block) . ' -->'
      call s:change_content(block, content)
      silent! call setpos('.', orgpos)
      return
    endif
  endwhile
endfunction

function! zencoding#splitJoinTag()
  let curpos = getpos('.')
  while 1
    let mx = '<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*>'
    let pos1 = searchpos(mx, 'bcnW')
    let content = matchstr(getline(pos1[0])[pos1[1]-1:], mx)
    let tag_name = substitute(content, '^<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\).*$', '\1', '')
    let block = [pos1, [pos1[0], pos1[1] + len(content) - 1]]
    if content[-2:] == '/>' && s:cursor_in_region(block)
      let content = content[:-3] . "></" . tag_name . '>'
      call s:change_content(block, content)
      call setpos('.', [0, block[0][0], block[0][1], 0])
      return
    else
      if tag_name[0] == '/'
        let pos1 = searchpos('<' . tag_name[1:] . '[^a-zA-Z0-9]', 'bcnW')
        call setpos('.', [0, pos1[0], pos1[1], 0])
        let pos2 = searchpos('</' . tag_name[1:] . '>', 'cneW')
      else
        let pos2 = searchpos('</' . tag_name . '>', 'cneW')
      endif
      let block = [pos1, pos2]
      let content = s:get_content(block)
      if s:point_in_region(curpos[1:2], block) && content[1:] !~ '<' . tag_name . '[^a-zA-Z0-9]*[^>]*>'
        let content = matchstr(content, mx)[:-2] . '/>'
        call s:change_content(block, content)
        call setpos('.', [0, block[0][0], block[0][1], 0])
        return
      else
        if block[0][0] > 0
          call setpos('.', [0, block[0][0]-1, block[0][1], 0])
        else
          call setpos('.', curpos)
          return
        endif
      endif
    endif
  endwhile
endfunction

function! zencoding#mergeLines() range
  let lines = join(map(getline(a:firstline, a:lastline), 'matchstr(v:val, "^\\s*\\zs.*\\ze\\s*$")'), '')
  let indent = substitute(getline('.'), '^\(\s*\).*', '\1', '')
  silent! exe "normal! gvc"
  call setline('.', indent . lines)
endfunction

function! zencoding#removeTag()
  let curpos = getpos('.')
  while 1
    let mx = '<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*>'
    let pos1 = searchpos(mx, 'bcnW')
    let content = matchstr(getline(pos1[0])[pos1[1]-1:], mx)
    let tag_name = substitute(content, '^<\(/\{0,1}[a-zA-Z0-9:_\-]*\).*$', '\1', '')
    let block = [pos1, [pos1[0], pos1[1] + len(content) - 1]]
    if content[-2:] == '/>' && s:cursor_in_region(block)
      call s:change_content(block, '')
      call setpos('.', [0, block[0][0], block[0][1], 0])
      return
    else
      if tag_name[0] == '/'
        let pos1 = searchpos('<' . tag_name[1:] . '[^a-zA-Z0-9]', 'bcnW')
        call setpos('.', [0, pos1[0], pos1[1], 0])
        let pos2 = searchpos('</' . tag_name[1:] . '>', 'cneW')
      else
        let pos2 = searchpos('</' . tag_name . '>', 'cneW')
      endif
      let block = [pos1, pos2]
      let content = s:get_content(block)
      if s:point_in_region(curpos[1:2], block) && content[1:] !~ '<' . tag_name . '[^a-zA-Z0-9]*[^>]*>'
        call s:change_content(block, '')
        call setpos('.', [0, block[0][0], block[0][1], 0])
        return
      else
        if block[0][0] > 0
          call setpos('.', [0, block[0][0]-1, block[0][1], 0])
        else
          call setpos('.', curpos)
          return
        endif
      endif
    endif
  endwhile
endfunction

function! zencoding#balanceTag(flag) range
  let vblock = s:get_visualblock()
  if a:flag == -2 || a:flag == 2
    let curpos = [0, line("'<"), col("'<"), 0]
  else
    let curpos = getpos('.')
  endif
  while 1
    let mx = '<\(/\{0,1}[a-zA-Z][a-zA-Z0-9:_\-]*\)[^>]*>'
    let pos1 = searchpos(mx, (a:flag == -2 ? 'nW' : 'bcnW'))
    let content = matchstr(getline(pos1[0])[pos1[1]-1:], mx)
    let tag_name = substitute(content, '^<\(/\{0,1}[a-zA-Z0-9:_\-]*\).*$', '\1', '')
    let block = [pos1, [pos1[0], pos1[1] + len(content) - 1]]
    if !s:region_is_valid(block)
      break
    endif
    if content[-2:] == '/>' && s:point_in_region(curpos[1:2], block)
      call s:select_region(block)
      return
    else
      if tag_name[0] == '/'
        let pos1 = searchpos('<' . tag_name[1:] . '[^a-zA-Z0-9]', a:flag == -2 ? 'nW' : 'bcnW')
        if pos1[0] == 0
          break
        endif
        call setpos('.', [0, pos1[0], pos1[1], 0])
        let pos2 = searchpos('</' . tag_name[1:] . '>', 'cneW')
      else
        let pos2 = searchpos('</' . tag_name . '>', 'cneW')
      endif
      let block = [pos1, pos2]
      if !s:region_is_valid(block)
        break
      endif
      let content = s:get_content(block)
      if a:flag == -2
        let check = s:region_in_region(vblock, block) && content[1:] !~ '<' . tag_name . '[^a-zA-Z0-9]*[^>]*>'
      else
        let check = s:point_in_region(curpos[1:2], block) && content[1:] !~ '<' . tag_name . '[^a-zA-Z0-9]*[^>]*>'
      endif
      if check
        if a:flag < 0
          let l = getline(pos1[0])
          let content = matchstr(l[pos1[1]-1:], mx)
          if pos1[1] + len(content) > len(l)
            let pos1[0] += 1
          else
            let pos1[1] += len(content)
          endif
          let pos2 = searchpos('\(\n\|.\)</' . tag_name . '>', 'cnW')
        else
          let pos2 = searchpos('</' . tag_name . '>', 'cneW')
        endif
        let block = [pos1, pos2]
        call s:select_region(block)
        return
      else
        if s:region_is_valid(block)
          if a:flag == -2
            if setpos('.', [0, block[0][0]+1, block[0][1], 0]) == -1
              break
            endif
          else
            if setpos('.', [0, block[0][0]-1, block[0][1], 0]) == -1
              break
            endif
          endif
        else
          break
        endif
      endif
    endif
  endwhile
  if a:flag == -2 || a:flag == 2
    silent! exe "normal! gv"
  else
    call setpos('.', curpos)
  endif
endfunction

function! zencoding#anchorizeURL(flag)
  let mx = 'https\=:\/\/[-!#$%&*+,./:;=?@0-9a-zA-Z_~]\+'
  let pos1 = searchpos(mx, 'bcnW')
  let url = matchstr(getline(pos1[0])[pos1[1]-1:], mx)
  let block = [pos1, [pos1[0], pos1[1] + len(url) - 1]]
  if !s:cursor_in_region(block)
    return
  endif

  let mx = '.*<title[^>]*>\s*\zs\([^<]\+\)\ze\s*<\/title[^>]*>.*'
  let content = s:get_content_from_url(url, 0)
  if len(matchstr(content, mx)) == 0
    let content = s:get_content_from_url(url, 1)
  endif
  let content = substitute(content, '\r', '', 'g')
  let content = substitute(content, '[ \n]\+', ' ', 'g')
  let content = substitute(content, '<!--.\{-}-->', '', 'g')
  let title = matchstr(content, mx)

  if a:flag == 0
    let a = s:zen_parseTag('<a>')
    let a.attr.href = url
    let a.value = '{' . title . '}'
    let expand = s:zen_toString(a, 'html', 0, [])
    let expand = substitute(expand, '\${cursor}', '', 'g')
  else
    let body = s:get_text_from_html(content)
    let body = '{' . substitute(body, '^\(.\{0,100}\).*', '\1', '') . '...}'

    let blockquote = s:zen_parseTag('<blockquote class="quote">')
    let a = s:zen_parseTag('<a>')
    let a.attr.href = url
    let a.value = '{' . title . '}'
    call add(blockquote.child, a)
    call add(blockquote.child, s:zen_parseTag('<br/>'))
    let p = s:zen_parseTag('<p>')
    let p.value = body
    call add(blockquote.child, p)
    let cite = s:zen_parseTag('<cite>')
    let cite.value = '{' . url . '}'
    call add(blockquote.child, cite)
    let expand = s:zen_toString(blockquote, 'html', 0, [])
    let expand = substitute(expand, '\${cursor}', '', 'g')
    let indent = substitute(getline('.'), '^\(\s*\).*', '\1', '')
    let expand = substitute(expand, "\n", "\n" . indent, 'g')
  endif
  call s:change_content(block, expand)
endfunction

"==============================================================================
" html utils
"==============================================================================
function! s:get_content_from_url(url, utf8)
  silent! new
  if a:utf8
    silent! exec '0r ++enc=utf8 !'.g:zencoding_curl_command.' "'.substitute(a:url, '#.*', '', '').'"'
  else
    silent! exec '0r!'.g:zencoding_curl_command.' "'.substitute(a:url, '#.*', '', '').'"'
  endif
  let ret = join(getline(1, '$'), "\n")
  silent! bw!
  return ret
endfunction

function! s:get_text_from_html(buf)
  let threshold_len = 100
  let threshold_per = 0.1
  let buf = a:buf

  let buf = strpart(buf, stridx(buf, '</head>'))
  let buf = substitute(buf, '<style[^>]*>.\{-}</style>', '', 'g')
  let buf = substitute(buf, '<script[^>]*>.\{-}</script>', '', 'g')
  let res = ''
  let max = 0
  let mx = '\(<td[^>]\{-}>\)\|\(<\/td>\)\|\(<div[^>]\{-}>\)\|\(<\/div>\)'
  let m = split(buf, mx)
  for str in m
    let c = split(str, '<[^>]*?>')
    let str = substitute(str, '<[^>]\{-}>', ' ', 'g')
    let str = substitute(str, '&gt;', '>', 'g')
    let str = substitute(str, '&lt;', '<', 'g')
    let str = substitute(str, '&quot;', '"', 'g')
    let str = substitute(str, '&apos;', "'", 'g')
    let str = substitute(str, '&nbsp;', ' ', 'g')
    let str = substitute(str, '&yen;', '\&#65509;', 'g')
    let str = substitute(str, '&amp;', '\&', 'g')
    let str = substitute(str, '^\s*\(.*\)\s*$', '\1', '')
    let str = substitute(str, '\s\+', ' ', 'g')
    let l = len(str)
    if l > threshold_len
      let per = (l+0.0) / len(c)
      if max < l && per > threshold_per
        let max = l
        let res = str
      endif
    endif
  endfor
  let res = substitute(res, '^\s*\(.*\)\s*$', '\1', 'g')
  return res
endfunction
"==============================================================================

"==============================================================================
" region utils
"==============================================================================
" delete_content : delete content in region
"   if region make from between '<foo>' and '</foo>'
"   --------------------
"   begin:<foo>
"   </foo>:end
"   --------------------
"   this function make the content as following
"   --------------------
"   begin::end
"   --------------------
function! s:delete_content(region)
  let lines = getline(a:region[0][0], a:region[1][0])
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
  silent! exe "delete ".(a:region[1][0] - a:region[0][0])
  call setline(line('.'), lines[0][:a:region[0][1]-2] . lines[-1][a:region[1][1]])
endfunction

" change_content : change content in region
"   if region make from between '<foo>' and '</foo>'
"   --------------------
"   begin:<foo>
"   </foo>:end
"   --------------------
"   and content is
"   --------------------
"   foo
"   bar
"   baz
"   --------------------
"   this function make the content as following
"   --------------------
"   begin:foo
"   bar
"   baz:end
"   --------------------
function! s:change_content(region, content)
  let newlines = split(a:content, '\n', 1)
  let oldlines = getline(a:region[0][0], a:region[1][0])
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
  silent! exe "delete ".(a:region[1][0] - a:region[0][0])
  if len(newlines) == 0
    let tmp = ''
    if a:region[0][1] > 1
      let tmp = oldlines[0][:a:region[0][1]-2]
    endif
    if a:region[1][1] >= 1
      let tmp .= oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), tmp)
  elseif len(newlines) == 1
    if a:region[0][1] > 1
      let newlines[0] = oldlines[0][:a:region[0][1]-2] . newlines[0]
    endif
    if a:region[1][1] >= 1
      let newlines[0] .= oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), newlines[0])
  else
    if a:region[0][1] > 1
      let newlines[0] = oldlines[0][:a:region[0][1]-2] . newlines[0]
    endif
    if a:region[1][1] >= 1
      let newlines[-1] .= oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), newlines[0])
    call append(line('.'), newlines[1:])
  endif
endfunction

" select_region : select region
"   this function make a selection of region
function! s:select_region(region)
  call setpos('.', [0, a:region[1][0], a:region[1][1], 0])
  normal! v
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
endfunction

" point_in_region : check point is in the region
"   this function return 0 or 1
function! s:point_in_region(point, region)
  if !s:region_is_valid(a:region) | return 0 | endif
  if a:region[0][0] > a:point[0] | return 0 | endif
  if a:region[1][0] < a:point[0] | return 0 | endif
  if a:region[0][0] == a:point[0] && a:region[0][1] > a:point[1] | return 0 | endif
  if a:region[1][0] == a:point[0] && a:region[1][1] < a:point[1] | return 0 | endif
  return 1
endfunction

" cursor_in_region : check cursor is in the region
"   this function return 0 or 1
function! s:cursor_in_region(region)
  if !s:region_is_valid(a:region) | return 0 | endif
  let cur = getpos('.')[1:2]
  return s:point_in_region(cur, a:region)
endfunction

" region_is_valid : check region is valid
"   this function return 0 or 1
function! s:region_is_valid(region)
  if a:region[0][0] == 0 || a:region[1][0] == 0 | return 0 | endif
  return 1
endfunction

" search_region : make region from pattern which is composing start/end
"   this function return array of position
function! s:search_region(start, end)
  return [searchpairpos(a:start, '', a:end, 'bcnW'), searchpairpos(a:start, '\%#', a:end, 'nW')]
endfunction

" get_content : get content in region
"   this function return string in region
function! s:get_content(region)
  if !s:region_is_valid(a:region)
    return ''
  endif
  let lines = getline(a:region[0][0], a:region[1][0])
  if a:region[0][0] == a:region[1][0]
    let lines[0] = lines[0][a:region[0][1]-1:a:region[1][1]-1]
  else
    let lines[0] = lines[0][a:region[0][1]-1:]
    let lines[-1] = lines[-1][:a:region[1][1]-1]
  endif
  return join(lines, "\n")
endfunction

" region_in_region : check region is in the region
"   this function return 0 or 1
function! s:region_in_region(outer, inner)
  if !s:region_is_valid(a:inner) || !s:region_is_valid(a:outer)
    return 0
  endif
  return s:point_in_region(a:inner[0], a:outer) && s:point_in_region(a:inner[1], a:outer)
endfunction

" get_visualblock : get region of visual block
"   this function return region of visual block
function! s:get_visualblock()
  return [[line("'<"), col("'<")], [line("'>"), col("'>")]]
endfunction
"==============================================================================

function! zencoding#ExpandWord(abbr, type, orig)
  let mx = '|\(\%(html\|haml\|e\|c\|fc\|xsl\|t\)\s*,\{0,1}\s*\)*$'
  let str = a:abbr
  let type = a:type

  if len(type) == 0 | let type = 'html' | endif
  if str =~ mx
    let filters = split(matchstr(str, mx)[1:], '\s*,\s*')
    let str = substitute(str, mx, '', '')
  elseif has_key(s:zen_settings[a:type], 'filters')
    let filters = split(s:zen_settings[a:type].filters, '\s*,\s*')
  else
    let filters = ['html']
  endif
  let items = s:zen_parseIntoTree(str, a:type).child
  let expand = ''
  for item in items
    let expand .= s:zen_toString(item, a:type, 0, filters)
  endfor
  if a:orig == 0
    let expand = substitute(expand, '\${lang}', s:zen_settings.lang, 'g')
    let expand = substitute(expand, '\${charset}', s:zen_settings.charset, 'g')
    let expand = substitute(expand, '\${cursor}', '', 'g')
  endif
  return expand
endfunction

function! zencoding#CompleteTag(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[a-zA-Z0-9:_\@\-]'
      let start -= 1
    endwhile
    return start
  else
    let type = s:zen_getFileType()
    let res = []

    let snippets = s:zen_getResource(type, 'snippets', {})
    for item in keys(snippets)
      if stridx(item, a:base) != -1
        call add(res, substitute(item, '\${cursor}\||', '', 'g'))
      endif
    endfor
    let aliases = s:zen_getResource(type, 'aliases', {})
    for item in values(aliases)
      if stridx(item, a:base) != -1
        call add(res, substitute(item, '\${cursor}\||', '', 'g'))
      endif
    endfor
    return res
  endif
endfunction

unlet! s:zen_settings
let s:zen_settings = {
\    'indentation': "\t",
\    'lang': "en",
\    'charset': "UTF-8",
\    'css': {
\        'snippets': {
\            '@i': '@import url(|);',
\            '@m': "@media print {\n\t|\n}",
\            '@f': "@font-face {\n\tfont-family:|;\n\tsrc:url(|);\n}",
\            '!': '!important',
\            'pos': 'position:|;',
\            'pos:s': 'position:static;',
\            'pos:a': 'position:absolute;',
\            'pos:r': 'position:relative;',
\            'pos:f': 'position:fixed;',
\            't': 'top:|;',
\            't:a': 'top:auto;',
\            'r': 'right:|;',
\            'r:a': 'right:auto;',
\            'b': 'bottom:|;',
\            'b:a': 'bottom:auto;',
\            'l': 'left:|;',
\            'l:a': 'left:auto;',
\            'z': 'z-index:|;',
\            'z:a': 'z-index:auto;',
\            'fl': 'float:|;',
\            'fl:n': 'float:none;',
\            'fl:l': 'float:left;',
\            'fl:r': 'float:right;',
\            'cl': 'clear:|;',
\            'cl:n': 'clear:none;',
\            'cl:l': 'clear:left;',
\            'cl:r': 'clear:right;',
\            'cl:b': 'clear:both;',
\            'd': 'display:|;',
\            'd:n': 'display:none;',
\            'd:b': 'display:block;',
\            'd:i': 'display:inline;',
\            'd:ib': 'display:inline-block;',
\            'd:li': 'display:list-item;',
\            'd:ri': 'display:run-in;',
\            'd:cp': 'display:compact;',
\            'd:tb': 'display:table;',
\            'd:itb': 'display:inline-table;',
\            'd:tbcp': 'display:table-caption;',
\            'd:tbcl': 'display:table-column;',
\            'd:tbclg': 'display:table-column-group;',
\            'd:tbhg': 'display:table-header-group;',
\            'd:tbfg': 'display:table-footer-group;',
\            'd:tbr': 'display:table-row;',
\            'd:tbrg': 'display:table-row-group;',
\            'd:tbc': 'display:table-cell;',
\            'd:rb': 'display:ruby;',
\            'd:rbb': 'display:ruby-base;',
\            'd:rbbg': 'display:ruby-base-group;',
\            'd:rbt': 'display:ruby-text;',
\            'd:rbtg': 'display:ruby-text-group;',
\            'v': 'visibility:|;',
\            'v:v': 'visibility:visible;',
\            'v:h': 'visibility:hidden;',
\            'v:c': 'visibility:collapse;',
\            'ov': 'overflow:|;',
\            'ov:v': 'overflow:visible;',
\            'ov:h': 'overflow:hidden;',
\            'ov:s': 'overflow:scroll;',
\            'ov:a': 'overflow:auto;',
\            'ovx': 'overflow-x:|;',
\            'ovx:v': 'overflow-x:visible;',
\            'ovx:h': 'overflow-x:hidden;',
\            'ovx:s': 'overflow-x:scroll;',
\            'ovx:a': 'overflow-x:auto;',
\            'ovy': 'overflow-y:|;',
\            'ovy:v': 'overflow-y:visible;',
\            'ovy:h': 'overflow-y:hidden;',
\            'ovy:s': 'overflow-y:scroll;',
\            'ovy:a': 'overflow-y:auto;',
\            'ovs': 'overflow-style:|;',
\            'ovs:a': 'overflow-style:auto;',
\            'ovs:s': 'overflow-style:scrollbar;',
\            'ovs:p': 'overflow-style:panner;',
\            'ovs:m': 'overflow-style:move;',
\            'ovs:mq': 'overflow-style:marquee;',
\            'zoo': 'zoom:1;',
\            'cp': 'clip:|;',
\            'cp:a': 'clip:auto;',
\            'cp:r': 'clip:rect(|);',
\            'bxz': 'box-sizing:|;',
\            'bxz:cb': 'box-sizing:content-box;',
\            'bxz:bb': 'box-sizing:border-box;',
\            'bxsh': 'box-shadow:|;',
\            'bxsh:n': 'box-shadow:none;',
\            'bxsh:w': '-webkit-box-shadow:0 0 0 #000;',
\            'bxsh:m': '-moz-box-shadow:0 0 0 0 #000;',
\            'm': 'margin:|;',
\            'm:a': 'margin:auto;',
\            'm:0': 'margin:0;',
\            'm:2': 'margin:0 0;',
\            'm:3': 'margin:0 0 0;',
\            'm:4': 'margin:0 0 0 0;',
\            'mt': 'margin-top:|;',
\            'mt:a': 'margin-top:auto;',
\            'mr': 'margin-right:|;',
\            'mr:a': 'margin-right:auto;',
\            'mb': 'margin-bottom:|;',
\            'mb:a': 'margin-bottom:auto;',
\            'ml': 'margin-left:|;',
\            'ml:a': 'margin-left:auto;',
\            'p': 'padding:|;',
\            'p:0': 'padding:0;',
\            'p:2': 'padding:0 0;',
\            'p:3': 'padding:0 0 0;',
\            'p:4': 'padding:0 0 0 0;',
\            'pt': 'padding-top:|;',
\            'pr': 'padding-right:|;',
\            'pb': 'padding-bottom:|;',
\            'pl': 'padding-left:|;',
\            'w': 'width:|;',
\            'w:a': 'width:auto;',
\            'h': 'height:|;',
\            'h:a': 'height:auto;',
\            'maw': 'max-width:|;',
\            'maw:n': 'max-width:none;',
\            'mah': 'max-height:|;',
\            'mah:n': 'max-height:none;',
\            'miw': 'min-width:|;',
\            'mih': 'min-height:|;',
\            'o': 'outline:|;',
\            'o:n': 'outline:none;',
\            'oo': 'outline-offset:|;',
\            'ow': 'outline-width:|;',
\            'os': 'outline-style:|;',
\            'oc': 'outline-color:#000;',
\            'oc:i': 'outline-color:invert;',
\            'bd': 'border:|;',
\            'bd+': 'border:1px solid #000;',
\            'bd:n': 'border:none;',
\            'bdbk': 'border-break:|;',
\            'bdbk:c': 'border-break:close;',
\            'bdcl': 'border-collapse:|;',
\            'bdcl:c': 'border-collapse:collapse;',
\            'bdcl:s': 'border-collapse:separate;',
\            'bdc': 'border-color:#000;',
\            'bdi': 'border-image:url(|);',
\            'bdi:n': 'border-image:none;',
\            'bdi:w': '-webkit-border-image:url(|) 0 0 0 0 stretch stretch;',
\            'bdi:m': '-moz-border-image:url(|) 0 0 0 0 stretch stretch;',
\            'bdti': 'border-top-image:url(|);',
\            'bdti:n': 'border-top-image:none;',
\            'bdri': 'border-right-image:url(|);',
\            'bdri:n': 'border-right-image:none;',
\            'bdbi': 'border-bottom-image:url(|);',
\            'bdbi:n': 'border-bottom-image:none;',
\            'bdli': 'border-left-image:url(|);',
\            'bdli:n': 'border-left-image:none;',
\            'bdci': 'border-corner-image:url(|);',
\            'bdci:n': 'border-corner-image:none;',
\            'bdci:c': 'border-corner-image:continue;',
\            'bdtli': 'border-top-left-image:url(|);',
\            'bdtli:n': 'border-top-left-image:none;',
\            'bdtli:c': 'border-top-left-image:continue;',
\            'bdtri': 'border-top-right-image:url(|);',
\            'bdtri:n': 'border-top-right-image:none;',
\            'bdtri:c': 'border-top-right-image:continue;',
\            'bdbri': 'border-bottom-right-image:url(|);',
\            'bdbri:n': 'border-bottom-right-image:none;',
\            'bdbri:c': 'border-bottom-right-image:continue;',
\            'bdbli': 'border-bottom-left-image:url(|);',
\            'bdbli:n': 'border-bottom-left-image:none;',
\            'bdbli:c': 'border-bottom-left-image:continue;',
\            'bdf': 'border-fit:|;',
\            'bdf:c': 'border-fit:clip;',
\            'bdf:r': 'border-fit:repeat;',
\            'bdf:sc': 'border-fit:scale;',
\            'bdf:st': 'border-fit:stretch;',
\            'bdf:ow': 'border-fit:overwrite;',
\            'bdf:of': 'border-fit:overflow;',
\            'bdf:sp': 'border-fit:space;',
\            'bdl': 'border-left:|;',
\            'bdl:a': 'border-length:auto;',
\            'bdsp': 'border-spacing:|;',
\            'bds': 'border-style:|;',
\            'bds:n': 'border-style:none;',
\            'bds:h': 'border-style:hidden;',
\            'bds:dt': 'border-style:dotted;',
\            'bds:ds': 'border-style:dashed;',
\            'bds:s': 'border-style:solid;',
\            'bds:db': 'border-style:double;',
\            'bds:dtds': 'border-style:dot-dash;',
\            'bds:dtdtds': 'border-style:dot-dot-dash;',
\            'bds:w': 'border-style:wave;',
\            'bds:g': 'border-style:groove;',
\            'bds:r': 'border-style:ridge;',
\            'bds:i': 'border-style:inset;',
\            'bds:o': 'border-style:outset;',
\            'bdw': 'border-width:|;',
\            'bdt': 'border-top:|;',
\            'bdt+': 'border-top:1px solid #000;',
\            'bdt:n': 'border-top:none;',
\            'bdtw': 'border-top-width:|;',
\            'bdts': 'border-top-style:|;',
\            'bdts:n': 'border-top-style:none;',
\            'bdtc': 'border-top-color:#000;',
\            'bdr': 'border-right:|;',
\            'bdr+': 'border-right:1px solid #000;',
\            'bdr:n': 'border-right:none;',
\            'bdrw': 'border-right-width:|;',
\            'bdrs': 'border-right-style:|;',
\            'bdrs:n': 'border-right-style:none;',
\            'bdrc': 'border-right-color:#000;',
\            'bdb': 'border-bottom:|;',
\            'bdb+': 'border-bottom:1px solid #000;',
\            'bdb:n': 'border-bottom:none;',
\            'bdbw': 'border-bottom-width:|;',
\            'bdbs': 'border-bottom-style:|;',
\            'bdbs:n': 'border-bottom-style:none;',
\            'bdbc': 'border-bottom-color:#000;',
\            'bdln': 'border-length:|;',
\            'bdl+': 'border-left:1px solid #000;',
\            'bdl:n': 'border-left:none;',
\            'bdlw': 'border-left-width:|;',
\            'bdls': 'border-left-style:|;',
\            'bdls:n': 'border-left-style:none;',
\            'bdlc': 'border-left-color:#000;',
\            'bdrz': 'border-radius:|;',
\            'bdtrrz': 'border-top-right-radius:|;',
\            'bdtlrz': 'border-top-left-radius:|;',
\            'bdbrrz': 'border-bottom-right-radius:|;',
\            'bdblrz': 'border-bottom-left-radius:|;',
\            'bdrz:w': '-webkit-border-radius:|;',
\            'bdrz:m': '-moz-border-radius:|;',
\            'bg': 'background:|;',
\            'bg+': 'background:#FFF url(|) 0 0 no-repeat;',
\            'bg:n': 'background:none;',
\            'bg:ie': 'filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src=''|x.png'');',
\            'bgc': 'background-color:#FFF;',
\            'bgi': 'background-image:url(|);',
\            'bgi:n': 'background-image:none;',
\            'bgr': 'background-repeat:|;',
\            'bgr:n': 'background-repeat:no-repeat;',
\            'bgr:x': 'background-repeat:repeat-x;',
\            'bgr:y': 'background-repeat:repeat-y;',
\            'bga': 'background-attachment:|;',
\            'bga:f': 'background-attachment:fixed;',
\            'bga:s': 'background-attachment:scroll;',
\            'bgp': 'background-position:0 0;',
\            'bgpx': 'background-position-x:|;',
\            'bgpy': 'background-position-y:|;',
\            'bgbk': 'background-break:|;',
\            'bgbk:bb': 'background-break:bounding-box;',
\            'bgbk:eb': 'background-break:each-box;',
\            'bgbk:c': 'background-break:continuous;',
\            'bgcp': 'background-clip:|;',
\            'bgcp:bb': 'background-clip:border-box;',
\            'bgcp:pb': 'background-clip:padding-box;',
\            'bgcp:cb': 'background-clip:content-box;',
\            'bgcp:nc': 'background-clip:no-clip;',
\            'bgo': 'background-origin:|;',
\            'bgo:pb': 'background-origin:padding-box;',
\            'bgo:bb': 'background-origin:border-box;',
\            'bgo:cb': 'background-origin:content-box;',
\            'bgz': 'background-size:|;',
\            'bgz:a': 'background-size:auto;',
\            'bgz:ct': 'background-size:contain;',
\            'bgz:cv': 'background-size:cover;',
\            'c': 'color:#000;',
\            'tbl': 'table-layout:|;',
\            'tbl:a': 'table-layout:auto;',
\            'tbl:f': 'table-layout:fixed;',
\            'cps': 'caption-side:|;',
\            'cps:t': 'caption-side:top;',
\            'cps:b': 'caption-side:bottom;',
\            'ec': 'empty-cells:|;',
\            'ec:s': 'empty-cells:show;',
\            'ec:h': 'empty-cells:hide;',
\            'lis': 'list-style:|;',
\            'lis:n': 'list-style:none;',
\            'lisp': 'list-style-position:|;',
\            'lisp:i': 'list-style-position:inside;',
\            'lisp:o': 'list-style-position:outside;',
\            'list': 'list-style-type:|;',
\            'list:n': 'list-style-type:none;',
\            'list:d': 'list-style-type:disc;',
\            'list:c': 'list-style-type:circle;',
\            'list:s': 'list-style-type:square;',
\            'list:dc': 'list-style-type:decimal;',
\            'list:dclz': 'list-style-type:decimal-leading-zero;',
\            'list:lr': 'list-style-type:lower-roman;',
\            'list:ur': 'list-style-type:upper-roman;',
\            'lisi': 'list-style-image:|;',
\            'lisi:n': 'list-style-image:none;',
\            'q': 'quotes:|;',
\            'q:n': 'quotes:none;',
\            'q:ru': 'quotes:''\00AB'' ''\00BB'' ''\201E'' ''\201C'';',
\            'q:en': 'quotes:''\201C'' ''\201D'' ''\2018'' ''\2019'';',
\            'ct': 'content:|;',
\            'ct:n': 'content:normal;',
\            'ct:oq': 'content:open-quote;',
\            'ct:noq': 'content:no-open-quote;',
\            'ct:cq': 'content:close-quote;',
\            'ct:ncq': 'content:no-close-quote;',
\            'ct:a': 'content:attr(|);',
\            'ct:c': 'content:counter(|);',
\            'ct:cs': 'content:counters(|);',
\            'coi': 'counter-increment:|;',
\            'cor': 'counter-reset:|;',
\            'va': 'vertical-align:|;',
\            'va:sup': 'vertical-align:super;',
\            'va:t': 'vertical-align:top;',
\            'va:tt': 'vertical-align:text-top;',
\            'va:m': 'vertical-align:middle;',
\            'va:bl': 'vertical-align:baseline;',
\            'va:b': 'vertical-align:bottom;',
\            'va:tb': 'vertical-align:text-bottom;',
\            'va:sub': 'vertical-align:sub;',
\            'ta': 'text-align:|;',
\            'ta:l': 'text-align:left;',
\            'ta:c': 'text-align:center;',
\            'ta:r': 'text-align:right;',
\            'tal': 'text-align-last:|;',
\            'tal:a': 'text-align-last:auto;',
\            'tal:l': 'text-align-last:left;',
\            'tal:c': 'text-align-last:center;',
\            'tal:r': 'text-align-last:right;',
\            'td': 'text-decoration:|;',
\            'td:n': 'text-decoration:none;',
\            'td:u': 'text-decoration:underline;',
\            'td:o': 'text-decoration:overline;',
\            'td:l': 'text-decoration:line-through;',
\            'te': 'text-emphasis:|;',
\            'te:n': 'text-emphasis:none;',
\            'te:ac': 'text-emphasis:accent;',
\            'te:dt': 'text-emphasis:dot;',
\            'te:c': 'text-emphasis:circle;',
\            'te:ds': 'text-emphasis:disc;',
\            'te:b': 'text-emphasis:before;',
\            'te:a': 'text-emphasis:after;',
\            'th': 'text-height:|;',
\            'th:a': 'text-height:auto;',
\            'th:f': 'text-height:font-size;',
\            'th:t': 'text-height:text-size;',
\            'th:m': 'text-height:max-size;',
\            'ti': 'text-indent:|;',
\            'ti:-': 'text-indent:-9999px;',
\            'tj': 'text-justify:|;',
\            'tj:a': 'text-justify:auto;',
\            'tj:iw': 'text-justify:inter-word;',
\            'tj:ii': 'text-justify:inter-ideograph;',
\            'tj:ic': 'text-justify:inter-cluster;',
\            'tj:d': 'text-justify:distribute;',
\            'tj:k': 'text-justify:kashida;',
\            'tj:t': 'text-justify:tibetan;',
\            'to': 'text-outline:|;',
\            'to+': 'text-outline:0 0 #000;',
\            'to:n': 'text-outline:none;',
\            'tr': 'text-replace:|;',
\            'tr:n': 'text-replace:none;',
\            'tt': 'text-transform:|;',
\            'tt:n': 'text-transform:none;',
\            'tt:c': 'text-transform:capitalize;',
\            'tt:u': 'text-transform:uppercase;',
\            'tt:l': 'text-transform:lowercase;',
\            'tw': 'text-wrap:|;',
\            'tw:n': 'text-wrap:normal;',
\            'tw:no': 'text-wrap:none;',
\            'tw:u': 'text-wrap:unrestricted;',
\            'tw:s': 'text-wrap:suppress;',
\            'tsh': 'text-shadow:|;',
\            'tsh+': 'text-shadow:0 0 0 #000;',
\            'tsh:n': 'text-shadow:none;',
\            'lh': 'line-height:|;',
\            'whs': 'white-space:|;',
\            'whs:n': 'white-space:normal;',
\            'whs:p': 'white-space:pre;',
\            'whs:nw': 'white-space:nowrap;',
\            'whs:pw': 'white-space:pre-wrap;',
\            'whs:pl': 'white-space:pre-line;',
\            'whsc': 'white-space-collapse:|;',
\            'whsc:n': 'white-space-collapse:normal;',
\            'whsc:k': 'white-space-collapse:keep-all;',
\            'whsc:l': 'white-space-collapse:loose;',
\            'whsc:bs': 'white-space-collapse:break-strict;',
\            'whsc:ba': 'white-space-collapse:break-all;',
\            'wob': 'word-break:|;',
\            'wob:n': 'word-break:normal;',
\            'wob:k': 'word-break:keep-all;',
\            'wob:l': 'word-break:loose;',
\            'wob:bs': 'word-break:break-strict;',
\            'wob:ba': 'word-break:break-all;',
\            'wos': 'word-spacing:|;',
\            'wow': 'word-wrap:|;',
\            'wow:nm': 'word-wrap:normal;',
\            'wow:n': 'word-wrap:none;',
\            'wow:u': 'word-wrap:unrestricted;',
\            'wow:s': 'word-wrap:suppress;',
\            'lts': 'letter-spacing:|;',
\            'f': 'font:|;',
\            'f+': 'font:1em Arial,sans-serif;',
\            'fw': 'font-weight:|;',
\            'fw:n': 'font-weight:normal;',
\            'fw:b': 'font-weight:bold;',
\            'fw:br': 'font-weight:bolder;',
\            'fw:lr': 'font-weight:lighter;',
\            'fs': 'font-style:|;',
\            'fs:n': 'font-style:normal;',
\            'fs:i': 'font-style:italic;',
\            'fs:o': 'font-style:oblique;',
\            'fv': 'font-variant:|;',
\            'fv:n': 'font-variant:normal;',
\            'fv:sc': 'font-variant:small-caps;',
\            'fz': 'font-size:|;',
\            'fza': 'font-size-adjust:|;',
\            'fza:n': 'font-size-adjust:none;',
\            'ff': 'font-family:|;',
\            'ff:s': 'font-family:serif;',
\            'ff:ss': 'font-family:sans-serif;',
\            'ff:c': 'font-family:cursive;',
\            'ff:f': 'font-family:fantasy;',
\            'ff:m': 'font-family:monospace;',
\            'fef': 'font-effect:|;',
\            'fef:n': 'font-effect:none;',
\            'fef:eg': 'font-effect:engrave;',
\            'fef:eb': 'font-effect:emboss;',
\            'fef:o': 'font-effect:outline;',
\            'fem': 'font-emphasize:|;',
\            'femp': 'font-emphasize-position:|;',
\            'femp:b': 'font-emphasize-position:before;',
\            'femp:a': 'font-emphasize-position:after;',
\            'fems': 'font-emphasize-style:|;',
\            'fems:n': 'font-emphasize-style:none;',
\            'fems:ac': 'font-emphasize-style:accent;',
\            'fems:dt': 'font-emphasize-style:dot;',
\            'fems:c': 'font-emphasize-style:circle;',
\            'fems:ds': 'font-emphasize-style:disc;',
\            'fsm': 'font-smooth:|;',
\            'fsm:a': 'font-smooth:auto;',
\            'fsm:n': 'font-smooth:never;',
\            'fsm:aw': 'font-smooth:always;',
\            'fst': 'font-stretch:|;',
\            'fst:n': 'font-stretch:normal;',
\            'fst:uc': 'font-stretch:ultra-condensed;',
\            'fst:ec': 'font-stretch:extra-condensed;',
\            'fst:c': 'font-stretch:condensed;',
\            'fst:sc': 'font-stretch:semi-condensed;',
\            'fst:se': 'font-stretch:semi-expanded;',
\            'fst:e': 'font-stretch:expanded;',
\            'fst:ee': 'font-stretch:extra-expanded;',
\            'fst:ue': 'font-stretch:ultra-expanded;',
\            'op': 'opacity:|;',
\            'op:ie': 'filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=100);',
\            'op:ms': '-ms-filter:''progid:DXImageTransform.Microsoft.Alpha(Opacity=100)'';',
\            'rz': 'resize:|;',
\            'rz:n': 'resize:none;',
\            'rz:b': 'resize:both;',
\            'rz:h': 'resize:horizontal;',
\            'rz:v': 'resize:vertical;',
\            'cur': 'cursor:|;',
\            'cur:a': 'cursor:auto;',
\            'cur:d': 'cursor:default;',
\            'cur:c': 'cursor:crosshair;',
\            'cur:ha': 'cursor:hand;',
\            'cur:he': 'cursor:help;',
\            'cur:m': 'cursor:move;',
\            'cur:p': 'cursor:pointer;',
\            'cur:t': 'cursor:text;',
\            'pgbb': 'page-break-before:|;',
\            'pgbb:au': 'page-break-before:auto;',
\            'pgbb:al': 'page-break-before:always;',
\            'pgbb:l': 'page-break-before:left;',
\            'pgbb:r': 'page-break-before:right;',
\            'pgbi': 'page-break-inside:|;',
\            'pgbi:au': 'page-break-inside:auto;',
\            'pgbi:av': 'page-break-inside:avoid;',
\            'pgba': 'page-break-after:|;',
\            'pgba:au': 'page-break-after:auto;',
\            'pgba:al': 'page-break-after:always;',
\            'pgba:l': 'page-break-after:left;',
\            'pgba:r': 'page-break-after:right;',
\            'orp': 'orphans:|;',
\            'wid': 'widows:|;'
\        },
\        'filters': 'fc'
\    },
\    'sass': {
\        'extends': 'css',
\    },
\    'html': {
\        'snippets': {
\            'cc:ie6': "<!--[if lte IE 6]>\n\t${child}|\n<![endif]-->",
\            'cc:ie': "<!--[if IE]>\n\t${child}|\n<![endif]-->",
\            'cc:noie': "<!--[if !IE]><!-->\n\t${child}|\n<!--<![endif]-->",
\            'html:4t': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\">\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:4s': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\">\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xt': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xxs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:5': "<!DOCTYPE HTML>\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <meta charset=\"${charset}\">\n"
\                    ."    <title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>"
\        },
\        'default_attributes': {
\            'a': {'href': ''},
\            'a:link': {'href': 'http://|'},
\            'a:mail': {'href': 'mailto:|'},
\            'abbr': {'title': ''},
\            'acronym': {'title': ''},
\            'base': {'href': ''},
\            'bdo': {'dir': ''},
\            'bdo:r': {'dir': 'rtl'},
\            'bdo:l': {'dir': 'ltr'},
\            'del': {'datetime': '${datetime}'},
\            'ins': {'datetime': '${datetime}'},
\            'link:css': [{'rel': 'stylesheet'}, {'type': 'text/css'}, {'href': '|style.css'}, {'media': 'all'}],
\            'link:print': [{'rel': 'stylesheet'}, {'type': 'text/css'}, {'href': '|print.css'}, {'media': 'print'}],
\            'link:favicon': [{'rel': 'shortcut icon'}, {'type': 'image/x-icon'}, {'href': '|favicon.ico'}],
\            'link:touch': [{'rel': 'apple-touch-icon'}, {'href': '|favicon.png'}],
\            'link:rss': [{'rel': 'alternate'}, {'type': 'application/rss+xml'}, {'title': 'RSS'}, {'href': '|rss.xml'}],
\            'link:atom': [{'rel': 'alternate'}, {'type': 'application/atom+xml'}, {'title': 'Atom'}, {'href': 'atom.xml'}],
\            'meta:utf': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=UTF-8'}],
\            'meta:win': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=Win-1251'}],
\            'meta:compat': [{'http-equiv': 'X-UA-Compatible'}, {'content': 'IE=7'}],
\            'style': {'type': 'text/css'},
\            'script': {'type': 'text/javascript'},
\            'script:src': [{'type': 'text/javascript'}, {'src': ''}],
\            'img': [{'src': ''}, {'alt': ''}],
\            'iframe': [{'src': ''}, {'frameborder': '0'}],
\            'embed': [{'src': ''}, {'type': ''}],
\            'object': [{'data': ''}, {'type': ''}],
\            'param': [{'name': ''}, {'value': ''}],
\            'map': {'name': ''},
\            'area': [{'shape': ''}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:d': [{'shape': 'default'}, {'href': ''}, {'alt': ''}],
\            'area:c': [{'shape': 'circle'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:r': [{'shape': 'rect'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:p': [{'shape': 'poly'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'link': [{'rel': 'stylesheet'}, {'href': ''}],
\            'form': {'action': ''},
\            'form:get': {'action': '', 'method': 'get'},
\            'form:post': {'action': '', 'method': 'post'},
\            'form:upload': {'action': '', 'method': 'post', 'enctype': 'multipart/form-data'},
\            'label': {'for': ''},
\            'input': {'type': ''},
\            'input:hidden': [{'type': 'hidden'}, {'name': ''}],
\            'input:h': [{'type': 'hidden'}, {'name': ''}],
\            'input:text': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:t': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:search': [{'type': 'search'}, {'name': ''}, {'id': ''}],
\            'input:email': [{'type': 'email'}, {'name': ''}, {'id': ''}],
\            'input:url': [{'type': 'url'}, {'name': ''}, {'id': ''}],
\            'input:password': [{'type': 'password'}, {'name': ''}, {'id': ''}],
\            'input:p': [{'type': 'password'}, {'name': ''}, {'id': ''}],
\            'input:datetime': [{'type': 'datetime'}, {'name': ''}, {'id': ''}],
\            'input:date': [{'type': 'date'}, {'name': ''}, {'id': ''}],
\            'input:datetime-local': [{'type': 'datetime-local'}, {'name': ''}, {'id': ''}],
\            'input:month': [{'type': 'month'}, {'name': ''}, {'id': ''}],
\            'input:week': [{'type': 'week'}, {'name': ''}, {'id': ''}],
\            'input:time': [{'type': 'time'}, {'name': ''}, {'id': ''}],
\            'input:number': [{'type': 'number'}, {'name': ''}, {'id': ''}],
\            'input:color': [{'type': 'color'}, {'name': ''}, {'id': ''}],
\            'input:checkbox': [{'type': 'checkbox'}, {'name': ''}, {'id': ''}],
\            'input:c': [{'type': 'checkbox'}, {'name': ''}, {'id': ''}],
\            'input:radio': [{'type': 'radio'}, {'name': ''}, {'id': ''}],
\            'input:r': [{'type': 'radio'}, {'name': ''}, {'id': ''}],
\            'input:range': [{'type': 'range'}, {'name': ''}, {'id': ''}],
\            'input:file': [{'type': 'file'}, {'name': ''}, {'id': ''}],
\            'input:f': [{'type': 'file'}, {'name': ''}, {'id': ''}],
\            'input:submit': [{'type': 'submit'}, {'value': ''}],
\            'input:s': [{'type': 'submit'}, {'value': ''}],
\            'input:image': [{'type': 'image'}, {'src': ''}, {'alt': ''}],
\            'input:i': [{'type': 'image'}, {'src': ''}, {'alt': ''}],
\            'input:reset': [{'type': 'reset'}, {'value': ''}],
\            'input:button': [{'type': 'button'}, {'value': ''}],
\            'input:b': [{'type': 'button'}, {'value': ''}],
\            'select': [{'name': ''}, {'id': ''}],
\            'option': {'value': ''},
\            'textarea': [{'name': ''}, {'id': ''}, {'cols': '30'}, {'rows': '10'}],
\            'menu:context': {'type': 'context'},
\            'menu:c': {'type': 'context'},
\            'menu:toolbar': {'type': 'toolbar'},
\            'menu:t': {'type': 'toolbar'},
\            'video': {'src': ''},
\            'audio': {'src': ''},
\            'html:xml': [{'xmlns': 'http://www.w3.org/1999/xhtml'}, {'xml:lang': '${lang}'}]
\        },
\        'aliases': {
\            'link:*': 'link',
\            'meta:*': 'meta',
\            'area:*': 'area',
\            'bdo:*': 'bdo',
\            'form:*': 'form',
\            'input:*': 'input',
\            'script:*': 'script',
\            'html:*': 'html',
\            'a:*': 'a',
\            'menu:*': 'menu',
\            'bq': 'blockquote',
\            'acr': 'acronym',
\            'fig': 'figure',
\            'ifr': 'iframe',
\            'emb': 'embed',
\            'obj': 'object',
\            'src': 'source',
\            'cap': 'caption',
\            'colg': 'colgroup',
\            'fst': 'fieldset',
\            'btn': 'button',
\            'optg': 'optgroup',
\            'opt': 'option',
\            'tarea': 'textarea',
\            'leg': 'legend',
\            'sect': 'section',
\            'art': 'article',
\            'hdr': 'header',
\            'ftr': 'footer',
\            'adr': 'address',
\            'dlg': 'dialog',
\            'str': 'strong',
\            'sty': 'style',
\            'prog': 'progress',
\            'fset': 'fieldset',
\            'datag': 'datagrid',
\            'datal': 'datalist',
\            'kg': 'keygen',
\            'out': 'output',
\            'det': 'details',
\            'cmd': 'command'
\        },
\        'expandos': {
\            'ol': 'ol>li',
\            'ul': 'ul>li',
\            'dl': 'dl>dt+dd',
\            'map': 'map>area',
\            'table': 'table>tr>td',
\            'colgroup': 'colgroup>col',
\            'colg': 'colgroup>col',
\            'tr': 'tr>td',
\            'select': 'select>option',
\            'optgroup': 'optgroup>option',
\            'optg': 'optgroup>option'
\        },
\        'empty_elements': 'area,base,basefont,br,col,frame,hr,img,input,isindex,link,meta,param,embed,keygen,command',
\        'block_elements': 'address,applet,blockquote,button,center,dd,del,dir,div,dl,dt,fieldset,form,frameset,hr,iframe,ins,isindex,link,map,menu,noframes,noscript,object,ol,p,pre,script,table,tbody,td,tfoot,th,thead,tr,ul,h1,h2,h3,h4,h5,h6,style',
\        'inline_elements': 'a,abbr,acronym,applet,b,basefont,bdo,big,br,button,cite,code,del,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,object,q,s,samp,script,small,span,strike,strong,sub,sup,textarea,tt,u,var',
\    },
\    'xsl': {
\        'extends': 'html',
\        'default_attributes': {
\            'tmatch': [{'match': ''}, {'mode': ''}],
\            'tname': [{'name': ''}],
\            'xsl:when': {'test': ''},
\            'var': [{'name': ''}, {'select': ''}],
\            'vari': {'name': ''},
\            'if': {'test': ''},
\            'call': {'name': ''},
\            'attr': {'name': ''},
\            'wp': [{'name': ''}, {'select': ''}],
\            'par': [{'name': ''}, {'select': ''}],
\            'val': {'select': ''},
\            'co': {'select': ''},
\            'each': {'select': ''},
\            'ap': [{'select': ''}, {'mode': ''}]
\        },
\        'aliases': {
\            'tmatch': 'xsl:template',
\            'tname': 'xsl:template',
\            'var': 'xsl:variable',
\            'vari': 'xsl:variable',
\            'if': 'xsl:if',
\            'choose': 'xsl:choose',
\            'call': 'xsl:call-template',
\            'wp': 'xsl:with-param',
\            'par': 'xsl:param',
\            'val': 'xsl:value-of',
\            'attr': 'xsl:attribute',
\            'co' : 'xsl:copy-of',
\            'each' : 'xsl:for-each',
\            'ap' : 'xsl:apply-templates'
\        },
\        'expandos': {
\            'choose': 'xsl:choose>xsl:when+xsl:otherwise'
\        }
\    },
\    'haml': {
\        'extends': 'html'
\    },
\    'xhtml': {
\        'extends': 'html'
\    },
\    'mustache': {
\        'extends': 'html'
\    },
\    'xsd': {
\        'extends': 'html',
\        'snippets': {
\            'xsd:w3c': "<?xml version=\"1.0\"?>\n"
\                    ."<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n"
\                    ."    <xsd:element name=\"\" type=\"\"/>\n"
\                    ."</xsd:schema>\n"
\        }
\    }
\}

if exists('g:user_zen_settings')
  call s:zen_mergeConfig(s:zen_settings, g:user_zen_settings)
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:

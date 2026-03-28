"=============================================================================
" emmet.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 26-Jul-2015.

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:filtermx = '|\(\%(bem\|html\|blade\|haml\|slim\|e\|c\|s\|fc\|xsl\|t\|\/[^ ]\+\)\s*,\{0,1}\s*\)*$'

function! emmet#getExpandos(type, key) abort
  let l:expandos = emmet#getResource(a:type, 'expandos', {})
  if has_key(l:expandos, a:key)
    return l:expandos[a:key]
  endif
  return a:key
endfunction

function! emmet#splitFilterArg(filters) abort
  for l:f in a:filters
    if l:f =~# '^/'
      return l:f[1:]
    endif
  endfor
  return ''
endfunction

function! emmet#useFilter(filters, filter) abort
  for l:f in a:filters
    if a:filter ==# '/' && l:f =~# '^/'
      return 1
    elseif l:f ==# a:filter
      return 1
    endif
  endfor
  return 0
endfunction

function! emmet#getIndentation(...) abort
  if a:0 > 0
    let l:type = a:1
  else
    let l:type = emmet#getFileType()
  endif
  if has_key(s:emmet_settings, l:type) && has_key(s:emmet_settings[l:type], 'indentation')
    let l:indent = s:emmet_settings[l:type].indentation
  elseif has_key(s:emmet_settings, 'indentation')
    let l:indent = s:emmet_settings.indentation
  elseif has_key(s:emmet_settings.variables, 'indentation')
    let l:indent = s:emmet_settings.variables.indentation
  else
    let l:sw = exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth
    let l:indent = (&l:expandtab || &l:tabstop !=# l:sw) ? repeat(' ', l:sw) : "\t"
  endif
  return l:indent
endfunction

function! emmet#getBaseType(type) abort
  if !has_key(s:emmet_settings, a:type)
    return ''
  endif
  if !has_key(s:emmet_settings[a:type], 'extends')
    return a:type
  endif
  let l:extends = s:emmet_settings[a:type].extends
  if type(l:extends) ==# 1
    let l:tmp = split(l:extends, '\s*,\s*')
    let l:ext = l:tmp[0]
  else
    let l:ext = l:extends[0]
  endif
  if a:type !=# l:ext
    return emmet#getBaseType(l:ext)
  endif
  return ''
endfunction

function! emmet#isExtends(type, extend) abort
  if a:type ==# a:extend
    return 1
  endif
  if !has_key(s:emmet_settings, a:type)
    return 0
  endif
  if !has_key(s:emmet_settings[a:type], 'extends')
    return 0
  endif
  let l:extends = emmet#lang#getExtends(a:type)
  for l:ext in l:extends
    if a:extend ==# l:ext
      return 1
    endif
  endfor
  return 0
endfunction

function! emmet#parseIntoTree(abbr, type) abort
  let l:abbr = a:abbr
  let l:type = a:type
  return emmet#lang#{emmet#lang#type(l:type)}#parseIntoTree(l:abbr, l:type)
endfunction

function! emmet#expandAbbrIntelligent(feedkey) abort
  if !emmet#isExpandable()
    return a:feedkey
  endif
  return "\<plug>(emmet-expand-abbr)"
endfunction

function! emmet#isExpandable() abort
  let l:line = getline('.')
  if col('.') < len(l:line)
    let l:line = matchstr(l:line, '^\(.*\%'.col('.').'c\)')
  endif
  let l:part = matchstr(l:line, '\(\S.*\)$')
  let l:type = emmet#getFileType()
  let l:rtype = emmet#lang#type(l:type)
  let l:part = emmet#lang#{l:rtype}#findTokens(l:part)
  return len(l:part) > 0
endfunction

function! emmet#mergeConfig(lhs, rhs) abort
  let [l:lhs, l:rhs] = [a:lhs, a:rhs]
  if type(l:lhs) ==# 3
    if type(l:rhs) ==# 3
      if len(l:lhs)
        call remove(l:lhs, 0, len(l:lhs)-1)
      endif
      for l:rhi in l:rhs
        call add(l:lhs, l:rhi)
      endfor
    elseif type(l:rhs) ==# 4
      let l:lhs += map(keys(l:rhs), '{v:val : l:rhs[v:val]}')
    endif
  elseif type(l:lhs) ==# 4
    if type(l:rhs) ==# 3
      for l:V in l:rhs
        if type(l:V) != 4
          continue
        endif
        for l:k in keys(l:V)
          let l:lhs[l:k] = l:V[l:k]
        endfor
      endfor
    elseif type(l:rhs) ==# 4
      for l:key in keys(l:rhs)
        if type(l:rhs[l:key]) ==# 3
          if !has_key(l:lhs, l:key)
            let l:lhs[l:key] = []
          endif
          if type(l:lhs[l:key]) == 3
            let l:lhs[l:key] += l:rhs[l:key]
          elseif type(l:lhs[l:key]) == 4
            for l:k in keys(l:rhs[l:key])
              let l:lhs[l:key][l:k] = l:rhs[l:key][l:k]
            endfor
          endif
        elseif type(l:rhs[l:key]) ==# 4
          if has_key(l:lhs, l:key)
            call emmet#mergeConfig(l:lhs[l:key], l:rhs[l:key])
          else
            let l:lhs[l:key] = l:rhs[l:key]
          endif
        else
          let l:lhs[l:key] = l:rhs[l:key]
        endif
      endfor
    endif
  endif
endfunction

function! emmet#newNode() abort
  return { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'basevalue': 0, 'basedirect': 1, 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0, 'attrs_order': ['id', 'class'], 'block': 0, 'empty': 0 }
endfunction

function! s:itemno(itemno, current) abort
  let l:current = a:current
  if l:current.basedirect > 0
    return l:current.basevalue - 1 + a:itemno
  else
    return l:current.multiplier + l:current.basevalue - 2 - a:itemno
  endif
endfunction

function! s:localvar(current, key) abort
  let l:val = ''
  let l:cur = a:current
  while !empty(l:cur)
    if has_key(l:cur, 'variables') && has_key(l:cur.variables, a:key)
      return l:cur.variables[a:key]
    endif
    let l:cur = l:cur.parent
  endwhile
  return ''
endfunction

function! emmet#toString(...) abort
  let l:current = a:1
  if a:0 > 1
    let l:type = a:2
  else
    let l:type = &filetype
  endif
  if len(l:type) ==# 0 | let l:type = 'html' | endif
  if a:0 > 2
    let l:inline = a:3
  else
    let l:inline = 0
  endif
  if a:0 > 3
    if type(a:4) ==# 1
      let l:filters = split(a:4, '\s*,\s*')
    else
      let l:filters = a:4
    endif
  else
    let l:filters = ['html']
  endif
  if a:0 > 4
    let l:group_itemno = a:5
  else
    let l:group_itemno = 0
  endif
  if a:0 > 5
    let l:indent = a:6
  else
    let l:indent = ''
  endif

  let l:dollar_expr = emmet#getResource(l:type, 'dollar_expr', 1)
  let l:itemno = 0
  let l:str = ''
  let l:rtype = emmet#lang#type(l:type)
  while l:itemno < l:current.multiplier
    if len(l:current.name)
      if l:current.multiplier ==# 1
        let l:inner = emmet#lang#{l:rtype}#toString(s:emmet_settings, l:current, l:type, l:inline, l:filters, s:itemno(l:group_itemno, l:current), l:indent)
      else
        let l:inner = emmet#lang#{l:rtype}#toString(s:emmet_settings, l:current, l:type, l:inline, l:filters, s:itemno(l:itemno, l:current), l:indent)
      endif
      if l:current.multiplier > 1
        let l:inner = substitute(l:inner, '\$#', '$line'.(l:itemno+1).'$', 'g')
      endif
      let l:str .= l:inner
    else
      let l:snippet = l:current.snippet
      if len(l:snippet) ==# 0
        let l:snippets = emmet#getResource(l:type, 'snippets', {})
        if !empty(l:snippets) && has_key(l:snippets, 'emmet_snippet')
          let l:snippet = l:snippets['emmet_snippet']
        endif
      endif
      if len(l:snippet) > 0
        let l:tmp = l:snippet
        let l:tmp = substitute(l:tmp, '\${emmet_name}', l:current.name, 'g')
        let l:snippet_node = emmet#newNode()
        let l:snippet_node.value = '{'.l:tmp.'}'
        let l:snippet_node.important = l:current.important
        let l:snippet_node.multiplier = l:current.multiplier
        let l:str .= emmet#lang#{l:rtype}#toString(s:emmet_settings, l:snippet_node, l:type, l:inline, l:filters, s:itemno(l:group_itemno, l:current), l:indent)
        if l:current.multiplier > 1
          let l:str .= "\n"
        endif
      else
        if len(l:current.name)
          let l:str .= l:current.name
        endif
        if len(l:current.value)
          let l:text = l:current.value[1:-2]
          if l:dollar_expr
            " TODO: regexp engine specified
            if exists('&regexpengine')
              let l:text = substitute(l:text, '\%#=1\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", max([l:itemno, l:group_itemno])+1).submatch(2)', 'g')
            else
              let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", max([l:itemno, l:group_itemno])+1).submatch(2)', 'g')
            endif
            let l:text = substitute(l:text, '\${nr}', "\n", 'g')
            let l:text = substitute(l:text, '\\\$', '$', 'g')
          endif
          let l:str .= l:text
        endif
      endif
      let l:inner = ''
      if len(l:current.child)
        for l:n in l:current.child
          let l:inner .= emmet#toString(l:n, l:type, l:inline, l:filters, s:itemno(l:group_itemno, l:n), l:indent)
        endfor
      else
        let l:inner = l:current.value[1:-2]
      endif
      let l:inner = substitute(l:inner, "\n", "\n" . l:indent, 'g')
      let l:str = substitute(l:str, '\${:\(\w\+\)}', '\=s:localvar(l:current, submatch(1))', '')
      let l:str = substitute(l:str, '\${child}', l:inner, '')
    endif
    let l:itemno = l:itemno + 1
  endwhile
  return l:str
endfunction

function! emmet#getSettings() abort
  return s:emmet_settings
endfunction

function! emmet#getFilters(type) abort
  let l:filterstr = emmet#getResource(a:type, 'filters', '')
  return split(l:filterstr, '\s*,\s*')
endfunction

function! emmet#getResource(type, name, default) abort
  if exists('b:emmet_' . a:name)
    return get(b:, 'emmet_' . a:name)
  endif
  let l:global = {}
  if has_key(s:emmet_settings, '*') && has_key(s:emmet_settings['*'], a:name)
    let l:global = extend(l:global, s:emmet_settings['*'][a:name])
  endif

  if has_key(s:emmet_settings, a:type)
    let l:types = [a:type]
  else
    let l:types = split(a:type, '\.')
  endif

  for l:type in l:types
    if !has_key(s:emmet_settings, l:type)
      continue
    endif
    let l:ret = a:default

    if has_key(s:emmet_settings[l:type], 'extends')
      let l:extends = emmet#lang#getExtends(a:type)
      call reverse(l:extends) " reverse to overwrite the correct way
      for l:ext in l:extends
        if !has_key(s:emmet_settings, l:ext)
          continue
        endif

        if has_key(s:emmet_settings[l:ext], a:name)
          if type(l:ret) ==# 3 || type(l:ret) ==# 4
            call emmet#mergeConfig(l:ret, s:emmet_settings[l:ext][a:name])
          else
            let l:ret = s:emmet_settings[l:ext][a:name]
          endif
        endif
      endfor
    endif

    if has_key(s:emmet_settings[l:type], a:name)
      if type(l:ret) ==# 3 || type(l:ret) ==# 4
        call emmet#mergeConfig(l:ret, s:emmet_settings[l:type][a:name])
        return extend(l:global, l:ret)
      else
        return s:emmet_settings[l:type][a:name]
      endif
    endif
    if !empty(l:ret)
      if type(l:ret) ==# 3 || type(l:ret) ==# 4
        let l:ret = extend(l:global, l:ret)
      endif
      return l:ret
    endif
  endfor

  let l:ret = a:default
  if type(l:ret) ==# 3 || type(l:ret) ==# 4
    let l:ret = extend(l:global, l:ret)
  endif
  return l:ret
endfunction

function! emmet#getFileType(...) abort
  let l:flg = get(a:000, 0, 0)

  if has_key(s:emmet_settings, &filetype)
    let l:type = &filetype
    if emmet#getResource(l:type, 'ignore_embeded_filetype', 0)
      return l:type
    endif
  endif

  if get(g:, 'loaded_nvim_treesitter', 0)
    let l:type = luaeval('require"emmet_utils".get_node_at_cursor()')
  else
    let l:pos = emmet#util#getcurpos()
    let l:type = synIDattr(synID(max([l:pos[1], 1]), max([l:pos[2], 1]), 1), 'name')
  endif

  " ignore htmlTagName as it seems to occur too often
  if l:type == 'htmlTagName'
    let l:type = ''
  endif
  if l:type =~ '^mkdSnippet'
    let l:type = tolower(l:type[10:])
  endif

  if l:type =~? '^css'
    let l:type = 'css'
  elseif l:type =~? '^html'
    let l:type = 'html'
  elseif l:type =~? '^jsx'
    let l:type = 'jsx'
  elseif (l:type =~? '^js\w' || l:type =~? '^javascript') && !(&filetype =~? 'jsx')
    let l:type = 'javascript'
  elseif l:type =~? '^tsx'
    let l:type = 'tsx'
  elseif l:type =~? '^ts\w' || l:type =~? '^typescript'
    let l:type = 'typescript'
  elseif l:type =~? '^xml'
    let l:type = 'xml'
  elseif l:type == 'styledEmmetAbbreviation'
    let l:type = 'styled'
  else
    let l:types = split(&filetype, '\.')
    for l:part in l:types
      if has_key(s:emmet_settings, l:part)
        let l:type = l:part
        break
      endif
      let l:base = emmet#getBaseType(l:part)
      if l:base !=# ''
        if l:flg
          let l:type = &filetype
        else
          let l:type = l:base
        endif
        unlet l:base
        break
      endif
    endfor
  endif

  return empty(l:type) ? 'html' : l:type
endfunction

function! emmet#getDollarExprs(expand) abort
  let l:expand = a:expand
  let l:dollar_list = []
  let l:dollar_reg = '\%(\\\)\@<!\${\(\([^{}]\|\%(\\\)\@\<=[{}]\)\{}\)}'
  while 1
    let l:matcharr = matchlist(l:expand, l:dollar_reg)
    if len(l:matcharr) > 0
      let l:key = get(l:matcharr, 1)
      if l:key !~# '^\d\+:'
        let l:key = substitute(l:key, '\\{', '{', 'g')
        let l:key = substitute(l:key, '\\}', '}', 'g')
        let l:value = emmet#getDollarValueByKey(l:key)
        if type(l:value) ==# type('')
          let l:expr = get(l:matcharr, 0)
          call add(l:dollar_list, {'expr': l:expr, 'value': l:value})
        endif
      endif
    else
      break
    endif
    let l:expand = substitute(l:expand, l:dollar_reg, '', '')
  endwhile
  return l:dollar_list
endfunction

function! emmet#getDollarValueByKey(key) abort
  let l:ret = 0
  let l:key = a:key
  let l:ftsetting = get(s:emmet_settings, emmet#getFileType())
  if type(l:ftsetting) ==# 4 && has_key(l:ftsetting, l:key)
    let l:V = get(l:ftsetting, l:key)
    if type(l:V) ==# 1 | return l:V | endif
  endif
  if type(l:ret) !=# 1 && has_key(s:emmet_settings.variables, l:key)
    let l:V = get(s:emmet_settings.variables, l:key)
    if type(l:V) ==# 1 | return l:V | endif
  endif
  if has_key(s:emmet_settings, 'custom_expands') && type(s:emmet_settings['custom_expands']) ==# 4
    for l:k in keys(s:emmet_settings['custom_expands'])
      if l:key =~# l:k
        let l:V = get(s:emmet_settings['custom_expands'], l:k)
        if type(l:V) ==# 1 | return l:V | endif
        if type(l:V) ==# 2 | return l:V(l:key) | endif
      endif
    endfor
  endif
  return l:ret
endfunction

function! emmet#reExpandDollarExpr(expand, times) abort
  let l:expand = a:expand
  let l:dollar_exprs = emmet#getDollarExprs(l:expand)
  if len(l:dollar_exprs) > 0
    if a:times < 9
      for l:n in range(len(l:dollar_exprs))
        let l:pair = get(l:dollar_exprs, l:n)
        let l:pat = get(l:pair, 'expr')
        let l:sub = get(l:pair, 'value')
        let l:expand = substitute(l:expand, l:pat, l:sub, '')
      endfor
      return emmet#reExpandDollarExpr(l:expand, a:times + 1)
    endif
  endif
  return l:expand
endfunction

function! emmet#expandDollarExpr(expand) abort
  return emmet#reExpandDollarExpr(a:expand, 0)
endfunction

function! emmet#expandCursorExpr(expand, mode) abort
  let l:expand = a:expand
  if l:expand !~# '\${cursor}'
    if a:mode ==# 2
      let l:expand = '${cursor}' . l:expand
    else
      let l:expand .= '${cursor}'
    endif
  endif
  let l:expand = substitute(l:expand, '\${\d\+:\?\([^}]\+\)}', '$select$$cursor$\1$select$', 'g')
  let l:expand = substitute(l:expand, '\${\d\+}', '$select$$cursor$$select$', 'g')
  let l:expand = substitute(l:expand, '\${cursor}', '$cursor$', '')
  let l:expand = substitute(l:expand, '\${cursor}', '', 'g')
  let l:expand = substitute(l:expand, '\${cursor}', '', 'g')
  return l:expand
endfunction

function! emmet#unescapeDollarExpr(expand) abort
  return substitute(a:expand, '\\\$', '$', 'g')
endfunction

function! s:expandItems(items, type, filters, indent) abort
  let l:expand = ''
  for l:item in a:items
    let l:expand .= emmet#toString(l:item, a:type, 0, a:filters, 0, a:indent)
  endfor
  return l:expand
endfunction

function! s:applyEscapeFilter(filters, expand) abort
  let l:expand = a:expand
  if emmet#useFilter(a:filters, 'e')
    let l:expand = substitute(l:expand, '&', '\&amp;', 'g')
    let l:expand = substitute(l:expand, '<', '\&lt;', 'g')
    let l:expand = substitute(l:expand, '>', '\&gt;', 'g')
  endif
  return l:expand
endfunction

function! emmet#expandAbbr(mode, abbr) range abort
  let l:type = emmet#getFileType(1)
  let l:indent = emmet#getIndentation(l:type)
  let l:expand = ''
  let l:line = ''
  let l:part = ''
  let l:rest = ''

  let l:filters = emmet#getFilters(l:type)
  if len(l:filters) ==# 0
    let l:filters = ['html']
  endif

  if a:mode ==# 2
    let l:leader = substitute(input('Tag: ', ''), '^\s*\(.*\)\s*$', '\1', 'g')
    if len(l:leader) ==# 0
      return ''
    endif
    if l:leader =~# s:filtermx
      let l:filters = map(split(matchstr(l:leader, s:filtermx)[1:], '\s*[^\\]\zs,\s*'), 'substitute(v:val, "\\\\\\\\zs.\\\\ze", "&", "g")')
      let l:leader = substitute(l:leader, s:filtermx, '', '')
    endif
    if l:leader =~# '\*'
      let l:query = substitute(l:leader, '*', '*' . (a:lastline - a:firstline + 1), '')
      if l:query !~# '}\s*$' && l:query !~# '\$#'
        let l:query .= '>{$#}'
      endif
      if emmet#useFilter(l:filters, '/')
        let l:spl = emmet#splitFilterArg(l:filters)
        let l:fline = getline(a:firstline)
        let l:query = substitute(l:query, '>\{0,1}{\$#}\s*$', '{\\$column\\$}*' . len(split(l:fline, l:spl)), '')
      else
        let l:spl = ''
      endif
      let l:items = emmet#parseIntoTree(l:query, l:type).child
      let l:itemno = 0
      for l:item in l:items
        let l:inner = emmet#toString(l:item, l:type, 0, l:filters, 0, l:indent)
        let l:inner = substitute(l:inner, '\$#', '$line'.(l:itemno*(a:lastline - a:firstline + 1)/len(l:items)+1).'$', 'g')
        let l:expand .= l:inner
        let l:itemno = l:itemno + 1
      endfor
      let l:expand = s:applyEscapeFilter(l:filters, l:expand)
      let l:line = getline(a:firstline)
      let l:part = substitute(l:line, '^\s*', '', '')
      for l:n in range(a:firstline, a:lastline)
        let l:lline = getline(l:n)
        let l:lpart = substitute(l:lline, '^\s\+', '', '')
        if emmet#useFilter(l:filters, 't')
          let l:lpart = substitute(l:lpart, '^[0-9.-]\+\s\+', '', '')
          let l:lpart = substitute(l:lpart, '\s\+$', '', '')
        endif
        if emmet#useFilter(l:filters, '/')
          for l:column in split(l:lpart, l:spl)
            let l:expand = substitute(l:expand, '\$column\$', '\=l:column', '')
          endfor
        else
          let l:expand = substitute(l:expand, '\$line'.(l:n-a:firstline+1).'\$', '\=l:lpart', 'g')
        endif
      endfor
      let l:expand = substitute(l:expand, '\$line\d*\$', '', 'g')
      let l:expand = substitute(l:expand, '\$column\$', '', 'g')
      let l:content = join(getline(a:firstline, a:lastline), "\n")
      if stridx(l:expand, '$#') < len(l:expand)-2
        let l:expand = substitute(l:expand, '^\(.*\)\$#\s*$', '\1', '')
      endif
      let l:expand = substitute(l:expand, '\$#', '\=l:content', 'g')
    else
      let l:str = ''
      if visualmode() ==# 'V'
        let l:line = getline(a:firstline)
        let l:lspaces = matchstr(l:line, '^\s*', '', '')
        let l:part = substitute(l:line, '^\s*', '', '')
        for l:n in range(a:firstline, a:lastline)
          if len(l:leader) > 0
            let l:line = getline(a:firstline)
            let l:spaces = matchstr(l:line, '^\s*', '', '')
            if len(l:spaces) >= len(l:lspaces)
              let l:str .= l:indent . getline(l:n)[len(l:lspaces):] . "\n"
            else
              let l:str .= getline(l:n) . "\n"
            endif
          else
            let l:lpart = substitute(getline(l:n), '^\s*', '', '')
            let l:str .= l:lpart . "\n"
          endif
        endfor
        if stridx(l:leader, '{$#}') ==# -1
          let l:leader .= '{$#}'
        endif
        let l:items = emmet#parseIntoTree(l:leader, l:type).child
      else
        let l:save_regcont = @"
        let l:save_regtype = getregtype('"')
        silent! normal! gvygv
        let l:str = @"
        call setreg('"', l:save_regcont, l:save_regtype)
        if stridx(l:leader, '{$#}') ==# -1
          let l:leader .= '{$#}'
        endif
        let l:items = emmet#parseIntoTree(l:leader, l:type).child
      endif
      let l:expand = s:applyEscapeFilter(l:filters, s:expandItems(l:items, l:type, l:filters, ''))
      if stridx(l:leader, '{$#}') !=# -1
        let l:expand = substitute(l:expand, '\$#', '\="\n" . l:str', 'g')
      endif
    endif
  elseif a:mode ==# 4
    let l:line = getline('.')
    let l:spaces = matchstr(l:line, '^\s*')
    if l:line !~# '^\s*$'
      put =l:spaces.a:abbr
    else
      call setline('.', l:spaces.a:abbr)
    endif
    normal! $
    call emmet#expandAbbr(0, '')
    return ''
  else
    let l:line = getline('.')
    if col('.') < len(l:line)
      let l:line = matchstr(l:line, '^\(.*\%'.col('.').'c\)')
    endif
    if a:mode ==# 1
      let l:part = matchstr(l:line, '\([a-zA-Z0-9:_\-\@|]\+\)$')
    else
      let l:part = matchstr(l:line, '\(\S.*\)$')
      let l:rtype = emmet#lang#type(l:type)
      let l:part = emmet#lang#{l:rtype}#findTokens(l:part)
      let l:line = l:line[0: strridx(l:line, l:part) + len(l:part) - 1]
    endif
    if col('.') ==# col('$')
      let l:rest = ''
    else
      let l:rest = getline('.')[len(l:line):]
    endif
    let l:str = l:part
    if l:str =~# s:filtermx
      let l:filters = split(matchstr(l:str, s:filtermx)[1:], '\s*,\s*')
      let l:str = substitute(l:str, s:filtermx, '', '')
    endif
    let l:items = emmet#parseIntoTree(l:str, l:type).child
    let l:expand = s:applyEscapeFilter(l:filters, s:expandItems(l:items, l:type, l:filters, l:indent))
    let l:expand = substitute(l:expand, '\$line\([0-9]\+\)\$', '\=submatch(1)', 'g')
  endif
  let l:expand = emmet#expandDollarExpr(l:expand)
  let l:expand = emmet#expandCursorExpr(l:expand, a:mode)
  if len(l:expand)
    if has_key(s:emmet_settings, 'timezone') && len(s:emmet_settings.timezone)
      let l:expand = substitute(l:expand, '${datetime}', strftime('%Y-%m-%dT%H:%M:%S') . s:emmet_settings.timezone, 'g')
    else
      " TODO: on windows, %z/%Z is 'Tokyo(Standard)'
      let l:expand = substitute(l:expand, '${datetime}', strftime('%Y-%m-%dT%H:%M:%S %z'), 'g')
    endif
    let l:expand = emmet#unescapeDollarExpr(l:expand)
    if a:mode ==# 2 && visualmode() ==# 'v'
      if a:firstline ==# a:lastline
        let l:expand = substitute(l:expand, '[\r\n]\s*', '', 'g')
      else
        let l:expand = substitute(l:expand, '[\n]$', '', 'g')
      endif
      silent! normal! gv
      let l:col = col('''<')
      silent! normal! c
      let l:line = getline('.')
      let l:lhs = matchstr(l:line, '.*\%<'.l:col.'c.')
      let l:rhs = matchstr(l:line, '\%>'.(l:col-1).'c.*')
      let l:expand = l:lhs.l:expand.l:rhs
      let l:lines = split(l:expand, '\n')
      call setline(line('.'), l:lines[0])
      if len(l:lines) > 1
        call append(line('.'), l:lines[1:])
      endif
    else
      if l:line[:-len(l:part)-1] =~# '^\s\+$'
        let l:indent = l:line[:-len(l:part)-1]
      else
        let l:indent = ''
      endif
      let l:expand = substitute(l:expand, '[\r\n]\s*$', '', 'g')
      if emmet#useFilter(l:filters, 's')
        let l:epart = substitute(l:expand, '[\r\n]\s*', '', 'g')
      else
        let l:epart = substitute(l:expand, '[\r\n]', "\n" . l:indent, 'g')
      endif
      let l:expand = l:line[:-len(l:part)-1] . l:epart . l:rest
      let l:lines = split(l:expand, '[\r\n]', 1)
      if a:mode ==# 2
        silent! exe 'normal! gvc'
      endif
      call setline('.', l:lines[0])
      if len(l:lines) > 1
        call append('.', l:lines[1:])
      endif
    endif
  endif
  if g:emmet_debug > 1
    call getchar()
  endif
  if search('\ze\$\(cursor\|select\)\$', 'c')
    let l:oldselection = &selection
    let &selection = 'inclusive'
    if foldclosed(line('.')) !=# -1
      silent! foldopen
    endif
    let l:pos = emmet#util#getcurpos()
    let l:use_selection = emmet#getResource(l:type, 'use_selection', 0)
    try
      let l:gdefault = &gdefault
      let &gdefault = 0
      if l:use_selection && getline('.')[col('.')-1:] =~# '^\$select'
        let l:pos[2] += 1
        silent! s/\$select\$//
        let l:next = searchpos('.\ze\$select\$', 'nW')
        silent! %s/\$\(cursor\|select\)\$//g
        call emmet#util#selectRegion([l:pos[1:2], l:next])
        return "\<esc>gv"
      else
        silent! %s/\$\(cursor\|select\)\$//g
        silent! call setpos('.', l:pos)
        if col('.') < col('$')
          return "\<right>"
        endif
      endif
    finally
      let &gdefault = l:gdefault
    endtry
    let &selection = l:oldselection
  endif
  return ''
endfunction

function! emmet#updateTag() abort
  let l:type = emmet#getFileType()
  let l:region = emmet#util#searchRegion('<\S', '>')
  if !emmet#util#regionIsValid(l:region) || !emmet#util#cursorInRegion(l:region)
    return ''
  endif
  let l:content = emmet#util#getContent(l:region)
  let l:content = matchstr(l:content,  '^<[^><]\+>')
  if l:content !~# '^<[^><]\+>$'
    return ''
  endif
  let l:current = emmet#lang#html#parseTag(l:content)
  if empty(l:current)
    return ''
  endif
  let l:old_tag_name = l:current.name

  let l:str = substitute(input('Enter Abbreviation: ', ''), '^\s*\(.*\)\s*$', '\1', 'g')
  let l:tag_changed = l:str =~# '^\s*\w'
  let l:item = emmet#parseIntoTree(l:str, l:type).child[0]
  for l:k in keys(l:item.attr)
    let l:current.attr[l:k] = l:item.attr[l:k]
  endfor
  if l:tag_changed
    let l:current.name = l:item.name
  endif
  let l:html = substitute(emmet#toString(l:current, 'html', 1), '\n', '', '')
  let l:html = substitute(l:html, '\${cursor}', '', '')
  let l:html = matchstr(l:html,  '^<[^><]\+>')
  if l:tag_changed
    let l:pos2 = searchpairpos('<' . l:old_tag_name . '\>[^>]*>', '', '</' . l:old_tag_name . '>', 'W')
    if l:pos2 != [0, 0]
      let l:html .= emmet#util#getContent([l:region[1], l:pos2])[1:-2]
      let l:html .= '</' . l:current.name . '>'
      let l:region = [l:region[0], [l:pos2[0], l:pos2[1] + len(l:old_tag_name) + 3]]
    endif
  endif
  call emmet#util#setContent(l:region, l:html)
  return ''
endfunction

function! emmet#moveNextPrevItem(flag) abort
  let l:type = emmet#getFileType()
  return emmet#lang#{emmet#lang#type(l:type)}#moveNextPrevItem(a:flag)
endfunction

function! emmet#moveNextPrev(flag) abort
  let l:type = emmet#getFileType()
  return emmet#lang#{emmet#lang#type(l:type)}#moveNextPrev(a:flag)
endfunction

function! emmet#imageSize() abort
  let l:orgpos = emmet#util#getcurpos()
  let l:type = emmet#getFileType()
  call emmet#lang#{emmet#lang#type(l:type)}#imageSize()
  silent! call setpos('.', l:orgpos)
  return ''
endfunction

function! emmet#imageEncode() abort
  let l:type = emmet#getFileType()
  return emmet#lang#{emmet#lang#type(l:type)}#imageEncode()
endfunction

function! emmet#toggleComment() abort
  let l:type = emmet#getFileType()
  call emmet#lang#{emmet#lang#type(l:type)}#toggleComment()
  return ''
endfunction

function! emmet#balanceTag(flag) range abort
  let l:type = emmet#getFileType()
  return emmet#lang#{emmet#lang#type(l:type)}#balanceTag(a:flag)
endfunction

function! emmet#splitJoinTag() abort
  let l:type = emmet#getFileType()
  return emmet#lang#{emmet#lang#type(l:type)}#splitJoinTag()
endfunction

function! emmet#mergeLines() range abort
  let l:type = emmet#getFileType()
  call emmet#lang#{emmet#lang#type(l:type)}#mergeLines()
  return ''
endfunction

function! emmet#removeTag() abort
  let l:type = emmet#getFileType()
  call emmet#lang#{emmet#lang#type(l:type)}#removeTag()
  return ''
endfunction

function! emmet#anchorizeURL(flag) abort
  let l:mx = 'https\=:\/\/[-!#$%&*+,./:;=?@0-9a-zA-Z_~]\+'
  let l:pos1 = searchpos(l:mx, 'bcnW')
  let l:url = matchstr(getline(l:pos1[0])[l:pos1[1]-1:], l:mx)
  let l:block = [l:pos1, [l:pos1[0], l:pos1[1] + len(l:url) - 1]]
  if !emmet#util#cursorInRegion(l:block)
    return ''
  endif

  let l:mx = '.*<title[^>]*>\s*\zs\([^<]\+\)\ze\s*<\/title[^>]*>.*'
  let l:content = emmet#util#getContentFromURL(l:url)
  let l:content = substitute(l:content, '\r', '', 'g')
  let l:content = substitute(l:content, '[ \n]\+', ' ', 'g')
  let l:content = substitute(l:content, '<!--.\{-}-->', '', 'g')
  let l:title = matchstr(l:content, l:mx)

  let l:type = emmet#getFileType()
  let l:rtype = emmet#lang#type(l:type)
  if &filetype ==# 'markdown'
    let l:expand = printf('[%s](%s)', substitute(l:title, '[\[\]]', '\\&', 'g'), l:url)
  elseif &filetype ==# 'rst'
    let l:expand = printf('`%s <%s>`_', substitute(l:title, '[\[\]]', '\\&', 'g'), l:url)
  elseif a:flag ==# 0
    let l:a = emmet#lang#html#parseTag('<a>')
    let l:a.attr.href = l:url
    let l:a.value = '{' . l:title . '}'
    let l:expand = emmet#toString(l:a, l:rtype, 0, [])
    let l:expand = substitute(l:expand, '\${cursor}', '', 'g')
  else
    let l:body = emmet#util#getTextFromHTML(l:content)
    let l:body = '{' . substitute(l:body, '^\(.\{0,100}\).*', '\1', '') . '...}'

    let l:blockquote = emmet#lang#html#parseTag('<blockquote class="quote">')
    let l:a = emmet#lang#html#parseTag('<a>')
    let l:a.attr.href = l:url
    let l:a.value = '{' . l:title . '}'
    call add(l:blockquote.child, l:a)
    call add(l:blockquote.child, emmet#lang#html#parseTag('<br/>'))
    let l:p = emmet#lang#html#parseTag('<p>')
    let l:p.value = l:body
    call add(l:blockquote.child, l:p)
    let l:cite = emmet#lang#html#parseTag('<cite>')
    let l:cite.value = '{' . l:url . '}'
    call add(l:blockquote.child, l:cite)
    let l:expand = emmet#toString(l:blockquote, l:rtype, 0, [])
    let l:expand = substitute(l:expand, '\${cursor}', '', 'g')
  endif
  let l:indent = substitute(getline('.'), '^\(\s*\).*', '\1', '')
  let l:expand = substitute(l:expand, "\n", "\n" . l:indent, 'g')
  call emmet#util#setContent(l:block, l:expand)
  return ''
endfunction

function! emmet#codePretty() range abort
  let l:type = input('FileType: ', &filetype, 'filetype')
  if len(l:type) ==# 0
    return
  endif
  let l:block = emmet#util#getVisualBlock()
  let l:content = emmet#util#getContent(l:block)
  silent! 1new
  let &l:filetype = l:type
  call setline(1, split(l:content, "\n"))
  let l:old_lazyredraw = &lazyredraw
  set lazyredraw
  silent! TOhtml
  let &lazyredraw = l:old_lazyredraw
  let l:content = join(getline(1, '$'), "\n")
  silent! bw!
  silent! bw!
  let l:content = matchstr(l:content, '<body[^>]*>[\s\n]*\zs.*\ze</body>')
  call emmet#util#setContent(l:block, l:content)
endfunction

function! emmet#expandWord(abbr, type, orig) abort
  let l:str = a:abbr
  let l:type = a:type
  let l:indent = emmet#getIndentation(l:type)

  if len(l:type) ==# 0 | let l:type = 'html' | endif
  if l:str =~# s:filtermx
    let l:filters = split(matchstr(l:str, s:filtermx)[1:], '\s*,\s*')
    let l:str = substitute(l:str, s:filtermx, '', '')
  else
    let l:filters = emmet#getFilters(a:type)
    if len(l:filters) ==# 0
      let l:filters = ['html']
    endif
  endif
  let l:str = substitute(l:str, '|', '${cursor}', 'g')
  let l:items = emmet#parseIntoTree(l:str, a:type).child
  let l:expand = s:applyEscapeFilter(l:filters, s:expandItems(l:items, a:type, l:filters, l:indent))
  if emmet#useFilter(l:filters, 's')
    let l:expand = substitute(l:expand, "\n\s\*", '', 'g')
  endif
  if a:orig ==# 0
    let l:expand = emmet#expandDollarExpr(l:expand)
    let l:expand = substitute(l:expand, '\${cursor}', '', 'g')
  endif
  return l:expand
endfunction

function! emmet#getSnippets(type) abort
  let l:type = a:type
  if len(l:type) ==# 0 || !has_key(s:emmet_settings, l:type)
    let l:type = 'html'
  endif
  return emmet#getResource(l:type, 'snippets', {})
endfunction

function! emmet#completeTag(findstart, base) abort
  if a:findstart
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start > 0 && l:line[l:start - 1] =~# '[a-zA-Z0-9:_\@\-]'
      let l:start -= 1
    endwhile
    return l:start
  else
    let l:type = emmet#getFileType()
    let l:res = []

    let l:snippets = emmet#getResource(l:type, 'snippets', {})
    for l:item in keys(l:snippets)
      if stridx(l:item, a:base) !=# -1
        call add(l:res, substitute(l:item, '\${cursor}\||', '', 'g'))
      endif
    endfor
    let l:aliases = emmet#getResource(l:type, 'aliases', {})
    for l:item in values(l:aliases)
      if stridx(l:item, a:base) !=# -1
        call add(l:res, substitute(l:item, '\${cursor}\||', '', 'g'))
      endif
    endfor
    return l:res
  endif
endfunction

unlet! s:emmet_settings
let s:emmet_settings = {
\    'variables': {
\      'lang': "en",
\      'locale': "en-US",
\      'charset': "UTF-8",
\      'newline': "\n",
\      'use_selection': 0,
\    },
\    'custom_expands' : {
\      '^\%(lorem\|lipsum\)\(\d*\)$' : function('emmet#lorem#en#expand'),
\    },
\    'css': {
\        'snippets': {
\           "@i": "@import url(|);",
\           "@import": "@import url(|);",
\           "@m": "@media ${1:screen} {\n\t|\n}",
\           "@media": "@media ${1:screen} {\n\t|\n}",
\           "@f": "@font-face {\n\tfont-family:|;\n\tsrc:url(|);\n}",
\           "@f+": "@font-face {\n\tfont-family: '${1:FontName}';\n\tsrc: url('${2:FileName}.eot');\n\tsrc: url('${2:FileName}.eot?#iefix') format('embedded-opentype'),\n\t\t url('${2:FileName}.woff') format('woff'),\n\t\t url('${2:FileName}.ttf') format('truetype'),\n\t\t url('${2:FileName}.svg#${1:FontName}') format('svg');\n\tfont-style: ${3:normal};\n\tfont-weight: ${4:normal};\n}",
\           "@kf": "@-webkit-keyframes ${1:identifier} {\n\t${2:from} { ${3} }${6}\n\t${4:to} { ${5} }\n}\n@-o-keyframes ${1:identifier} {\n\t${2:from} { ${3} }${6}\n\t${4:to} { ${5} }\n}\n@-moz-keyframes ${1:identifier} {\n\t${2:from} { ${3} }${6}\n\t${4:to} { ${5} }\n}\n@keyframes ${1:identifier} {\n\t${2:from} { ${3} }${6}\n\t${4:to} { ${5} }\n}",
\           "anim": "animation:|;",
\           "anim-": "animation:${1:name} ${2:duration} ${3:timing-function} ${4:delay} ${5:iteration-count} ${6:direction} ${7:fill-mode};",
\           "animdel": "animation-delay:${1:time};",
\           "animdir": "animation-direction:${1:normal};",
\           "animdir:n": "animation-direction:normal;",
\           "animdir:r": "animation-direction:reverse;",
\           "animdir:a": "animation-direction:alternate;",
\           "animdir:ar": "animation-direction:alternate-reverse;",
\           "animdur": "animation-duration:${1:0}s;",
\           "animfm": "animation-fill-mode:${1:both};",
\           "animfm:f": "animation-fill-mode:forwards;",
\           "animfm:b": "animation-fill-mode:backwards;",
\           "animfm:bt": "animation-fill-mode:both;",
\           "animfm:bh": "animation-fill-mode:both;",
\           "animic": "animation-iteration-count:${1:1};",
\           "animic:i": "animation-iteration-count:infinite;",
\           "animn": "animation-name:${1:none};",
\           "animps": "animation-play-state:${1:running};",
\           "animps:p": "animation-play-state:paused;",
\           "animps:r": "animation-play-state:running;",
\           "animtf": "animation-timing-function:${1:linear};",
\           "animtf:e": "animation-timing-function:ease;",
\           "animtf:ei": "animation-timing-function:ease-in;",
\           "animtf:eo": "animation-timing-function:ease-out;",
\           "animtf:eio": "animation-timing-function:ease-in-out;",
\           "animtf:l": "animation-timing-function:linear;",
\           "animtf:cb": "animation-timing-function:cubic-bezier(${1:0.1}, ${2:0.7}, ${3:1.0}, ${3:0.1});",
\           "ap": "appearance:${none};",
\           "!": "!important",
\           "pos": "position:${1:relative};",
\           "pos:s": "position:static;",
\           "pos:a": "position:absolute;",
\           "pos:r": "position:relative;",
\           "pos:f": "position:fixed;",
\           "t": "top:|;",
\           "t:a": "top:auto;",
\           "r": "right:|;",
\           "r:a": "right:auto;",
\           "b": "bottom:|;",
\           "b:a": "bottom:auto;",
\           "l": "left:|;",
\           "l:a": "left:auto;",
\           "z": "z-index:|;",
\           "z:a": "z-index:auto;",
\           "fl": "float:${1:left};",
\           "fl:n": "float:none;",
\           "fl:l": "float:left;",
\           "fl:r": "float:right;",
\           "cl": "clear:${1:both};",
\           "cl:n": "clear:none;",
\           "cl:l": "clear:left;",
\           "cl:r": "clear:right;",
\           "cl:b": "clear:both;",
\           "colm": "columns:|;",
\           "colmc": "column-count:|;",
\           "colmf": "column-fill:|;",
\           "colmg": "column-gap:|;",
\           "colmr": "column-rule:|;",
\           "colmrc": "column-rule-color:|;",
\           "colmrs": "column-rule-style:|;",
\           "colmrw": "column-rule-width:|;",
\           "colms": "column-span:|;",
\           "colmw": "column-width:|;",
\           "d": "display:${1:block};",
\           "d:n": "display:none;",
\           "d:b": "display:block;",
\           "d:f": "display:flex;",
\           "d:if": "display:inline-flex;",
\           "d:i": "display:inline;",
\           "d:ib": "display:inline-block;",
\           "d:ib+": "display: inline-block;\n*display: inline;\n*zoom: 1;",
\           "d:li": "display:list-item;",
\           "d:ri": "display:run-in;",
\           "d:cp": "display:compact;",
\           "d:tb": "display:table;",
\           "d:itb": "display:inline-table;",
\           "d:tbcp": "display:table-caption;",
\           "d:tbcl": "display:table-column;",
\           "d:tbclg": "display:table-column-group;",
\           "d:tbhg": "display:table-header-group;",
\           "d:tbfg": "display:table-footer-group;",
\           "d:tbr": "display:table-row;",
\           "d:tbrg": "display:table-row-group;",
\           "d:tbc": "display:table-cell;",
\           "d:rb": "display:ruby;",
\           "d:rbb": "display:ruby-base;",
\           "d:rbbg": "display:ruby-base-group;",
\           "d:rbt": "display:ruby-text;",
\           "d:rbtg": "display:ruby-text-group;",
\           "v": "visibility:${1:hidden};",
\           "v:v": "visibility:visible;",
\           "v:h": "visibility:hidden;",
\           "v:c": "visibility:collapse;",
\           "ov": "overflow:${1:hidden};",
\           "ov:v": "overflow:visible;",
\           "ov:h": "overflow:hidden;",
\           "ov:s": "overflow:scroll;",
\           "ov:a": "overflow:auto;",
\           "ovx": "overflow-x:${1:hidden};",
\           "ovx:v": "overflow-x:visible;",
\           "ovx:h": "overflow-x:hidden;",
\           "ovx:s": "overflow-x:scroll;",
\           "ovx:a": "overflow-x:auto;",
\           "ovy": "overflow-y:${1:hidden};",
\           "ovy:v": "overflow-y:visible;",
\           "ovy:h": "overflow-y:hidden;",
\           "ovy:s": "overflow-y:scroll;",
\           "ovy:a": "overflow-y:auto;",
\           "ovs": "overflow-style:${1:scrollbar};",
\           "ovs:a": "overflow-style:auto;",
\           "ovs:s": "overflow-style:scrollbar;",
\           "ovs:p": "overflow-style:panner;",
\           "ovs:m": "overflow-style:move;",
\           "ovs:mq": "overflow-style:marquee;",
\           "zoo": "zoom:1;",
\           "zm": "zoom:1;",
\           "cp": "clip:|;",
\           "cp:a": "clip:auto;",
\           "cp:r": "clip:rect(${1:top} ${2:right} ${3:bottom} ${4:left});",
\           "bxz": "box-sizing:${1:border-box};",
\           "bxz:cb": "box-sizing:content-box;",
\           "bxz:bb": "box-sizing:border-box;",
\           "bxsh": "box-shadow:${1:inset }${2:hoff} ${3:voff} ${4:blur} ${5:color};",
\           "bxsh:r": "box-shadow:${1:inset }${2:hoff} ${3:voff} ${4:blur} ${5:spread }rgb(${6:0}, ${7:0}, ${8:0});",
\           "bxsh:ra": "box-shadow:${1:inset }${2:h} ${3:v} ${4:blur} ${5:spread }rgba(${6:0}, ${7:0}, ${8:0}, .${9:5});",
\           "bxsh:n": "box-shadow:none;",
\           "m": "margin:|;",
\           "m:a": "margin:auto;",
\           "mt": "margin-top:|;",
\           "mt:a": "margin-top:auto;",
\           "mr": "margin-right:|;",
\           "mr:a": "margin-right:auto;",
\           "mb": "margin-bottom:|;",
\           "mb:a": "margin-bottom:auto;",
\           "ml": "margin-left:|;",
\           "ml:a": "margin-left:auto;",
\           "p": "padding:|;",
\           "pt": "padding-top:|;",
\           "pr": "padding-right:|;",
\           "pb": "padding-bottom:|;",
\           "pl": "padding-left:|;",
\           "w": "width:|;",
\           "w:a": "width:auto;",
\           "h": "height:|;",
\           "h:a": "height:auto;",
\           "maw": "max-width:|;",
\           "maw:n": "max-width:none;",
\           "mah": "max-height:|;",
\           "mah:n": "max-height:none;",
\           "miw": "min-width:|;",
\           "mih": "min-height:|;",
\           "mar": "max-resolution:${1:res};",
\           "mir": "min-resolution:${1:res};",
\           "ori": "orientation:|;",
\           "ori:l": "orientation:landscape;",
\           "ori:p": "orientation:portrait;",
\           "ol": "outline:|;",
\           "ol:n": "outline:none;",
\           "olo": "outline-offset:|;",
\           "olw": "outline-width:|;",
\           "olw:tn": "outline-width:thin;",
\           "olw:m": "outline-width:medium;",
\           "olw:tc": "outline-width:thick;",
\           "ols": "outline-style:|;",
\           "ols:n": "outline-style:none;",
\           "ols:dt": "outline-style:dotted;",
\           "ols:ds": "outline-style:dashed;",
\           "ols:s": "outline-style:solid;",
\           "ols:db": "outline-style:double;",
\           "ols:g": "outline-style:groove;",
\           "ols:r": "outline-style:ridge;",
\           "ols:i": "outline-style:inset;",
\           "ols:o": "outline-style:outset;",
\           "olc": "outline-color:#${1:000};",
\           "olc:i": "outline-color:invert;",
\           "bfv": "backface-visibility:|;",
\           "bfv:h": "backface-visibility:hidden;",
\           "bfv:v": "backface-visibility:visible;",
\           "bd": "border:|;",
\           "bd+": "border:${1:1px} ${2:solid} ${3:#000};",
\           "bd:n": "border:none;",
\           "bdbk": "border-break:${1:close};",
\           "bdbk:c": "border-break:close;",
\           "bdcl": "border-collapse:|;",
\           "bdcl:c": "border-collapse:collapse;",
\           "bdcl:s": "border-collapse:separate;",
\           "bdc": "border-color:#${1:000};",
\           "bdc:t": "border-color:transparent;",
\           "bdi": "border-image:url(|);",
\           "bdi:n": "border-image:none;",
\           "bdti": "border-top-image:url(|);",
\           "bdti:n": "border-top-image:none;",
\           "bdri": "border-right-image:url(|);",
\           "bdri:n": "border-right-image:none;",
\           "bdbi": "border-bottom-image:url(|);",
\           "bdbi:n": "border-bottom-image:none;",
\           "bdli": "border-left-image:url(|);",
\           "bdli:n": "border-left-image:none;",
\           "bdci": "border-corner-image:url(|);",
\           "bdci:n": "border-corner-image:none;",
\           "bdci:c": "border-corner-image:continue;",
\           "bdtli": "border-top-left-image:url(|);",
\           "bdtli:n": "border-top-left-image:none;",
\           "bdtli:c": "border-top-left-image:continue;",
\           "bdtri": "border-top-right-image:url(|);",
\           "bdtri:n": "border-top-right-image:none;",
\           "bdtri:c": "border-top-right-image:continue;",
\           "bdbri": "border-bottom-right-image:url(|);",
\           "bdbri:n": "border-bottom-right-image:none;",
\           "bdbri:c": "border-bottom-right-image:continue;",
\           "bdbli": "border-bottom-left-image:url(|);",
\           "bdbli:n": "border-bottom-left-image:none;",
\           "bdbli:c": "border-bottom-left-image:continue;",
\           "bdf": "border-fit:${1:repeat};",
\           "bdf:c": "border-fit:clip;",
\           "bdf:r": "border-fit:repeat;",
\           "bdf:sc": "border-fit:scale;",
\           "bdf:st": "border-fit:stretch;",
\           "bdf:ow": "border-fit:overwrite;",
\           "bdf:of": "border-fit:overflow;",
\           "bdf:sp": "border-fit:space;",
\           "bdlen": "border-length:|;",
\           "bdlen:a": "border-length:auto;",
\           "bdsp": "border-spacing:|;",
\           "bds": "border-style:|;",
\           "bds:n": "border-style:none;",
\           "bds:h": "border-style:hidden;",
\           "bds:dt": "border-style:dotted;",
\           "bds:ds": "border-style:dashed;",
\           "bds:s": "border-style:solid;",
\           "bds:db": "border-style:double;",
\           "bds:dtds": "border-style:dot-dash;",
\           "bds:dtdtds": "border-style:dot-dot-dash;",
\           "bds:w": "border-style:wave;",
\           "bds:g": "border-style:groove;",
\           "bds:r": "border-style:ridge;",
\           "bds:i": "border-style:inset;",
\           "bds:o": "border-style:outset;",
\           "bdw": "border-width:|;",
\           "bdtw": "border-top-width:|;",
\           "bdrw": "border-right-width:|;",
\           "bdbw": "border-bottom-width:|;",
\           "bdlw": "border-left-width:|;",
\           "bdt": "border-top:|;",
\           "bt": "border-top:|;",
\           "bdt+": "border-top:${1:1px} ${2:solid} ${3:#000};",
\           "bdt:n": "border-top:none;",
\           "bdts": "border-top-style:|;",
\           "bdts:n": "border-top-style:none;",
\           "bdtc": "border-top-color:#${1:000};",
\           "bdtc:t": "border-top-color:transparent;",
\           "bdr": "border-right:|;",
\           "br": "border-right:|;",
\           "bdr+": "border-right:${1:1px} ${2:solid} ${3:#000};",
\           "bdr:n": "border-right:none;",
\           "bdrst": "border-right-style:|;",
\           "bdrst:n": "border-right-style:none;",
\           "bdrc": "border-right-color:#${1:000};",
\           "bdrc:t": "border-right-color:transparent;",
\           "bdb": "border-bottom:|;",
\           "bb": "border-bottom:|;",
\           "bdb+": "border-bottom:${1:1px} ${2:solid} ${3:#000};",
\           "bdb:n": "border-bottom:none;",
\           "bdbs": "border-bottom-style:|;",
\           "bdbs:n": "border-bottom-style:none;",
\           "bdbc": "border-bottom-color:#${1:000};",
\           "bdbc:t": "border-bottom-color:transparent;",
\           "bdl": "border-left:|;",
\           "bl": "border-left:|;",
\           "bdl+": "border-left:${1:1px} ${2:solid} ${3:#000};",
\           "bdl:n": "border-left:none;",
\           "bdls": "border-left-style:|;",
\           "bdls:n": "border-left-style:none;",
\           "bdlc": "border-left-color:#${1:000};",
\           "bdlc:t": "border-left-color:transparent;",
\           "bdrs": "border-radius:|;",
\           "bdtrrs": "border-top-right-radius:|;",
\           "bdtlrs": "border-top-left-radius:|;",
\           "bdbrrs": "border-bottom-right-radius:|;",
\           "bdblrs": "border-bottom-left-radius:|;",
\           "bg": "background:#${1:000};",
\           "bg+": "background:${1:#fff} url(${2}) ${3:0} ${4:0} ${5:no-repeat};",
\           "bg:n": "background:none;",
\           "bg:ie": "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='${1:x}.png',sizingMethod='${2:crop}');",
\           "bgc": "background-color:#${1:fff};",
\           "bgc:t": "background-color:transparent;",
\           "bgi": "background-image:url(|);",
\           "bgi:n": "background-image:none;",
\           "bgr": "background-repeat:|;",
\           "bgr:n": "background-repeat:no-repeat;",
\           "bgr:x": "background-repeat:repeat-x;",
\           "bgr:y": "background-repeat:repeat-y;",
\           "bgr:sp": "background-repeat:space;",
\           "bgr:rd": "background-repeat:round;",
\           "bga": "background-attachment:|;",
\           "bga:f": "background-attachment:fixed;",
\           "bga:s": "background-attachment:scroll;",
\           "bgp": "background-position:${1:0} ${2:0};",
\           "bgpx": "background-position-x:|;",
\           "bgpy": "background-position-y:|;",
\           "bgbk": "background-break:|;",
\           "bgbk:bb": "background-break:bounding-box;",
\           "bgbk:eb": "background-break:each-box;",
\           "bgbk:c": "background-break:continuous;",
\           "bgcp": "background-clip:${1:padding-box};",
\           "bgcp:bb": "background-clip:border-box;",
\           "bgcp:pb": "background-clip:padding-box;",
\           "bgcp:cb": "background-clip:content-box;",
\           "bgcp:nc": "background-clip:no-clip;",
\           "bgo": "background-origin:|;",
\           "bgo:pb": "background-origin:padding-box;",
\           "bgo:bb": "background-origin:border-box;",
\           "bgo:cb": "background-origin:content-box;",
\           "bgsz": "background-size:|;",
\           "bgsz:a": "background-size:auto;",
\           "bgsz:ct": "background-size:contain;",
\           "bgsz:cv": "background-size:cover;",
\           "c": "color:#${1:000};",
\           "c:r": "color:rgb(${1:0}, ${2:0}, ${3:0});",
\           "c:ra": "color:rgba(${1:0}, ${2:0}, ${3:0}, .${4:5});",
\           "cm": "/* |${child} */",
\           "cnt": "content:'|';",
\           "cnt:n": "content:normal;",
\           "cnt:oq": "content:open-quote;",
\           "cnt:noq": "content:no-open-quote;",
\           "cnt:cq": "content:close-quote;",
\           "cnt:ncq": "content:no-close-quote;",
\           "cnt:a": "content:attr(|);",
\           "cnt:c": "content:counter(|);",
\           "cnt:cs": "content:counters(|);",
\           "tbl": "table-layout:|;",
\           "tbl:a": "table-layout:auto;",
\           "tbl:f": "table-layout:fixed;",
\           "cps": "caption-side:|;",
\           "cps:t": "caption-side:top;",
\           "cps:b": "caption-side:bottom;",
\           "ec": "empty-cells:|;",
\           "ec:s": "empty-cells:show;",
\           "ec:h": "empty-cells:hide;",
\           "lis": "list-style:|;",
\           "lis:n": "list-style:none;",
\           "lisp": "list-style-position:|;",
\           "lisp:i": "list-style-position:inside;",
\           "lisp:o": "list-style-position:outside;",
\           "list": "list-style-type:|;",
\           "list:n": "list-style-type:none;",
\           "list:d": "list-style-type:disc;",
\           "list:c": "list-style-type:circle;",
\           "list:s": "list-style-type:square;",
\           "list:dc": "list-style-type:decimal;",
\           "list:dclz": "list-style-type:decimal-leading-zero;",
\           "list:lr": "list-style-type:lower-roman;",
\           "list:ur": "list-style-type:upper-roman;",
\           "lisi": "list-style-image:|;",
\           "lisi:n": "list-style-image:none;",
\           "q": "quotes:|;",
\           "q:n": "quotes:none;",
\           "q:ru": "quotes:'\\00AB' '\\00BB' '\\201E' '\\201C';",
\           "q:en": "quotes:'\\201C' '\\201D' '\\2018' '\\2019';",
\           "ct": "content:|;",
\           "ct:n": "content:normal;",
\           "ct:oq": "content:open-quote;",
\           "ct:noq": "content:no-open-quote;",
\           "ct:cq": "content:close-quote;",
\           "ct:ncq": "content:no-close-quote;",
\           "ct:a": "content:attr(|);",
\           "ct:c": "content:counter(|);",
\           "ct:cs": "content:counters(|);",
\           "coi": "counter-increment:|;",
\           "cor": "counter-reset:|;",
\           "va": "vertical-align:${1:top};",
\           "va:sup": "vertical-align:super;",
\           "va:t": "vertical-align:top;",
\           "va:tt": "vertical-align:text-top;",
\           "va:m": "vertical-align:middle;",
\           "va:bl": "vertical-align:baseline;",
\           "va:b": "vertical-align:bottom;",
\           "va:tb": "vertical-align:text-bottom;",
\           "va:sub": "vertical-align:sub;",
\           "ta": "text-align:${1:left};",
\           "ta:l": "text-align:left;",
\           "ta:c": "text-align:center;",
\           "ta:r": "text-align:right;",
\           "ta:j": "text-align:justify;",
\           "ta-lst": "text-align-last:|;",
\           "tal:a": "text-align-last:auto;",
\           "tal:l": "text-align-last:left;",
\           "tal:c": "text-align-last:center;",
\           "tal:r": "text-align-last:right;",
\           "td": "text-decoration:${1:none};",
\           "td:n": "text-decoration:none;",
\           "td:u": "text-decoration:underline;",
\           "td:o": "text-decoration:overline;",
\           "td:l": "text-decoration:line-through;",
\           "te": "text-emphasis:|;",
\           "te:n": "text-emphasis:none;",
\           "te:ac": "text-emphasis:accent;",
\           "te:dt": "text-emphasis:dot;",
\           "te:c": "text-emphasis:circle;",
\           "te:ds": "text-emphasis:disc;",
\           "te:b": "text-emphasis:before;",
\           "te:a": "text-emphasis:after;",
\           "th": "text-height:|;",
\           "th:a": "text-height:auto;",
\           "th:f": "text-height:font-size;",
\           "th:t": "text-height:text-size;",
\           "th:m": "text-height:max-size;",
\           "ti": "text-indent:|;",
\           "ti:-": "text-indent:-9999px;",
\           "tj": "text-justify:|;",
\           "tj:a": "text-justify:auto;",
\           "tj:iw": "text-justify:inter-word;",
\           "tj:ii": "text-justify:inter-ideograph;",
\           "tj:ic": "text-justify:inter-cluster;",
\           "tj:d": "text-justify:distribute;",
\           "tj:k": "text-justify:kashida;",
\           "tj:t": "text-justify:tibetan;",
\           "tov": "text-overflow:${ellipsis};",
\           "tov:e": "text-overflow:ellipsis;",
\           "tov:c": "text-overflow:clip;",
\           "to": "text-outline:|;",
\           "to+": "text-outline:${1:0} ${2:0} ${3:#000};",
\           "to:n": "text-outline:none;",
\           "tr": "text-replace:|;",
\           "tr:n": "text-replace:none;",
\           "tt": "text-transform:${1:uppercase};",
\           "tt:n": "text-transform:none;",
\           "tt:c": "text-transform:capitalize;",
\           "tt:u": "text-transform:uppercase;",
\           "tt:l": "text-transform:lowercase;",
\           "tw": "text-wrap:|;",
\           "tw:n": "text-wrap:normal;",
\           "tw:no": "text-wrap:none;",
\           "tw:u": "text-wrap:unrestricted;",
\           "tw:s": "text-wrap:suppress;",
\           "tsh": "text-shadow:${1:hoff} ${2:voff} ${3:blur} ${4:#000};",
\           "tsh:r": "text-shadow:${1:h} ${2:v} ${3:blur} rgb(${4:0}, ${5:0}, ${6:0});",
\           "tsh:ra": "text-shadow:${1:h} ${2:v} ${3:blur} rgba(${4:0}, ${5:0}, ${6:0}, .${7:5});",
\           "tsh+": "text-shadow:${1:0} ${2:0} ${3:0} ${4:#000};",
\           "tsh:n": "text-shadow:none;",
\           "trf": "transform:|;",
\           "trf:skx": "transform: skewX(${1:angle});",
\           "trf:sky": "transform: skewY(${1:angle});",
\           "trf:sc": "transform: scale(${1:x}, ${2:y});",
\           "trf:scx": "transform: scaleX(${1:x});",
\           "trf:scy": "transform: scaleY(${1:y});",
\           "trf:scz": "transform: scaleZ(${1:z});",
\           "trf:sc3": "transform: scale3d(${1:x}, ${2:y}, ${3:z});",
\           "trf:r": "transform: rotate(${1:angle});",
\           "trf:rx": "transform: rotateX(${1:angle});",
\           "trf:ry": "transform: rotateY(${1:angle});",
\           "trf:rz": "transform: rotateZ(${1:angle});",
\           "trf:t": "transform: translate(${1:x}, ${2:y});",
\           "trf:tx": "transform: translateX(${1:x});",
\           "trf:ty": "transform: translateY(${1:y});",
\           "trf:tz": "transform: translateZ(${1:z});",
\           "trf:t3": "transform: translate3d(${1:tx}, ${2:ty}, ${3:tz});",
\           "trfo": "transform-origin:|;",
\           "trfs": "transform-style:${1:preserve-3d};",
\           "trs": "transition:${1:prop} ${2:time};",
\           "trsde": "transition-delay:${1:time};",
\           "trsdu": "transition-duration:${1:time};",
\           "trsp": "transition-property:${1:prop};",
\           "trstf": "transition-timing-function:${1:tfunc};",
\           "lh": "line-height:|;",
\           "whs": "white-space:|;",
\           "whs:n": "white-space:normal;",
\           "whs:p": "white-space:pre;",
\           "whs:nw": "white-space:nowrap;",
\           "whs:pw": "white-space:pre-wrap;",
\           "whs:pl": "white-space:pre-line;",
\           "whsc": "white-space-collapse:|;",
\           "whsc:n": "white-space-collapse:normal;",
\           "whsc:k": "white-space-collapse:keep-all;",
\           "whsc:l": "white-space-collapse:loose;",
\           "whsc:bs": "white-space-collapse:break-strict;",
\           "whsc:ba": "white-space-collapse:break-all;",
\           "wob": "word-break:|;",
\           "wob:n": "word-break:normal;",
\           "wob:k": "word-break:keep-all;",
\           "wob:ba": "word-break:break-all;",
\           "wos": "word-spacing:|;",
\           "wow": "word-wrap:|;",
\           "wow:nm": "word-wrap:normal;",
\           "wow:n": "word-wrap:none;",
\           "wow:u": "word-wrap:unrestricted;",
\           "wow:s": "word-wrap:suppress;",
\           "wow:b": "word-wrap:break-word;",
\           "wm": "writing-mode:${1:lr-tb};",
\           "wm:lrt": "writing-mode:lr-tb;",
\           "wm:lrb": "writing-mode:lr-bt;",
\           "wm:rlt": "writing-mode:rl-tb;",
\           "wm:rlb": "writing-mode:rl-bt;",
\           "wm:tbr": "writing-mode:tb-rl;",
\           "wm:tbl": "writing-mode:tb-lr;",
\           "wm:btl": "writing-mode:bt-lr;",
\           "wm:btr": "writing-mode:bt-rl;",
\           "lts": "letter-spacing:|;",
\           "lts-n": "letter-spacing:normal;",
\           "f": "font:|;",
\           "f+": "font:${1:1em} ${2:Arial,sans-serif};",
\           "fw": "font-weight:|;",
\           "fw:n": "font-weight:normal;",
\           "fw:b": "font-weight:bold;",
\           "fw:br": "font-weight:bolder;",
\           "fw:lr": "font-weight:lighter;",
\           "fs": "font-style:${italic};",
\           "fs:n": "font-style:normal;",
\           "fs:i": "font-style:italic;",
\           "fs:o": "font-style:oblique;",
\           "fv": "font-variant:|;",
\           "fv:n": "font-variant:normal;",
\           "fv:sc": "font-variant:small-caps;",
\           "fz": "font-size:|;",
\           "fza": "font-size-adjust:|;",
\           "fza:n": "font-size-adjust:none;",
\           "ff": "font-family:|;",
\           "ff:s": "font-family:serif;",
\           "ff:ss": "font-family:sans-serif;",
\           "ff:c": "font-family:cursive;",
\           "ff:f": "font-family:fantasy;",
\           "ff:m": "font-family:monospace;",
\           "ff:a": "font-family: Arial, \"Helvetica Neue\", Helvetica, sans-serif;",
\           "ff:t": "font-family: \"Times New Roman\", Times, Baskerville, Georgia, serif;",
\           "ff:v": "font-family: Verdana, Geneva, sans-serif;",
\           "fef": "font-effect:|;",
\           "fef:n": "font-effect:none;",
\           "fef:eg": "font-effect:engrave;",
\           "fef:eb": "font-effect:emboss;",
\           "fef:o": "font-effect:outline;",
\           "fem": "font-emphasize:|;",
\           "femp": "font-emphasize-position:|;",
\           "femp:b": "font-emphasize-position:before;",
\           "femp:a": "font-emphasize-position:after;",
\           "fems": "font-emphasize-style:|;",
\           "fems:n": "font-emphasize-style:none;",
\           "fems:ac": "font-emphasize-style:accent;",
\           "fems:dt": "font-emphasize-style:dot;",
\           "fems:c": "font-emphasize-style:circle;",
\           "fems:ds": "font-emphasize-style:disc;",
\           "fsm": "font-smooth:|;",
\           "fsm:a": "font-smooth:auto;",
\           "fsm:n": "font-smooth:never;",
\           "fsm:aw": "font-smooth:always;",
\           "fst": "font-stretch:|;",
\           "fst:n": "font-stretch:normal;",
\           "fst:uc": "font-stretch:ultra-condensed;",
\           "fst:ec": "font-stretch:extra-condensed;",
\           "fst:c": "font-stretch:condensed;",
\           "fst:sc": "font-stretch:semi-condensed;",
\           "fst:se": "font-stretch:semi-expanded;",
\           "fst:e": "font-stretch:expanded;",
\           "fst:ee": "font-stretch:extra-expanded;",
\           "fst:ue": "font-stretch:ultra-expanded;",
\           "op": "opacity:|;",
\           "op+": "opacity: $1;\nfilter: alpha(opacity=$2);",
\           "op:ie": "filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=100);",
\           "op:ms": "-ms-filter:'progid:DXImageTransform.Microsoft.Alpha(Opacity=100)';",
\           "rsz": "resize:|;",
\           "rsz:n": "resize:none;",
\           "rsz:b": "resize:both;",
\           "rsz:h": "resize:horizontal;",
\           "rsz:v": "resize:vertical;",
\           "cur": "cursor:${pointer};",
\           "cur:a": "cursor:auto;",
\           "cur:d": "cursor:default;",
\           "cur:c": "cursor:crosshair;",
\           "cur:ha": "cursor:hand;",
\           "cur:he": "cursor:help;",
\           "cur:m": "cursor:move;",
\           "cur:p": "cursor:pointer;",
\           "cur:t": "cursor:text;",
\           "fxd": "flex-direction:|;",
\           "fxd:r": "flex-direction:row;",
\           "fxd:rr": "flex-direction:row-reverse;",
\           "fxd:c": "flex-direction:column;",
\           "fxd:cr": "flex-direction:column-reverse;",
\           "fxw": "flex-wrap: |;",
\           "fxw:n": "flex-wrap:nowrap;",
\           "fxw:w": "flex-wrap:wrap;",
\           "fxw:wr": "flex-wrap:wrap-reverse;",
\           "fxf": "flex-flow:|;",
\           "jc": "justify-content:|;",
\           "jc:fs": "justify-content:flex-start;",
\           "jc:fe": "justify-content:flex-end;",
\           "jc:c": "justify-content:center;",
\           "jc:sb": "justify-content:space-between;",
\           "jc:sa": "justify-content:space-around;",
\           "ai": "align-items:|;",
\           "ai:fs": "align-items:flex-start;",
\           "ai:fe": "align-items:flex-end;",
\           "ai:c": "align-items:center;",
\           "ai:b": "align-items:baseline;",
\           "ai:s": "align-items:stretch;",
\           "ac": "align-content:|;",
\           "ac:fs": "align-content:flex-start;",
\           "ac:fe": "align-content:flex-end;",
\           "ac:c": "align-content:center;",
\           "ac:sb": "align-content:space-between;",
\           "ac:sa": "align-content:space-around;",
\           "ac:s": "align-content:stretch;",
\           "ord": "order:|;",
\           "fxg": "flex-grow:|;",
\           "fxsh": "flex-shrink:|;",
\           "fxb": "flex-basis:|;",
\           "fx": "flex:|;",
\           "as": "align-self:|;",
\           "as:a": "align-self:auto;",
\           "as:fs": "align-self:flex-start;",
\           "as:fe": "align-self:flex-end;",
\           "as:c": "align-self:center;",
\           "as:b": "align-self:baseline;",
\           "as:s": "align-self:stretch;",
\           "pgbb": "page-break-before:|;",
\           "pgbb:au": "page-break-before:auto;",
\           "pgbb:al": "page-break-before:always;",
\           "pgbb:l": "page-break-before:left;",
\           "pgbb:r": "page-break-before:right;",
\           "pgbi": "page-break-inside:|;",
\           "pgbi:au": "page-break-inside:auto;",
\           "pgbi:av": "page-break-inside:avoid;",
\           "pgba": "page-break-after:|;",
\           "pgba:au": "page-break-after:auto;",
\           "pgba:al": "page-break-after:always;",
\           "pgba:l": "page-break-after:left;",
\           "pgba:r": "page-break-after:right;",
\           "orp": "orphans:|;",
\           "us": "user-select:${none};",
\           "wid": "widows:|;",
\           "wfsm": "-webkit-font-smoothing:${antialiased};",
\           "wfsm:a": "-webkit-font-smoothing:antialiased;",
\           "wfsm:s": "-webkit-font-smoothing:subpixel-antialiased;",
\           "wfsm:sa": "-webkit-font-smoothing:subpixel-antialiased;",
\           "wfsm:n": "-webkit-font-smoothing:none;"
\        },
\        'filters': 'fc',
\        'ignore_embeded_filetype': 1,
\    },
\    'sass': {
\        'extends': 'css',
\        'snippets': {
\            '@if': "@if {\n\t|\n}",
\            '@e': "@else {\n\t|\n}",
\            '@in': "@include |",
\            '@ex': "@extend |",
\            '@mx': "@mixin {\n\t|\n}",
\            '@fn': "@function {\n\t|\n}",
\            '@r': "@return |",
\        },
\    },
\    'scss': {
\        'extends': 'css',
\    },
\    'less': {
\        'extends': 'css',
\    },
\    'css.drupal': {
\        'extends': 'css',
\    },
\    'styled': {
\        'extends': 'css',
\    },
\    'html': {
\        'snippets': {
\            '!': "html:5",
\            '!!!': "<!DOCTYPE html>\n",
\            '!!!4t':  "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n",
\            '!!!4s':  "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n",
\            '!!!xt':  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n",
\            '!!!xs':  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n",
\            '!!!xxs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n",
\            'c': "<!-- |${child} -->",
\            'cc:ie6': "<!--[if lte IE 6]>\n\t${child}|\n<![endif]-->",
\            'cc:ie': "<!--[if IE]>\n\t${child}|\n<![endif]-->",
\            'cc:noie': "<!--[if !IE]><!-->\n\t${child}|\n<!--<![endif]-->",
\            'html:4t': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\">\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:4s': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\">\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xt': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xxs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=${charset}\" />\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:5': "<!DOCTYPE html>\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."\t<meta charset=\"${charset}\">\n"
\                    ."\t<title></title>\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\        },
\        'default_attributes': {
\            'a': [{'href': ''}],
\            'a:blank': [{'href': 'http://|'},{'target': '_blank'},{'rel': 'noopener noreferrer'}],
\            'a:link': [{'href': 'http://|'}],
\            'a:mail': [{'href': 'mailto:|'}],
\            'a:tel': [{'href': 'tel:+|'}],
\            'abbr': [{'title': ''}],
\            'acronym': [{'title': ''}],
\            'acr': [{'title': ''}],
\            'base': [{'href': ''}],
\            'bdo': [{'dir': ''}],
\            'bdo:r': [{'dir': 'rtl'}],
\            'bdo:l': [{'dir': 'ltr'}],
\            'button:disabled': [{'disabled': 'disabled'}],
\            'button:d': [{'disabled': 'disabled'}],
\            'btn:d': [{'disabled': 'disabled'}],
\            'button:submit': [{'type': 'submit'}],
\            'button:s': [{'type': 'submit'}],
\            'btn:s': [{'type': 'submit'}],
\            'button:reset': [{'type': 'reset'}],
\            'button:r': [{'type': 'reset'}],
\            'btn:r': [{'type': 'reset'}],
\            'del': [{'datetime': '${datetime}'}],
\            'ins': [{'datetime': '${datetime}'}],
\            'link:css': [{'rel': 'stylesheet'}, g:emmet_html5 ? {} : {'type': 'text/css'}, {'href': '|style.css'}, {'media': 'all'}],
\            'link:manifest': [{'rel': 'manifest'},{'href': '|manifest.json'}],
\            'link:mf': [{'rel': 'manifest'},{'href': '|manifest.json'}],
\            'link:print': [{'rel': 'stylesheet'}, g:emmet_html5 ? {} : {'type': 'text/css'}, {'href': '|print.css'}, {'media': 'print'}],
\            'link:import': [{'rel': 'import'}, {'href': '|.html'}],
\            'link:im': [{'rel': 'import'}, {'href': '|.html'}],
\            'link:favicon': [{'rel': 'shortcut icon'}, {'type': 'image/x-icon'}, {'href': '|favicon.ico'}],
\            'link:touch': [{'rel': 'apple-touch-icon'}, {'href': '|favicon.png'}],
\            'link:rss': [{'rel': 'alternate'}, {'type': 'application/rss+xml'}, {'title': 'RSS'}, {'href': '|rss.xml'}],
\            'link:atom': [{'rel': 'alternate'}, {'type': 'application/atom+xml'}, {'title': 'Atom'}, {'href': 'atom.xml'}],
\            'marquee': [{'behavior': ''},{'direction': ''}],
\            'meta:utf': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=UTF-8'}],
\            'meta:vp': [{'name': 'viewport'}, {'content': 'width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'}],
\            'meta:win': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=Win-1251'}],
\            'meta:compat': [{'http-equiv': 'X-UA-Compatible'}, {'content': 'IE=7'}],
\            'meta:desc': [{'name': 'description'},{'content': ''}],
\            'meta:edge': [{'http-equiv': 'X-UA-Compatible'}, {'content': 'ie=edge'}],
\            'meta:kw': [{'name': 'keywords'},{'content': ''}],
\            'meta:redirect': [{'http-equiv': 'Content-Type'}, {'content': '0; url=http://example.com'}],
\            'style': g:emmet_html5 ? [] : [{'type': 'text/css'}],
\            'script': g:emmet_html5 ? [] : [{'type': 'text/javascript'}],
\            'script:src': (g:emmet_html5 ? [] : [{'type': 'text/javascript'}]) + [{'src': ''}],
\            'img': [{'src': ''}, {'alt': ''}],
\            'img:srcset': [{'srcset': ''},{'src': ''}, {'alt': ''}],
\            'img:s': [{'srcset': ''},{'src': ''}, {'alt': ''}],
\            'img:sizes': [{'sizes': ''},{'srcset': ''},{'src': ''}, {'alt': ''}],
\            'img:z': [{'sizes': ''},{'srcset': ''},{'src': ''}, {'alt': ''}],
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
\            'fieldset:disabled': [{'disabled': 'disabled'}],
\            'fieldset:d': [{'disabled': 'disabled'}],
\            'fset:d': [{'disabled': 'disabled'}],
\            'fst:disabled': [{'disabled': 'disabled'}],
\            'form': [{'action': ''}],
\            'form:get': [{'action': ''}, {'method': 'get'}],
\            'form:post': [{'action': ''}, {'method': 'post'}],
\            'form:upload': [{'action': ''}, {'method': 'post'}, {'enctype': 'multipart/form-data'}],
\            'label': [{'for': ''}],
\            'input': [{'type': ''}],
\            'input:hidden': [{'type': 'hidden'}, {'name': ''}],
\            'input:h': [{'type': 'hidden'}, {'name': ''}],
\            'input:text': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:t': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:search': [{'type': 'search'}, {'name': ''}, {'id': ''}],
\            'input:email': [{'type': 'email'}, {'name': ''}, {'id': ''}],
\            'input:tel': [{'type': 'tel'}, {'name': ''}, {'id': ''}],
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
\            'select:disabled': [{'name': ''}, {'id': ''}, {'disabled': 'disabled'}],
\            'source:media': [{'media': '(minwidth: )'},{'srcset': ''}],
\            'source:m': [{'media': '(minwidth: )'},{'srcset': ''}],
\            'source:media:type': [{'media': '(minwidth: )'},{'srcset': ''},{'type': 'image/'}],
\            'source:media:sizes': [{'media': '(minwidth: )'},{'srcset': ''},{'sizes': ''}],
\            'source:sizes:type': [{'sizes': ''},{'srcset': ''},{'type': 'image/'}],
\            'source:src': [{'src': ''},{'type': ''}],
\            'source:sc': [{'src': ''},{'type': ''}],
\            'source:srcset': [{'srcset': ''}],
\            'source:s': [{'srcset': ''}],
\            'source:type': [{'srcset': ''},{'type': 'image/'}],
\            'source:t': [{'srcset': ''},{'type': 'image/'}],
\            'source:sizes': [{'sizes': ''},{'srcset': ''}],
\            'source:z': [{'sizes': ''},{'srcset': ''}],
\            'option': [{'value': ''}],
\            'textarea': [{'name': ''}, {'id': ''}, {'cols': '30'}, {'rows': '10'}],
\            'menu:context': [{'type': 'context'}],
\            'menu:c': [{'type': 'context'}],
\            'menu:toolbar': [{'type': 'toolbar'}],
\            'menu:t': [{'type': 'toolbar'}],
\            'video': [{'src': ''}],
\            'audio': [{'src': ''}],
\            'html:xml': [{'xmlns': 'http://www.w3.org/1999/xhtml'}, {'xml:lang': '${lang}'}],
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
\            'mn': 'main',
\            'tem': 'template',
\            'bq': 'blockquote',
\            'acr': 'acronym',
\            'fig': 'figure',
\            'figc': 'figcaption',
\            'ifr': 'iframe',
\            'emb': 'embed',
\            'obj': 'object',
\            'src:*': 'source',
\            'cap': 'caption',
\            'colg': 'colgroup',
\            'fst': 'fieldset',
\            'fst:disabled': 'fieldset',
\            'btn': 'button',
\            'btn:d': 'button',
\            'btn:r': 'button',
\            'btn:s': 'button',
\            'optg': 'optgroup',
\            'opt': 'option',
\            'pic': 'picture',
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
\            'fset:d': 'fieldset',
\            'datag': 'datagrid',
\            'datal': 'datalist',
\            'kg': 'keygen',
\            'out': 'output',
\            'det': 'details',
\            'cmd': 'command',
\            'sum': 'summary',
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
\            'optg': 'optgroup>option',
\            'ri:dpr': 'img:s',
\            'ri:d': 'img:s',
\            'ri:viewport': 'img:z',
\            'ri:vp': 'img:z',
\            'ri:art': 'pic>source:m+img',
\            'ri:a': 'pic>source:m+img',
\            'ri:type': 'pic>source:t+img',
\            'ri:t': 'pic>source:t+img',
\        },
\        'empty_elements': 'area,base,basefont,br,col,frame,hr,img,input,isindex,link,meta,param,embed,keygen,command',
\        'block_elements': 'address,applet,blockquote,button,center,dd,del,dir,div,dl,dt,fieldset,form,frameset,hr,iframe,ins,isindex,li,link,map,menu,noframes,noscript,object,ol,p,pre,script,table,tbody,td,tfoot,th,thead,tr,ul,h1,h2,h3,h4,h5,h6',
\        'inline_elements': 'a,abbr,acronym,applet,b,basefont,bdo,big,br,button,cite,code,del,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,object,q,s,samp,script,small,span,strike,strong,sub,sup,textarea,tt,u,var',
\        'empty_element_suffix': g:emmet_html5 ? '>' : ' />',
\        'indent_blockelement': 0,
\        'block_all_childless': 0,
\    },
\    'elm': {
\        'indentation': '    ',
\        'extends': 'html',
\    },
\    'xml': {
\        'extends': 'html',
\        'empty_elements': '',
\        'block_elements': '',
\        'inline_elements': '',
\    },
\    'htmldjango': {
\        'extends': 'html',
\    },
\    'html.django_template': {
\        'extends': 'html',
\    },
\    'jade': {
\        'indentation': '  ',
\        'extends': 'html',
\        'snippets': {
\            '!': "html:5",
\            '!!!': "doctype html\n",
\            '!!!4t': "doctype HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"\n",
\            '!!!4s': "doctype HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\"\n",
\            '!!!xt': "doctype transitional\n",
\            '!!!xs': "doctype strict\n",
\            '!!!xxs': "doctype 1.1\n",
\            'c': "\/\/ |${child}",
\            'html:4t': "doctype HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"\n"
\                    ."html(lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(http-equiv=\"Content-Type\", content=\"text/html;charset=${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\            'html:4s': "doctype HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\"\n"
\                    ."html(lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(http-equiv=\"Content-Type\", content=\"text/html;charset=${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\            'html:xt': "doctype transitional\n"
\                    ."html(xmlns=\"http://www.w3.org/1999/xhtml\", xml:lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(http-equiv=\"Content-Type\", content=\"text/html;charset=${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\            'html:xs': "doctype strict\n"
\                    ."html(xmlns=\"http://www.w3.org/1999/xhtml\", xml:lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(http-equiv=\"Content-Type\", content=\"text/html;charset=${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\            'html:xxs': "doctype 1.1\n"
\                    ."html(xmlns=\"http://www.w3.org/1999/xhtml\", xml:lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(http-equiv=\"Content-Type\", content=\"text/html;charset=${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\            'html:5': "doctype html\n"
\                    ."html(lang=\"${lang}\")\n"
\                    ."\thead\n"
\                    ."\t\tmeta(charset=\"${charset}\")\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n\t\t${child}|",
\        },
\    },
\    'pug': {
\        'extends': 'jade',
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
\            'ap' : 'xsl:apply-templates',
\        },
\        'expandos': {
\            'choose': 'xsl:choose>xsl:when+xsl:otherwise',
\        }
\    },
\    'jsx': {
\        'extends': 'html',
\        'attribute_name': {'class': 'className', 'for': 'htmlFor'},
\        'empty_element_suffix': ' />',
\    },
\    'javascriptreact': {
\        'extends': 'html',
\        'attribute_name': {'class': 'className', 'for': 'htmlFor'},
\        'empty_element_suffix': ' />',
\    },
\    'tsx': {
\        'extends': 'jsx',
\    },
\    'typescriptreact': {
\        'extends': 'html',
\        'attribute_name': {'class': 'className', 'for': 'htmlFor'},
\        'empty_element_suffix': ' />',
\    },
\    'xslt': {
\        'extends': 'xsl',
\    },
\    'haml': {
\        'indentation': '  ',
\        'extends': 'html',
\        'snippets': {
\            'html:5': "!!! 5\n"
\                    ."%html{:lang => \"${lang}\"}\n"
\                    ."\t%head\n"
\                    ."\t\t%meta{:charset => \"${charset}\"}\n"
\                    ."\t\t%title\n"
\                    ."\t%body\n"
\                    ."\t\t${child}|\n",
\        },
\        'attribute_style': 'hash',
\    },
\    'slim': {
\        'indentation': '  ',
\        'extends': 'html',
\        'snippets': {
\            'html:5': "doctype 5\n"
\                    ."html lang=\"${lang}\"\n"
\                    ."\thead\n"
\                    ."\t\tmeta charset=\"${charset}\"\n"
\                    ."\t\ttitle\n"
\                    ."\tbody\n"
\                    ."\t\t${child}|\n",
\        },
\        'ignore_embeded_filetype': 1,
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
\                    ."\t<xsd:element name=\"\" type=\"\"/>\n"
\                    ."</xsd:schema>\n"
\        }
\    },
\}

if exists('g:user_emmet_settings')
  call emmet#mergeConfig(s:emmet_settings, g:user_emmet_settings)
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim:set et:

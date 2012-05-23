function! zencoding#html#toString(settings, current, type, inline, filters, itemno, indent)
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

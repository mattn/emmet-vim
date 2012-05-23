function! zencoding#slim#findTokens(str)
  return zencoding#html#findTokens(a:str)
endfunction

function! zencoding#slim#parseIntoTree(abbr, type)
  return zencoding#html#parseIntoTree(a:abbr, a:type)
endfunction

function! zencoding#slim#toString(settings, current, type, inline, filters, itemno, indent)
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
    let str .= current_name
    for attr in keys(current.attr)
      let val = current.attr[attr]
      while val =~ '\$\([^#{]\|$\)'
        let val = substitute(val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
      endwhile
      let attr = substitute(attr, '\$$', itemno+1, '')
      let str .= ' ' . attr . '="' . val . '"'
    endfor

    let inner = ''
    if len(current.value) > 0
      let str .= "\n"
      for line in split(current.value[1:-2], "\n")
        let str .= " | " . line . "\n"
      endfor
    endif
    if len(current.child) == 1 && len(current.child[0].name) == 0
      let str .= "\n"
      for line in split(current.child[0].value[1:-2], "\n")
        let str .= " | " . line . "\n"
      endfor
    elseif len(current.child) > 0
      for child in current.child
        let inner .= zencoding#toString(child, type, inline, filters)
      endfor
      let inner = substitute(inner, "\n", "\n  ", 'g')
      let inner = substitute(inner, "\n  $", "", 'g')
      let str .= "\n  " . inner
    endif
  endif
  if str !~ "\n$"
    let str .= "\n"
  endif
  return str
endfunction

function! emmet#lang#elm#findTokens(str) abort
  return emmet#lang#html#findTokens(a:str)
endfunction

function! emmet#lang#elm#parseIntoTree(abbr, type) abort
  let l:tree = emmet#lang#html#parseIntoTree(a:abbr, a:type)
  if len(l:tree.child) < 2 | return l:tree | endif

  " Add ',' nodes between root elements.
  let l:new_children = []
  for l:child in l:tree.child[0:-2]
    let l:comma = emmet#newNode()
    let l:comma.name = ','
    call add(l:new_children, l:child)
    call add(l:new_children, l:comma)
  endfor
  call add(l:new_children, l:tree.child[-1])
  let l:tree.child = l:new_children
  return l:tree
endfunction

function! emmet#lang#elm#renderNode(node)
  let l:elm_nodes = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        \, 'div', 'p', 'hr', 'pre', 'blockquote'
        \, 'span', 'a', 'code', 'em', 'strong', 'i', 'b', 'u', 'sub', 'sup', 'br'
        \, 'ol', 'ul', 'li', 'dl', 'dt', 'dd'
        \, 'img', 'iframe', 'canvas', 'math'
        \, 'form', 'input', 'textarea', 'button', 'select', 'option'
        \, 'section', 'nav', 'article', 'aside', 'header', 'footer', 'address', 'main_', 'body'
        \, 'figure', 'figcaption'
        \, 'table', 'caption', 'colgroup', 'col', 'tbody', 'thead', 'tfoot', 'tr', 'td', 'th'
        \, 'fieldset', 'legend', 'label', 'datalist', 'optgroup', 'keygen', 'output', 'progress', 'meter'
        \, 'audio', 'video', 'source', 'track'
        \, 'embed', 'object', 'param'
        \, 'ins', 'del'
        \, 'small', 'cite', 'dfn', 'abbr', 'time', 'var', 'samp', 'kbd', 's', 'q'
        \, 'mark', 'ruby', 'rt', 'rp', 'bdi', 'bdo', 'wbr'
        \, 'details', 'summary', 'menuitem', 'menu']

  if index(l:elm_nodes, a:node) >= 0
    return a:node
  endif
  return 'node "' . a:node . '"'
endfunction

function! emmet#lang#elm#renderParam(param)
  let l:elm_events = ["onClick", "onDoubleClick"
        \, "onMouseDown", "onMouseUp"
        \, "onMouseEnter", "onMouseLeave"
        \, "onMouseOver", "onMouseOut"
        \, "onInput", "onCheck", "onSubmit"
        \, "onBlur", "onFocus"
        \, "on", "onWithOptions", "Options", "defaultOptions"
        \, "targetValue", "targetChecked", "keyCode"]
  if index(l:elm_events, a:param) >= 0
    return a:param
  endif
  let l:elm_attributes = ["style", "map" , "class", "id", "title", "hidden"
        \, "type", "type_", "value", "defaultValue", "checked", "placeholder", "selected"
        \, "accept", "acceptCharset", "action", "autocomplete", "autofocus"
        \, "disabled", "enctype", "formaction", "list", "maxlength", "minlength", "method", "multiple"
        \, "name", "novalidate", "pattern", "readonly", "required", "size", "for", "form"
        \, "max", "min", "step"
        \, "cols", "rows", "wrap"
        \, "href", "target", "download", "downloadAs", "hreflang", "media", "ping", "rel"
        \, "ismap", "usemap", "shape", "coords"
        \, "src", "height", "width", "alt"
        \, "autoplay", "controls", "loop", "preload", "poster", "default", "kind", "srclang"
        \, "sandbox", "seamless", "srcdoc"
        \, "reversed", "start"
        \, "align", "colspan", "rowspan", "headers", "scope"
        \, "async", "charset", "content", "defer", "httpEquiv", "language", "scoped"
        \, "accesskey", "contenteditable", "contextmenu", "dir", "draggable", "dropzone"
        \, "itemprop", "lang", "spellcheck", "tabindex"
        \, "challenge", "keytype"
        \, "cite", "datetime", "pubdate", "manifest"]

  if index(l:elm_attributes, a:param) >= 0
    if a:param == 'type'
      return 'type_'
    endif
    return a:param
  endif
  return 'attribute "' . a:param . '"'
endfunction

function! emmet#lang#elm#toString(settings, current, type, inline, filters, itemno, indent) abort
  let l:settings = a:settings
  let l:current = a:current
  let l:type = a:type
  let l:inline = a:inline
  let l:filters = a:filters
  let l:itemno = a:itemno
  let l:indent = emmet#getIndentation(l:type)
  let l:dollar_expr = emmet#getResource(l:type, 'dollar_expr', 1)
  let l:str = ''

  " comma between items with *, eg. li*3
  if l:itemno > 0
    let l:str = ", "
  endif

  let l:current_name = l:current.name
  if l:dollar_expr
    let l:current_name = substitute(l:current.name, '\$$', l:itemno+1, '')
  endif

  if len(l:current.name) > 0
    " inserted root comma nodes
    if l:current_name == ','
      return "\n, "
    endif
    let l:str .= emmet#lang#elm#renderNode(l:current_name)
    let l:tmp = ''
    for l:attr in emmet#util#unique(l:current.attrs_order + keys(l:current.attr))
      if !has_key(l:current.attr, l:attr)
        continue
      endif
      let l:Val = l:current.attr[l:attr]

      let l:attr = emmet#lang#elm#renderParam(l:attr)

      if type(l:Val) == 2 && l:Val == function('emmet#types#true')
        let l:tmp .= ', ' . l:attr . ' True'
      else
        if l:dollar_expr
          while l:Val =~# '\$\([^#{]\|$\)'
            let l:Val = substitute(l:Val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          endwhile
          let l:attr = substitute(l:attr, '\$$', l:itemno+1, '')
        endif
        let l:valtmp = substitute(l:Val, '\${cursor}', '', '')
        if l:attr ==# 'id' && len(l:valtmp) > 0
          let l:tmp .=', id "' . l:Val . '"'
        elseif l:attr ==# 'class' && len(l:valtmp) > 0
          let l:tmp .= ', class "' . substitute(l:Val, '\.', ' ', 'g') . '"'
        else
          let l:tmp .= ', ' . l:attr . ' "' . l:Val . '"'
        endif
      endif
    endfor

    if ! len(l:tmp)
      let l:str .= ' []'
    else
      let l:tmp = strpart(l:tmp, 2)
      let l:str .= ' [ ' . l:tmp . ' ]'
    endif

    " No children quit early
    if len(l:current.child) == 0 && len(l:current.value) == 0
      "Place cursor in node with no value or children
      let l:str .= ' [${cursor}]'
      return l:str
    endif

    let l:inner = ''

    " Parent contex text
    if len(l:current.value) > 0
      let l:text = l:current.value[1:-2]
      if l:dollar_expr
        let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
        let l:text = substitute(l:text, '\${nr}', "\n", 'g')
        let l:text = substitute(l:text, '\\\$', '$', 'g')
        " let l:str = substitute(l:str, '\$#', l:text, 'g')
        let l:inner .= ', text "' . l:text . '"'
      endif
    endif


    " Has children
    for l:child in l:current.child
      if len(l:child.name) == 0 && len(l:child.value) > 0
        "  Text node
        let l:text = l:child.value[1:-2]
        if l:dollar_expr
          let l:text = substitute(l:text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", l:itemno+1).submatch(2)', 'g')
          let l:text = substitute(l:text, '\${nr}', "\n", 'g')
          let l:text = substitute(l:text, '\\\$', '$', 'g')
        endif
        let l:inner .= ', text "' . l:text . '"'
      else
        " Other nodes
        let l:inner .= ', ' . emmet#toString(l:child, l:type, l:inline, l:filters, 0, l:indent)
      endif
    endfor

    let l:inner = substitute(l:inner, "\n", "\n" . escape(l:indent, '\'), 'g')
    let l:inner = substitute(l:inner, "\n" . escape(l:indent, '\') . '$', '', 'g')
    let l:inner = strpart(l:inner, 2)

    let l:inner = substitute(l:inner, '  ', '', 'g')

    if ! len(l:inner)
      let l:str .= ' []'
    else
      let l:str .= ' [ ' . l:inner . ' ]'
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

function! emmet#lang#elm#imageEncode() abort
endfunction

function! emmet#lang#elm#parseTag(tag) abort
  return {}
endfunction

function! emmet#lang#elm#toggleComment() abort
endfunction

function! emmet#lang#elm#balanceTag(flag) range abort
endfunction

function! emmet#lang#elm#moveNextPrevItem(flag) abort
  return emmet#lang#elm#moveNextPrev(a:flag)
endfunction

function! emmet#lang#elm#moveNextPrev(flag) abort
endfunction

function! emmet#lang#elm#splitJoinTag() abort
endfunction

function! emmet#lang#elm#removeTag() abort
endfunction

function! emmet#lang#elm#mergeLines() abort
endfunction

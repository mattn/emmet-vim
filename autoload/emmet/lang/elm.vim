function! emmet#lang#elm#findTokens(str) abort
  return emmet#lang#html#findTokens(a:str)
endfunction

function! emmet#lang#elm#parseIntoTree(abbr, type) abort
  let tree = emmet#lang#html#parseIntoTree(a:abbr, a:type)
  if len(tree.child) < 2 | return tree | endif

  " Add ',' nodes between root elements.
  let new_children = []
  for child in tree.child[0:-2]
    let comma = emmet#newNode()
    let comma.name = ','
    call add(new_children, child)
    call add(new_children, comma)
  endfor
  call add(new_children, tree.child[-1])
  let tree.child = new_children
  return tree
endfunction

function! emmet#lang#elm#renderNode(node)
  let elm_nodes = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'
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

  if index(elm_nodes, a:node) >= 0
    return a:node
  endif
  return 'node "' . a:node . '"'
endfunction

function! emmet#lang#elm#renderParam(param)
  let elm_events = ["onClick", "onDoubleClick"
        \, "onMouseDown", "onMouseUp"
        \, "onMouseEnter", "onMouseLeave"
        \, "onMouseOver", "onMouseOut"
        \, "onInput", "onCheck", "onSubmit"
        \, "onBlur", "onFocus"
        \, "on", "onWithOptions", "Options", "defaultOptions"
        \, "targetValue", "targetChecked", "keyCode"]
  if index(elm_events, a:param) >= 0
    return a:param
  endif
  let elm_attributes = ["style", "map" , "class", "id", "title", "hidden"
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

  if index(elm_attributes, a:param) >= 0
    if a:param == 'type'
      return 'type_'
    endif
    return a:param
  endif
  return 'attribute "' . a:param . '"'
endfunction

function! emmet#lang#elm#toString(settings, current, type, inline, filters, itemno, indent) abort
  let settings = a:settings
  let current = a:current
  let type = a:type
  let inline = a:inline
  let filters = a:filters
  let itemno = a:itemno
  let indent = emmet#getIndentation(type)
  let dollar_expr = emmet#getResource(type, 'dollar_expr', 1)
  let str = ''

  " comma between items with *, eg. li*3
  if itemno > 0
    let str = ", "
  endif

  let current_name = current.name
  if dollar_expr
    let current_name = substitute(current.name, '\$$', itemno+1, '')
  endif

  if len(current.name) > 0
    " inserted root comma nodes
    if current_name == ','
      return "\n, "
    endif
    let str .= emmet#lang#elm#renderNode(current_name)
    let tmp = ''
    for attr in emmet#util#unique(current.attrs_order + keys(current.attr))
      if !has_key(current.attr, attr)
        continue
      endif
      let Val = current.attr[attr]

      let attr = emmet#lang#elm#renderParam(attr)

      if type(Val) == 2 && Val == function('emmet#types#true')
        let tmp .= ', ' . attr . ' True'
      else
        if dollar_expr
          while Val =~# '\$\([^#{]\|$\)'
            let Val = substitute(Val, '\(\$\+\)\([^{]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
          endwhile
          let attr = substitute(attr, '\$$', itemno+1, '')
        endif
        let valtmp = substitute(Val, '\${cursor}', '', '')
        if attr ==# 'id' && len(valtmp) > 0
          let tmp .=', id "' . Val . '"'
        elseif attr ==# 'class' && len(valtmp) > 0
          let tmp .= ', class "' . substitute(Val, '\.', ' ', 'g') . '"'
        else
          let tmp .= ', ' . attr . ' "' . Val . '"'
        endif
      endif
    endfor

    if ! len(tmp)
      let str .= ' []'
    else
      let tmp = strpart(tmp, 2)
      let str .= ' [ ' . tmp . ' ]'
    endif

    " No children quit early
    if len(current.child) == 0 && len(current.value) == 0
      "Place cursor in node with no value or children
      let str .= ' [${cursor}]'
      return str
    endif

    let inner = ''

    " Parent contex text
    if len(current.value) > 0
      let text = current.value[1:-2]
      if dollar_expr
        let text = substitute(text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
        let text = substitute(text, '\${nr}', "\n", 'g')
        let text = substitute(text, '\\\$', '$', 'g')
        " let str = substitute(str, '\$#', text, 'g')
        let inner .= ', text "' . text . '"'
      endif
    endif


    " Has children
    for child in current.child
      if len(child.name) == 0 && len(child.value) > 0
        "  Text node
        let text = child.value[1:-2]
        if dollar_expr
          let text = substitute(text, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
          let text = substitute(text, '\${nr}', "\n", 'g')
          let text = substitute(text, '\\\$', '$', 'g')
        endif
        let inner .= ', text "' . text . '"'
      else
        " Other nodes
        let inner .= ', ' . emmet#toString(child, type, inline, filters, 0, indent)
      endif
    endfor

    let inner = substitute(inner, "\n", "\n" . escape(indent, '\'), 'g')
    let inner = substitute(inner, "\n" . escape(indent, '\') . '$', '', 'g')
    let inner = strpart(inner, 2)

    let inner = substitute(inner, '  ', '', 'g')

    if ! len(inner)
      let str .= ' []'
    else
      let str .= ' [ ' . inner . ' ]'
    endif

  else
    let str = current.value[1:-2]
    if dollar_expr
      let str = substitute(str, '\%(\\\)\@\<!\(\$\+\)\([^{#]\|$\)', '\=printf("%0".len(submatch(1))."d", itemno+1).submatch(2)', 'g')
      let str = substitute(str, '\${nr}', "\n", 'g')
      let str = substitute(str, '\\\$', '$', 'g')
    endif
  endif

  let str .= "\n"
  return str
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

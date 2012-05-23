function! zencoding#css#findTokens(str)
  return substitute(a:str, '^.*[;{]\s*', '', '')
endfunction

function! zencoding#css#parseIntoTree(abbr, type)
  let abbr = a:abbr
  let type = a:type

  let settings = zencoding#getSettings()

  if has_key(settings[type], 'indentation')
    let indent = settings[type].indentation
  else
    let indent = settings.indentation
  endif

  let root = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0 }

  let tag_name = abbr
  if tag_name =~ '.!$'
    let tag_name = tag_name[:-2]
    let important = 1
  endif
  " make default node
  let current = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'pos': 0, 'important': 0 }
  let current.name = tag_name

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
  let current.pos = 0
  call add(root.child, current)
  return root
endfunction

function! zencoding#css#toString(settings, current, type, inline, filters, itemno, indent)
  return ''
endfunction

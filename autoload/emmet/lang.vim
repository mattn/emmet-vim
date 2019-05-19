let s:exists = {}
function! emmet#lang#exists(type) abort
  if len(a:type) == 0
    return 0
  elseif has_key(s:exists, a:type)
    return s:exists[a:type]
  endif
  let s:exists[a:type] = len(globpath(&rtp, 'autoload/emmet/lang/'.a:type.'.vim')) > 0
  return s:exists[a:type]
endfunction

function! emmet#lang#type(type) abort
  let type = a:type
  let base = type
  let settings = emmet#getSettings()
  while base != ''
    for b in split(base, '\.')
      if emmet#lang#exists(b)
        return b
      endif
      if has_key(settings, b) && has_key(settings[b], 'extends')
        let base = settings[b].extends
        break
      else
        let base = ''
      endif
    endfor
  endwhile
  return 'html'
endfunction

" get all extends for a type recursively
function! emmet#lang#getExtends(type) abort
  let settings = emmet#getSettings()

  if !has_key(settings[a:type], 'extends')
    return []
  endif

  let extends = settings[a:type].extends
  if type(extends) ==# 1
    let tmp = split(extends, '\s*,\s*')
    unlet! extends
    let extends = tmp
  endif

  for ext in extends
    let extends = extends + emmet#lang#getExtends(ext)
  endfor

  return extends
endfunction

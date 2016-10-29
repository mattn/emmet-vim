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
    if emmet#lang#exists(base)
      return base
    endif
    if !has_key(settings[base], 'extends')
      break
    endif
    let base = settings[base].extends
  endwhile
  return 'html'
endfunction

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
  let l:type = a:type
  let l:base = l:type
  let l:settings = emmet#getSettings()
  while l:base != ''
    for l:b in split(l:base, '\.')
      if emmet#lang#exists(l:b)
        return l:b
      endif
      if has_key(l:settings, l:b) && has_key(l:settings[l:b], 'extends')
        let l:base = l:settings[l:b].extends
        break
      else
        let l:base = ''
      endif
    endfor
  endwhile
  return 'html'
endfunction

" get all extends for a type recursively
function! emmet#lang#getExtends(type) abort
  let l:settings = emmet#getSettings()

  if !has_key(l:settings[a:type], 'extends')
    return []
  endif

  let l:extends = l:settings[a:type].extends
  if type(l:extends) ==# 1
    let l:tmp = split(l:extends, '\s*,\s*')
    unlet! l:extends
    let l:extends = l:tmp
  endif

  for l:ext in l:extends
    let l:extends = l:extends + emmet#lang#getExtends(l:ext)
  endfor

  return l:extends
endfunction

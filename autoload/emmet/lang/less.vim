function! emmet#lang#less#findTokens(str)
  return emmet#lang#html#findTokens(a:str)
endfunction

function! emmet#lang#less#parseIntoTree(abbr, type)
  return emmet#lang#scss#parseIntoTree(a:abbr, a:type)
endfunction

function! emmet#lang#less#toString(settings, current, type, inline, filters, itemno, indent)
  return emmet#lang#scss#toString(a:settings, a:current, a:type, a:inline, a:filters, a:itemno, a:indent)
endfunction

function! emmet#lang#less#imageSize()
  call emmet#lang#css#imageSize()
endfunction

function! emmet#lang#less#encodeImage()
  return emmet#lang#css#encodeImage()
endfunction

function! emmet#lang#less#parseTag(tag)
  return emmet#lang#css#parseTag(a:tag)
endfunction

function! emmet#lang#less#toggleComment()
  call emmet#lang#css#toggleComment()
endfunction

function! emmet#lang#less#balanceTag(flag) range
  call emmet#lang#scss#balanceTag(a:flag)
endfunction

function! emmet#lang#less#moveNextPrevItem(flag)
  return emmet#lang#less#moveNextPrev(a:flag)
endfunction

function! emmet#lang#less#moveNextPrev(flag)
  call emmet#lang#scss#moveNextPrev(a:flag)
endfunction

function! emmet#lang#less#splitJoinTag()
  call emmet#lang#css#splitJoinTag()
endfunction

function! emmet#lang#less#removeTag()
  call emmet#lang#css#removeTag()
endfunction

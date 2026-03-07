scriptencoding utf-8

function! emmet#lorem#ja#expand(command) abort
  let l:wcount = matchstr(a:command, '^\%(lorem\|lipsum\)\(\d*\)}$', '\1', '')
  let l:wcount = l:wcount > 0 ? l:wcount : 30

  let l:url = "http://www.aozora.gr.jp/cards/000081/files/470_15407.html"
  let l:content = emmet#util#cache(l:url)
  if len(l:content) == 0
    let l:content = emmet#util#getContentFromURL(l:url)
    let l:content = matchstr(l:content, '<div[^>]*>\zs.\{-}</div>')
    let l:content = substitute(l:content, '[　\r]', '', 'g')
    let l:content = substitute(l:content, '<br[^>]*>', "\n", 'g')
    let l:content = substitute(l:content, '<[^>]\+>', '', 'g')
    let l:content = join(filter(split(l:content, "\n"), 'len(v:val)>0'), "\n")
    call emmet#util#cache(l:url, l:content)
  endif

  let l:content = substitute(l:content, "、\n", "、", "g")
  let l:clines = split(l:content, '\n')
  let l:lines = filter(l:clines, 'len(substitute(v:val,".",".","g"))<=l:wcount')
  if len(l:lines) == 0
    let l:lines = l:clines
  endif
  let l:r = emmet#util#rand()
  return l:lines[l:r % len(l:lines)]
endfunction

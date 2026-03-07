"==============================================================================
" region utils
"==============================================================================
" deleteContent : delete content in region
"   if region make from between '<foo>' and '</foo>'
"   --------------------
"   begin:<foo>
"   </foo>:end
"   --------------------
"   this function make the content as following
"   --------------------
"   begin::end
"   --------------------
function! emmet#util#deleteContent(region) abort
  let l:lines = getline(a:region[0][0], a:region[1][0])
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
  silent! exe 'delete '.(a:region[1][0] - a:region[0][0])
  call setline(line('.'), l:lines[0][:a:region[0][1]-2] . l:lines[-1][a:region[1][1]])
endfunction

" change_content : change content in region
"   if region make from between '<foo>' and '</foo>'
"   --------------------
"   begin:<foo>
"   </foo>:end
"   --------------------
"   and content is
"   --------------------
"   foo
"   bar
"   baz
"   --------------------
"   this function make the content as following
"   --------------------
"   begin:foo
"   bar
"   baz:end
"   --------------------
function! emmet#util#setContent(region, content) abort
  let l:newlines = split(a:content, '\n', 1)
  let l:oldlines = getline(a:region[0][0], a:region[1][0])
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
  silent! exe 'delete '.(a:region[1][0] - a:region[0][0])
  if len(l:newlines) == 0
    let l:tmp = ''
    if a:region[0][1] > 1
      let l:tmp = l:oldlines[0][:a:region[0][1]-2]
    endif
    if a:region[1][1] >= 1
      let l:tmp .= l:oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), l:tmp)
  elseif len(l:newlines) == 1
    if a:region[0][1] > 1
      let l:newlines[0] = l:oldlines[0][:a:region[0][1]-2] . l:newlines[0]
    endif
    if a:region[1][1] >= 1
      let l:newlines[0] .= l:oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), l:newlines[0])
  else
    if a:region[0][1] > 1
      let l:newlines[0] = l:oldlines[0][:a:region[0][1]-2] . l:newlines[0]
    endif
    if a:region[1][1] >= 1
      let l:newlines[-1] .= l:oldlines[-1][a:region[1][1]:]
    endif
    call setline(line('.'), l:newlines[0])
    call append(line('.'), l:newlines[1:])
  endif
endfunction

" select_region : select region
"   this function make a selection of region
function! emmet#util#selectRegion(region) abort
  call setpos('.', [0, a:region[1][0], a:region[1][1], 0])
  normal! v
  call setpos('.', [0, a:region[0][0], a:region[0][1], 0])
endfunction

" point_in_region : check point is in the region
"   this function return 0 or 1
function! emmet#util#pointInRegion(point, region) abort
  if !emmet#util#regionIsValid(a:region) | return 0 | endif
  if a:region[0][0] > a:point[0] | return 0 | endif
  if a:region[1][0] < a:point[0] | return 0 | endif
  if a:region[0][0] == a:point[0] && a:region[0][1] > a:point[1] | return 0 | endif
  if a:region[1][0] == a:point[0] && a:region[1][1] < a:point[1] | return 0 | endif
  return 1
endfunction

" cursor_in_region : check cursor is in the region
"   this function return 0 or 1
function! emmet#util#cursorInRegion(region) abort
  if !emmet#util#regionIsValid(a:region) | return 0 | endif
  let l:cur = emmet#util#getcurpos()[1:2]
  return emmet#util#pointInRegion(l:cur, a:region)
endfunction

" region_is_valid : check region is valid
"   this function return 0 or 1
function! emmet#util#regionIsValid(region) abort
  if a:region[0][0] == 0 || a:region[1][0] == 0 | return 0 | endif
  return 1
endfunction

" search_region : make region from pattern which is composing start/end
"   this function return array of position
function! emmet#util#searchRegion(start, end) abort
  let l:b = searchpairpos(a:start, '', a:end, 'bcnW')
  if l:b == [0, 0]
    return [searchpairpos(a:start, '', a:end, 'bnW'), searchpairpos(a:start, '\%#', a:end, 'nW')]
  else
    return [l:b, searchpairpos(a:start, '', a:end. '', 'nW')]
  endif
endfunction

" get_content : get content in region
"   this function return string in region
function! emmet#util#getContent(region) abort
  if !emmet#util#regionIsValid(a:region)
    return ''
  endif
  let l:lines = getline(a:region[0][0], a:region[1][0])
  if a:region[0][0] == a:region[1][0]
    let l:lines[0] = l:lines[0][a:region[0][1]-1:a:region[1][1]-1]
  else
    let l:lines[0] = l:lines[0][a:region[0][1]-1:]
    let l:lines[-1] = l:lines[-1][:a:region[1][1]-1]
  endif
  return join(l:lines, "\n")
endfunction

" region_in_region : check region is in the region
"   this function return 0 or 1
function! emmet#util#regionInRegion(outer, inner) abort
  if !emmet#util#regionIsValid(a:inner) || !emmet#util#regionIsValid(a:outer)
    return 0
  endif
  return emmet#util#pointInRegion(a:inner[0], a:outer) && emmet#util#pointInRegion(a:inner[1], a:outer)
endfunction

" get_visualblock : get region of visual block
"   this function return region of visual block
function! emmet#util#getVisualBlock() abort
  return [[line("'<"), col("'<")], [line("'>"), col("'>")]]
endfunction

"==============================================================================
" html utils
"==============================================================================
function! emmet#util#getContentFromURL(url) abort
  let l:res = system(printf('%s -i %s', g:emmet_curl_command, shellescape(substitute(a:url, '#.*', '', ''))))
  while l:res =~# '^HTTP/1.\d 3' || l:res =~# '^HTTP/1\.\d 200 Connection established' || l:res =~# '^HTTP/1\.\d 100 Continue'
    let l:pos = stridx(l:res, "\r\n\r\n")
    if l:pos != -1
      let l:res = strpart(l:res, l:pos+4)
    else
      let l:pos = stridx(l:res, "\n\n")
      let l:res = strpart(l:res, l:pos+2)
    endif
  endwhile
  let l:pos = stridx(l:res, "\r\n\r\n")
  if l:pos != -1
    let l:content = strpart(l:res, l:pos+4)
  else
    let l:pos = stridx(l:res, "\n\n")
    let l:content = strpart(l:res, l:pos+2)
  endif
  let l:header = l:res[:l:pos-1]
  let l:charset = matchstr(l:content, '<meta[^>]\+content=["''][^;"'']\+;\s*charset=\zs[^;"'']\+\ze["''][^>]*>')
  if len(l:charset) == 0
    let l:charset = matchstr(l:content, '<meta\s\+charset=["'']\?\zs[^"'']\+\ze["'']\?[^>]*>')
  endif
  if len(l:charset) == 0
    let l:charset = matchstr(l:header, '\nContent-Type:.* charset=[''"]\?\zs[^''";\n]\+\ze')
  endif
  if len(l:charset) == 0
    let l:s1 = len(split(l:content, '?'))
    let l:utf8 = iconv(l:content, 'utf-8', &encoding)
    let l:s2 = len(split(l:utf8, '?'))
    return (l:s2 == l:s1 || l:s2 >= l:s1 * 2) ? l:utf8 : l:content
  endif
  return iconv(l:content, l:charset, &encoding)
endfunction

function! emmet#util#getTextFromHTML(buf) abort
  let l:threshold_len = 100
  let l:threshold_per = 0.1
  let l:buf = a:buf

  let l:buf = strpart(l:buf, stridx(l:buf, '</head>'))
  let l:buf = substitute(l:buf, '<style[^>]*>.\{-}</style>', '', 'g')
  let l:buf = substitute(l:buf, '<script[^>]*>.\{-}</script>', '', 'g')
  let l:res = ''
  let l:max = 0
  let l:mx = '\(<td[^>]\{-}>\)\|\(<\/td>\)\|\(<div[^>]\{-}>\)\|\(<\/div>\)'
  let l:m = split(l:buf, l:mx)
  for l:str in l:m
    let l:c = split(l:str, '<[^>]*?>')
    let l:str = substitute(l:str, '<[^>]\{-}>', ' ', 'g')
    let l:str = substitute(l:str, '&gt;', '>', 'g')
    let l:str = substitute(l:str, '&lt;', '<', 'g')
    let l:str = substitute(l:str, '&quot;', '"', 'g')
    let l:str = substitute(l:str, '&apos;', '''', 'g')
    let l:str = substitute(l:str, '&nbsp;', ' ', 'g')
    let l:str = substitute(l:str, '&yen;', '\&#65509;', 'g')
    let l:str = substitute(l:str, '&amp;', '\&', 'g')
    let l:str = substitute(l:str, '^\s*\(.*\)\s*$', '\1', '')
    let l:str = substitute(l:str, '\s\+', ' ', 'g')
    let l:l = len(l:str)
    if l:l > l:threshold_len
      let l:per = (l:l+0.0) / len(l:c)
      if l:max < l:l && l:per > l:threshold_per
        let l:max = l:l
        let l:res = l:str
      endif
    endif
  endfor
  let l:res = substitute(l:res, '^\s*\(.*\)\s*$', '\1', 'g')
  return l:res
endfunction

function! emmet#util#getImageSize(fn) abort
  let l:fn = a:fn

  if emmet#util#isImageMagickInstalled()
    return emmet#util#imageSizeWithImageMagick(l:fn)
  endif

  if filereadable(l:fn)
    let l:hex = substitute(system('xxd -p '.shellescape(l:fn)), '\n', '', 'g')
  else
    if l:fn !~# '^\w\+://'
      let l:path = fnamemodify(expand('%'), ':p:gs?\\?/?')
      if has('win32') || has('win64') |
        let l:path = tolower(l:path)
      endif
      for l:k in keys(g:emmet_docroot)
        let l:root = fnamemodify(l:k, ':p:gs?\\?/?')
        if has('win32') || has('win64') |
          let l:root = tolower(l:root)
        endif
        if stridx(l:path, l:root) == 0
          let l:v = g:emmet_docroot[l:k]
          let l:fn = (len(l:v) == 0 ? l:k : l:v) . l:fn
          break
        endif
      endfor
    endif
    let l:hex = substitute(system(g:emmet_curl_command.' '.shellescape(l:fn).' | xxd -p'), '\n', '', 'g')
  endif

  let [l:width, l:height] = [-1, -1]
  if l:hex =~# '^89504e470d0a1a0a'
    let l:width = eval('0x'.l:hex[32:39])
    let l:height = eval('0x'.l:hex[40:47])
  endif
  if l:hex =~# '^ffd8'
    let l:pos = 4
    while l:pos < len(l:hex)
      let l:bs = l:hex[l:pos+0:l:pos+3]
      let l:pos += 4
      if l:bs ==# 'ffc0' || l:bs ==# 'ffc2'
        let l:pos += 6
        let l:height = eval('0x'.l:hex[l:pos+0:l:pos+1])*256 + eval('0x'.l:hex[l:pos+2:l:pos+3])
        let l:pos += 4
        let l:width = eval('0x'.l:hex[l:pos+0:l:pos+1])*256 + eval('0x'.l:hex[l:pos+2:l:pos+3])
        break
      elseif l:bs =~# 'ffd[9a]'
        break
      elseif l:bs =~# 'ff\(e[0-9a-e]\|fe\|db\|dd\|c4\)'
        let l:pos += (eval('0x'.l:hex[l:pos+0:l:pos+1])*256 + eval('0x'.l:hex[l:pos+2:l:pos+3])) * 2
      endif
    endwhile
  endif
  if l:hex =~# '^47494638'
    let l:width = eval('0x'.l:hex[14:15].l:hex[12:13])
    let l:height = eval('0x'.l:hex[18:19].l:hex[16:17])
  endif

  return [l:width, l:height]
endfunction

function! emmet#util#imageSizeWithImageMagick(fn) abort
  let l:img_info = system('identify -format "%wx%h" '.shellescape(a:fn))
  let l:img_size = split(substitute(l:img_info, '\n', '', ''), 'x')
  if len(l:img_size) != 2
    return [-1, -1]
  endif
  return l:img_size
endfunction

function! emmet#util#isImageMagickInstalled() abort
  if !get(g:, 'emmet_use_identify', 1)
    return 0
  endif
  return executable('identify')
endfunction

function! s:b64encode(bytes, table, pad)
  let l:b64 = []
  for l:i in range(0, len(a:bytes) - 1, 3)
    let l:n = a:bytes[l:i] * 0x10000
          \ + get(a:bytes, l:i + 1, 0) * 0x100
          \ + get(a:bytes, l:i + 2, 0)
    call add(l:b64, a:table[l:n / 0x40000])
    call add(l:b64, a:table[l:n / 0x1000 % 0x40])
    call add(l:b64, a:table[l:n / 0x40 % 0x40])
    call add(l:b64, a:table[l:n % 0x40])
  endfor
  if len(a:bytes) % 3 == 2
    let l:b64[-1] = a:pad
  elseif len(a:bytes) % 3 == 1
    let l:b64[-1] = a:pad
    let l:b64[-2] = a:pad
  endif
  return l:b64
endfunction

function! emmet#util#imageEncodeDecode(fn, flag) abort
  let l:fn = a:fn

  if filereadable(l:fn)
    let l:hex = substitute(system('xxd -p '.shellescape(l:fn)), '\n', '', 'g')
  else
    if l:fn !~# '^\w\+://'
      let l:path = fnamemodify(expand('%'), ':p:gs?\\?/?')
      if has('win32') || has('win64') |
        let l:path = tolower(l:path)
      endif
      for l:k in keys(g:emmet_docroot)
        let l:root = fnamemodify(l:k, ':p:gs?\\?/?')
        if has('win32') || has('win64') |
          let l:root = tolower(l:root)
        endif
        if stridx(l:path, l:root) == 0
          let l:v = g:emmet_docroot[l:k]
          let l:fn = (len(l:v) == 0 ? l:k : l:v) . l:fn
          break
        endif
      endfor
    endif
    let l:hex = substitute(system(g:emmet_curl_command.' '.shellescape(l:fn).' | xxd -p'), '\n', '', 'g')
  endif

  let l:bin = map(split(l:hex, '..\zs'), 'eval("0x" . v:val)')
  let l:table = split('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', '\zs')
  let l:ret = 'data:image/'
  if l:hex =~# '^89504e470d0a1a0a'
    let l:ret .= 'png'
  elseif l:hex =~# '^ffd8'
    let l:ret .= 'jpeg'
  elseif l:hex =~# '^47494638'
    let l:ret .= 'gif'
  elseif l:hex =~# '^00000020667479706176696600000000'
    let l:ret .= 'avif'
  else
    let l:ret .= 'unknown'
  endif
  return l:ret . ';base64,' . join(s:b64encode(l:bin, l:table, '='), '')
endfunction

function! emmet#util#unique(arr) abort
  let l:m = {}
  let l:r = []
  for l:i in a:arr
    if !has_key(l:m, l:i)
      let l:m[l:i] = 1
      call add(l:r, l:i)
    endif
  endfor
  return l:r
endfunction

let s:seed = localtime()
function! emmet#util#srand(seed) abort
  let s:seed = a:seed
endfunction

function! emmet#util#rand() abort
  let s:seed = s:seed * 214013 + 2531011
  return (s:seed < 0 ? s:seed - 0x80000000 : s:seed) / 0x10000 % 0x8000
endfunction

function! emmet#util#cache(name, ...) abort
  let l:content = get(a:000, 0, '')
  let l:dir = expand('~/.emmet/cache')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p', 0700)
  endif
  let l:file = l:dir . '/' . substitute(a:name, '\W', '_', 'g')
  if len(l:content) == 0
    if !filereadable(l:file)
      return ''
    endif
	return join(readfile(l:file), "\n")
  endif
  call writefile(split(l:content, "\n"), l:file)
endfunction

function! emmet#util#getcurpos() abort
  let l:pos = getpos('.')
  if mode(0) ==# 'i' && l:pos[2] > 0
    let l:pos[2] -=1
  endif
  return l:pos
endfunction

function! emmet#util#closePopup() abort
  return pumvisible() ? "\<c-e>" : ''
endfunction

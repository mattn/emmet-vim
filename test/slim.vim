let s:suite = themis#suite('slim')
let s:assert = themis#helper('assert')

let s:emmet = themis#helper('emmet')

function! s:suite.__setup() abort
  call s:emmet.setup()
endfunction

function! s:suite.__expand_abbreviation()
  let expand = themis#suite('expand abbreviation')

  function! expand.complex() abort
    call s:assert.equals(s:emmet.expand_word('div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}', 'slim'), "div\n  p\n  ul id=\"foo\"\n    li class=\"bar1\" foo=\"bar\" bar=\"baz\"\n      | baz\n    li class=\"bar2\" foo=\"bar\" bar=\"baz\"\n      | baz\n    li class=\"bar3\" foo=\"bar\" bar=\"baz\"\n      | baz\n")
  endfunction

  function! expand.with_slim_filter() abort
    call s:assert.equals(s:emmet.expand_word('div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}|slim', 'slim'), "div\n  p\n  ul id=\"foo\"\n    li class=\"bar1\" foo=\"bar\" bar=\"baz\"\n      | baz\n    li class=\"bar2\" foo=\"bar\" bar=\"baz\"\n      | baz\n    li class=\"bar3\" foo=\"bar\" bar=\"baz\"\n      | baz\n")
  endfunction

  function! expand.a_multiplier() abort
    call s:assert.equals(s:emmet.expand_word('a*3|slim', 'slim'), "a href=\"\"\na href=\"\"\na href=\"\"\n")
  endfunction

  function! expand.class_with_text() abort
    call s:assert.equals(s:emmet.expand_word('.content{Hello!}|slim', 'slim'), "div class=\"content\"\n  | Hello!\n")
  endfunction

  function! expand.title_dollar_hash() abort
    call s:assert.equals(s:emmet.expand_word('a[title=$#]{foo}', 'slim'), "a href=\"\" title=\"foo\"\n  | foo\n")
  endfunction
endfunction

function! s:suite.__split_join_tag()
  let split_join = themis#suite('split join tag')

  function! split_join.join() abort
    let res = s:emmet.expand_in_buffer("a\n  | foo$$$$\\<c-y>j$$$$", 'slim', 'a')
    call s:assert.equals(res, 'a')
  endfunction

  function! split_join.split() abort
    let res = s:emmet.expand_in_buffer("a$$$$\\<c-y>j$$$$", 'slim', "a\n  | $$$$")
    call s:assert.equals(res, "a\n  | $$$$")
  endfunction
endfunction

function! s:suite.__toggle_comment()
  let comment = themis#suite('toggle comment')

  function! comment.add() abort
    let res = s:emmet.expand_in_buffer("a href=\"http://www.google.com\"$$$$\\<c-y>/$$$$\n  | hello", 'slim', "/a href=\"http://www.google.com\"\n  | hello")
    call s:assert.equals(res, "/a href=\"http://www.google.com\"\n  | hello")
  endfunction

  function! comment.remove() abort
    let res = s:emmet.expand_in_buffer("/a href=\"http://www.google.com\"$$$$\\<c-y>/$$$$\n  | hello", 'slim', "a href=\"http://www.google.com\"\n  | hello")
    call s:assert.equals(res, "a href=\"http://www.google.com\"\n  | hello")
  endfunction
endfunction

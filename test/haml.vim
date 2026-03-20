let s:suite = themis#suite('haml')
let s:assert = themis#helper('assert')

let s:emmet = themis#helper('emmet')

function! s:suite.__setup() abort
  call s:emmet.setup()
endfunction

function! s:suite.__expand_abbreviation()
  let expand = themis#suite('expand abbreviation')

  function! expand.complex() abort
    call s:assert.equals(s:emmet.expand_word('div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}', 'haml'), "%div\n  %p\n  %ul#foo\n    %li.bar1{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar2{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar3{ :foo => \"bar\", :bar => \"baz\" } baz\n")
  endfunction

  function! expand.with_haml_filter() abort
    call s:assert.equals(s:emmet.expand_word('div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}|haml', 'haml'), "%div\n  %p\n  %ul#foo\n    %li.bar1{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar2{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar3{ :foo => \"bar\", :bar => \"baz\" } baz\n")
  endfunction

  function! expand.a_multiplier() abort
    call s:assert.equals(s:emmet.expand_word('a*3|haml', 'haml'), "%a{ :href => \"\" }\n%a{ :href => \"\" }\n%a{ :href => \"\" }\n")
  endfunction

  function! expand.class_with_text() abort
    call s:assert.equals(s:emmet.expand_word('.content{Hello!}|haml', 'haml'), "%div.content Hello!\n")
  endfunction

  function! expand.title_dollar_hash() abort
    call s:assert.equals(s:emmet.expand_word('a[title=$#]{foo}', 'haml'), "%a{ :href => \"\", :title => \"foo\" } foo\n")
  endfunction
endfunction

function! s:suite.__split_join()
  let split_join = themis#suite('split join')

  function! split_join.join() abort
    let res = s:emmet.expand_in_buffer("%a foo\n  bar$$$$\\<c-y>j$$$$", 'haml', '%a ')
    call s:assert.equals(res, '%a ')
  endfunction

  function! split_join.split() abort
    let res = s:emmet.expand_in_buffer("$$$$\\<c-y>j$$$$%a ", 'haml', '%a $$$$')
    call s:assert.equals(res, '%a $$$$')
  endfunction
endfunction

function! s:suite.__toggle_comment()
  let comment = themis#suite('toggle comment')

  function! comment.add() abort
    let res = s:emmet.expand_in_buffer('%a{ :href => "http://www.google.com"$$$$\<c-y>/$$$$ } hello', 'haml', '-# %a{ :href => "http://www.google.com" } hello')
    call s:assert.equals(res, '-# %a{ :href => "http://www.google.com" } hello')
  endfunction

  function! comment.remove() abort
    let res = s:emmet.expand_in_buffer('-# %a{ :href => "http://www.google.com"$$$$\<c-y>/$$$$ } hello', 'haml', '%a{ :href => "http://www.google.com" } hello')
    call s:assert.equals(res, '%a{ :href => "http://www.google.com" } hello')
  endfunction
endfunction

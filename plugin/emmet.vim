"=============================================================================
" File: emmet.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 06-Aug-2013.
" Version: 0.75
" WebPage: http://github.com/mattn/emmet-vim
" Description: vim plugins for HTML and CSS hi-speed coding.
" SeeAlso: http://emmet.io/
" Usage:
"
"   This is vim script support expanding abbreviation like emmet.
"   ref: http://emmet.io/
"
"   Type abbreviation
"      +-------------------------------------
"      | html:5_
"      +-------------------------------------
"   "_" is a cursor position. and type "<c-y>," (Ctrl+y and Comma)
"   NOTE: Don't worry about key map. you can change it easily.
"      +-------------------------------------
"      | <!DOCTYPE HTML>
"      | <html lang="en">
"      | <head>
"      |     <title></title>
"      |     <meta charset="UTF-8">
"      | </head>
"      | <body>
"      |      _
"      | </body>
"      | </html>
"      +-------------------------------------
"   Type following
"      +-------------------------------------
"      | div#foo$*2>div.bar
"      +-------------------------------------
"   And type "<c-y>,"
"      +-------------------------------------
"      |<div id="foo1">
"      |    <div class="bar">_</div>
"      |</div>
"      |<div id="foo2">
"      |    <div class="bar"></div>
"      |</div>
"      +-------------------------------------
"
" Tips:
"
"   You can customize behavior of expanding with overriding config.
"   This configuration will be marged at loading plugin.
"
"     let g:user_emmet_settings = {
"     \  'indentation' : '  ',
"     \  'perl' : {
"     \    'aliases' : {
"     \      'req' : 'require '
"     \    },
"     \    'snippets' : {
"     \      'use' : "use strict\nuse warnings\n\n",
"     \      'warn' : "warn \"|\";",
"     \    }
"     \  }
"     \}
"
"   You can set language attribute in html using 'emmet_settings.lang'.
"
" GetLatestVimScripts: 2981 1 :AutoInstall: emmet.vim
" script type: plugin

if &cp || v:version < 702 || (exists('g:loaded_emmet_vim') && g:loaded_emmet_vim)
  finish
endif
let g:loaded_emmet_vim = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:emmet_debug')
  let g:emmet_debug = 0
endif

if !exists('g:emmet_curl_command')
  let g:emmet_curl_command = 'curl -s -L -A Mozilla/5.0'
endif

if exists('g:use_emmet_complete_tag') && g:use_emmet_complete_tag
  setlocal omnifunc=emmet#CompleteTag
endif

if !exists('g:user_emmet_leader_key')
  let g:user_emmet_leader_key = '<c-y>'
endif

function! s:install_plugin_i()
  for item in [
  \ {'mode': 'i', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandAbbr', 'func': '<c-g>u<esc>:call emmet#expandAbbr(0,"")<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_expandword_key', 'key': ';', 'plug': 'EmmetExpandWord', 'func': '<c-g>u<esc>:call emmet#expandAbbr(1,"")<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInwardInsert', 'func': '<esc>:call emmet#balanceTag(1)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutwardInsert', 'func': '<esc>:call emmet#balanceTag(-1)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_next_key', 'key': 'n', 'plug': 'EmmetNext', 'func': '<esc>:call emmet#moveNextPrev(0)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_prev_key', 'key': 'N', 'plug': 'EmmetPrev', 'func': '<esc>:call emmet#moveNextPrev(1)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_imagesize_key', 'key': 'i', 'plug': 'EmmetImageSize', 'func': '<esc>:call emmet#imageSize()<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_togglecomment_key', 'key': '/', 'plug': 'EmmetToggleComment', 'func': '<esc>:call emmet#toggleComment()<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_splitjointag_key', 'key': 'j', 'plug': 'EmmetSplitJoinTagInsert', 'func': '<esc>:call emmet#splitJoinTag()<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_removetag_key', 'key': 'k', 'plug': 'EmmetRemoveTag', 'func': '<esc>:call emmet#removeTag()<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_anchorizeurl_key', 'key': 'a', 'plug': 'EmmetAnchorizeURL', 'func': '<esc>:call emmet#anchorizeURL(0)<cr>a'},
  \ {'mode': 'i', 'var': 'user_emmet_anchorizesummary_key', 'key': 'A', 'plug': 'EmmetAnchorizeSummary', 'func': '<esc>:call emmet#anchorizeURL(1)<cr>a'},
  \]

    if !hasmapto('<plug>'.item.plug, item.mode)
      exe item.mode . 'noremap <plug>' . item.plug . ' ' . item.func
    endif
    if !exists('g:' . item.var)
    endif
    if exists('g:' . item.var)
      let key = eval('g:' . item.var)
    else
      let key = g:user_emmet_leader_key . item.key
    endif
    if len(maparg(key, item.mode)) == 0
      exe item.mode . 'map <unique> ' . key . ' <plug>' . item.plug
    endif
  endfor
endfunction

function! s:install_plugin_n()
  for item in [
  \ {'mode': 'n', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandNormal', 'func': ':call emmet#expandAbbr(3,"")<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_expandword_key', 'key': ',', 'plug': 'EmmetExpandWord', 'func': ':call emmet#expandAbbr(1,"")<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInwardNormal', 'func': ':call emmet#balanceTag(1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutwardNormal', 'func': ':call emmet#balanceTag(-1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_next_key', 'key': 'n', 'plug': 'EmmetNext', 'func': ':call emmet#moveNextPrev(0)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_prev_key', 'key': 'N', 'plug': 'EmmetPrev', 'func': ':call emmet#moveNextPrev(1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_imagesize_key', 'key': 'i', 'plug': 'EmmetImageSize', 'func': ':call emmet#imageSize()<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_togglecomment_key', 'key': '/', 'plug': 'EmmetToggleComment', 'func': ':call emmet#toggleComment()<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_splitjointag_key', 'key': 'j', 'plug': 'EmmetSplitJoinTagNormal', 'func': ':call emmet#splitJoinTag()<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_removetag_key', 'key': 'k', 'plug': 'EmmetRemoveTag', 'func': ':call emmet#removeTag()<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_anchorizeurl_key', 'key': 'a', 'plug': 'EmmetAnchorizeURL', 'func': ':call emmet#anchorizeURL(0)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_anchorizesummary_key', 'key': 'A', 'plug': 'EmmetAnchorizeSummary', 'func': ':call emmet#anchorizeURL(1)<cr>'},
  \]

    if !hasmapto('<plug>'.item.plug, item.mode)
      exe item.mode . 'noremap <plug>' . item.plug . ' ' . item.func
    endif
    if !exists('g:' . item.var)
    endif
    if exists('g:' . item.var)
      let key = eval('g:' . item.var)
    else
      let key = g:user_emmet_leader_key . item.key
    endif
    if len(maparg(key, item.mode)) == 0
      exe item.mode . 'map <unique> ' . key . ' <plug>' . item.plug
    endif
  endfor
endfunction

function! s:install_plugin_v()
  for item in [
  \ {'mode': 'v', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandVisual', 'func': ':call emmet#expandAbbr(2,"")<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInwardVisual', 'func': ':call emmet#balanceTag(2)<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutwardVisual', 'func': ':call emmet#balanceTag(-2)<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_mergelines_key', 'key': 'm', 'plug': 'EmmetMergeLines', 'func': ':call emmet#mergeLines()<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_codepretty_key', 'key': 'c', 'plug': 'EmmetCodePretty', 'func': ':call emmet#codePretty()<cr>'},
  \]

    if !hasmapto('<plug>'.item.plug, item.mode)
      exe item.mode . 'noremap <plug>' . item.plug . ' ' . item.func
    endif
    if !exists('g:' . item.var)
    endif
    if exists('g:' . item.var)
      let key = eval('g:' . item.var)
    else
      let key = g:user_emmet_leader_key . item.key
    endif
    if len(maparg(key, item.mode)) == 0
      exe item.mode . 'map <unique> ' . key . ' <plug>' . item.plug
    endif
  endfor
endfunction


if exists('g:user_emmet_mode')
    let imode = matchstr(g:user_emmet_mode, '[ai]')
    let nmode = matchstr(g:user_emmet_mode, '[an]')
    let vmode = matchstr(g:user_emmet_mode, '[av]')

    if !empty(imode)
        call s:install_plugin_i()
    endif

    if !empty(nmode)
        call s:install_plugin_n()
    endif

    if !empty(vmode)
        call s:install_plugin_v()
    endif
else
    call s:install_plugin_i()
    call s:install_plugin_n()
    call s:install_plugin_v()
endif


delfunction s:install_plugin_i
delfunction s:install_plugin_n
delfunction s:install_plugin_v

command! -nargs=1 Emmet call emmet#expandAbbr(4, <q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:

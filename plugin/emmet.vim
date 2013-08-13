"=============================================================================
" File: emmet.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 13-Aug-2013.
" Version: 0.82
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

function! s:install_plugin(mode)
  for item in [
  \ {'mode': 'i', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandAbbr', 'func': '<c-g>u<esc>:call emmet#expandAbbr(0,"")<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandAbbr', 'func': ':call emmet#expandAbbr(3,"")<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_expandabbr_key', 'key': ',', 'plug': 'EmmetExpandAbbr', 'func': ':call emmet#expandAbbr(2,"")<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_expandword_key', 'key': ';', 'plug': 'EmmetExpandWord', 'func': '<c-g>u<esc>:call emmet#expandAbbr(1,"")<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_expandword_key', 'key': ';', 'plug': 'EmmetExpandWord', 'func': ':call emmet#expandAbbr(1,"")<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInward', 'func': '<esc>:call emmet#balanceTag(1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInward', 'func': ':call emmet#balanceTag(1)<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_balancetaginward_key', 'key': 'd', 'plug': 'EmmetBalanceTagInward', 'func': ':call emmet#balanceTag(2)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutward', 'func': '<esc>:call emmet#balanceTag(-1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutward', 'func': ':call emmet#balanceTag(-1)<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_balancetagoutward_key', 'key': 'D', 'plug': 'EmmetBalanceTagOutward', 'func': ':call emmet#balanceTag(-2)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_next_key', 'key': 'n', 'plug': 'EmmetMoveNext', 'func': '<esc>:call emmet#moveNextPrev(0)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_next_key', 'key': 'n', 'plug': 'EmmetMoveNext', 'func': ':call emmet#moveNextPrev(0)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_prev_key', 'key': 'N', 'plug': 'EmmetMovePrev', 'func': '<esc>:call emmet#moveNextPrev(1)<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_prev_key', 'key': 'N', 'plug': 'EmmetMovePrev', 'func': ':call emmet#moveNextPrev(1)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_imagesize_key', 'key': 'i', 'plug': 'EmmetImageSize', 'func': '<esc>:call emmet#imageSize()<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_imagesize_key', 'key': 'i', 'plug': 'EmmetImageSize', 'func': ':call emmet#imageSize()<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_togglecomment_key', 'key': '/', 'plug': 'EmmetToggleComment', 'func': '<esc>:call emmet#toggleComment()<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_togglecomment_key', 'key': '/', 'plug': 'EmmetToggleComment', 'func': ':call emmet#toggleComment()<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_splitjointag_key', 'key': 'j', 'plug': 'EmmetSplitJoinTag', 'func': '<esc>:call emmet#splitJoinTag()<cr>'},
  \ {'mode': 'n', 'var': 'user_emmet_splitjointag_key', 'key': 'j', 'plug': 'EmmetSplitJoinTag', 'func': ':call emmet#splitJoinTag()<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_removetag_key', 'key': 'k', 'plug': 'EmmetRemoveTag', 'func': '<esc>:call emmet#removeTag()<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_removetag_key', 'key': 'k', 'plug': 'EmmetRemoveTag', 'func': ':call emmet#removeTag()<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_anchorizeurl_key', 'key': 'a', 'plug': 'EmmetAnchorizeURL', 'func': '<esc>:call emmet#anchorizeURL(0)<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_anchorizeurl_key', 'key': 'a', 'plug': 'EmmetAnchorizeURL', 'func': ':call emmet#anchorizeURL(0)<cr>'},
  \ {'mode': 'i', 'var': 'user_emmet_anchorizesummary_key', 'key': 'A', 'plug': 'EmmetAnchorizeSummary', 'func': '<esc>:call emmet#anchorizeURL(1)<cr>a'},
  \ {'mode': 'n', 'var': 'user_emmet_anchorizesummary_key', 'key': 'A', 'plug': 'EmmetAnchorizeSummary', 'func': ':call emmet#anchorizeURL(1)<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_mergelines_key', 'key': 'm', 'plug': 'EmmetMergeLines', 'func': ':call emmet#mergeLines()<cr>'},
  \ {'mode': 'v', 'var': 'user_emmet_codepretty_key', 'key': 'c', 'plug': 'EmmetCodePretty', 'func': ':call emmet#codePretty()<cr>'},
  \]

    if a:mode != 'a' && stridx(a:mode, item.mode) == -1
      continue
    endif
    if !hasmapto('<plug>(' . item.plug . ')', item.mode)
      exe item.mode . 'noremap <plug>(' . item.plug . ') ' . item.func
    endif
    if exists('g:' . item.var)
      let key = eval('g:' . item.var)
    else
      let key = g:user_emmet_leader_key . item.key
    endif
    if len(maparg(key, item.mode)) == 0
      exe item.mode . 'map <unique> ' . key . ' <plug>(' . item.plug . ')'
    endif
  endfor
endfunction

if exists('g:user_emmet_mode')
  call s:install_plugin(g:user_emmet_mode)
else
  call s:install_plugin('a')
endif

delfunction s:install_plugin

command! -nargs=1 Emmet call emmet#expandAbbr(4, <q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:

"=============================================================================
" File: zencoding.vim
" Author: Yasuhiro Matsumoto <mattn.jp@gmail.com>
" Last Change: 23-Feb-2010.
" Version: 0.22
" WebPage: http://github.com/mattn/zencoding-vim
" Description: vim plugins for HTML and CSS hi-speed coding.
" SeeAlso: http://code.google.com/p/zen-coding/
" Usage:
"
"   This is vim script support expanding abbreviation like zen-coding.
"   ref: http://code.google.com/p/zen-coding/
"   
"   Type abbreviation
"      +-------------------------------------
"      | html:5_
"      +-------------------------------------
"   "_" is a cursor position. and type "<c-z>,"
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
"   And type "<c-z>,"
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
"     let g:user_zen_settings = {
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
"   You can set language attribute in html using zen_settings['lang'].
"
" GetLatestVimScripts: 2981 1 :AutoInstall: zencoding.vim
" script type: plugin

if exists('g:use_zen_complete_tag') && g:use_zen_complete_tag
  setlocal completefunc=ZenCompleteTag
endif

inoremap <plug>ZenCodingExpandAbbr   <esc>:call <sid>zen_expand(0)<cr>a
inoremap <plug>ZenCodingExpandWord   <esc>:call <sid>zen_expand(1)<cr>a
vnoremap <plug>ZenCodingExpandVisual :call <sid>zen_expand(2)<cr>

if !exists('g:user_zen_expandword_key')
  let g:user_zen_expandword_key = '<c-z>.'
endif
if !hasmapto(g:user_zen_expandword_key, 'i')
  exe "imap <buffer> " . g:user_zen_expandword_key . " <plug>ZenCodingExpandWord"
endif
if !exists('g:user_zen_expandabbr_key')
  let g:user_zen_expandabbr_key = '<c-z>,'
endif
if !hasmapto(g:user_zen_expandabbr_key, 'i')
  exe "imap <buffer> " . g:user_zen_expandabbr_key . " <plug>ZenCodingExpandAbbr"
endif
if !hasmapto(g:user_zen_expandabbr_key, 'v')
  exe "vmap <buffer> " . g:user_zen_expandabbr_key . " <plug>ZenCodingExpandVisual"
endif

if exists('s:zen_settings')
  finish
endif

unlet! s:zen_settings
let s:zen_settings = {
\    'indentation': "\t",
\    'lang': "en",
\    'css': {
\        'snippets': {
\            '@i': '@import url(|);',
\            '@m': "@media print {\n\t|\n}",
\            '@f': "@font-face {\n\tfont-family:|;\n\tsrc:url(|);\n}",
\            '!': '!important',
\            'pos': 'position:|;',
\            'pos:s': 'position:static;',
\            'pos:a': 'position:absolute;',
\            'pos:r': 'position:relative;',
\            'pos:f': 'position:fixed;',
\            't': 'top:|;',
\            't:a': 'top:auto;',
\            'r': 'right:|;',
\            'r:a': 'right:auto;',
\            'b': 'bottom:|;',
\            'b:a': 'bottom:auto;',
\            'l': 'left:|;',
\            'l:a': 'left:auto;',
\            'z': 'z-index:|;',
\            'z:a': 'z-index:auto;',
\            'fl': 'float:|;',
\            'fl:n': 'float:none;',
\            'fl:l': 'float:left;',
\            'fl:r': 'float:right;',
\            'cl': 'clear:|;',
\            'cl:n': 'clear:none;',
\            'cl:l': 'clear:left;',
\            'cl:r': 'clear:right;',
\            'cl:b': 'clear:both;',
\            'd': 'display:|;',
\            'd:n': 'display:none;',
\            'd:b': 'display:block;',
\            'd:ib': 'display:inline;',
\            'd:li': 'display:list-item;',
\            'd:ri': 'display:run-in;',
\            'd:cp': 'display:compact;',
\            'd:tb': 'display:table;',
\            'd:itb': 'display:inline-table;',
\            'd:tbcp': 'display:table-caption;',
\            'd:tbcl': 'display:table-column;',
\            'd:tbclg': 'display:table-column-group;',
\            'd:tbhg': 'display:table-header-group;',
\            'd:tbfg': 'display:table-footer-group;',
\            'd:tbr': 'display:table-row;',
\            'd:tbrg': 'display:table-row-group;',
\            'd:tbc': 'display:table-cell;',
\            'd:rb': 'display:ruby;',
\            'd:rbb': 'display:ruby-base;',
\            'd:rbbg': 'display:ruby-base-group;',
\            'd:rbt': 'display:ruby-text;',
\            'd:rbtg': 'display:ruby-text-group;',
\            'v': 'visibility:|;',
\            'v:v': 'visibility:visible;',
\            'v:h': 'visibility:hidden;',
\            'v:c': 'visibility:collapse;',
\            'ov': 'overflow:|;',
\            'ov:v': 'overflow:visible;',
\            'ov:h': 'overflow:hidden;',
\            'ov:s': 'overflow:scroll;',
\            'ov:a': 'overflow:auto;',
\            'ovx': 'overflow-x:|;',
\            'ovx:v': 'overflow-x:visible;',
\            'ovx:h': 'overflow-x:hidden;',
\            'ovx:s': 'overflow-x:scroll;',
\            'ovx:a': 'overflow-x:auto;',
\            'ovy': 'overflow-y:|;',
\            'ovy:v': 'overflow-y:visible;',
\            'ovy:h': 'overflow-y:hidden;',
\            'ovy:s': 'overflow-y:scroll;',
\            'ovy:a': 'overflow-y:auto;',
\            'ovs': 'overflow-style:|;',
\            'ovs:a': 'overflow-style:auto;',
\            'ovs:s': 'overflow-style:scrollbar;',
\            'ovs:p': 'overflow-style:panner;',
\            'ovs:m': 'overflow-style:move;',
\            'ovs:mq': 'overflow-style:marquee;',
\            'zoo': 'zoom:1;',
\            'cp': 'clip:|;',
\            'cp:a': 'clip:auto;',
\            'cp:r': 'clip:rect(|);',
\            'bxz': 'box-sizing:|;',
\            'bxz:cb': 'box-sizing:content-box;',
\            'bxz:bb': 'box-sizing:border-box;',
\            'bxsh': 'box-shadow:|;',
\            'bxsh:n': 'box-shadow:none;',
\            'bxsh:w': '-webkit-box-shadow:0 0 0 #000;',
\            'bxsh:m': '-moz-box-shadow:0 0 0 0 #000;',
\            'm': 'margin:|;',
\            'm:a': 'margin:auto;',
\            'm:0': 'margin:0;',
\            'm:2': 'margin:0 0;',
\            'm:3': 'margin:0 0 0;',
\            'm:4': 'margin:0 0 0 0;',
\            'mt': 'margin-top:|;',
\            'mt:a': 'margin-top:auto;',
\            'mr': 'margin-right:|;',
\            'mr:a': 'margin-right:auto;',
\            'mb': 'margin-bottom:|;',
\            'mb:a': 'margin-bottom:auto;',
\            'ml': 'margin-left:|;',
\            'ml:a': 'margin-left:auto;',
\            'p': 'padding:|;',
\            'p:0': 'padding:0;',
\            'p:2': 'padding:0 0;',
\            'p:3': 'padding:0 0 0;',
\            'p:4': 'padding:0 0 0 0;',
\            'pt': 'padding-top:|;',
\            'pr': 'padding-right:|;',
\            'pb': 'padding-bottom:|;',
\            'pl': 'padding-left:|;',
\            'w': 'width:|;',
\            'w:a': 'width:auto;',
\            'h': 'height:|;',
\            'h:a': 'height:auto;',
\            'maw': 'max-width:|;',
\            'maw:n': 'max-width:none;',
\            'mah': 'max-height:|;',
\            'mah:n': 'max-height:none;',
\            'miw': 'min-width:|;',
\            'mih': 'min-height:|;',
\            'o': 'outline:|;',
\            'o:n': 'outline:none;',
\            'oo': 'outline-offset:|;',
\            'ow': 'outline-width:|;',
\            'os': 'outline-style:|;',
\            'oc': 'outline-color:#000;',
\            'oc:i': 'outline-color:invert;',
\            'bd': 'border:|;',
\            'bd+': 'border:1px solid #000;',
\            'bd:n': 'border:none;',
\            'bdbk': 'border-break:|;',
\            'bdbk:c': 'border-break:close;',
\            'bdcl': 'border-collapse:|;',
\            'bdcl:c': 'border-collapse:collapse;',
\            'bdcl:s': 'border-collapse:separate;',
\            'bdc': 'border-color:#000;',
\            'bdi': 'border-image:url(|);',
\            'bdi:n': 'border-image:none;',
\            'bdi:w': '-webkit-border-image:url(|) 0 0 0 0 stretch stretch;',
\            'bdi:m': '-moz-border-image:url(|) 0 0 0 0 stretch stretch;',
\            'bdti': 'border-top-image:url(|);',
\            'bdti:n': 'border-top-image:none;',
\            'bdri': 'border-right-image:url(|);',
\            'bdri:n': 'border-right-image:none;',
\            'bdbi': 'border-bottom-image:url(|);',
\            'bdbi:n': 'border-bottom-image:none;',
\            'bdli': 'border-left-image:url(|);',
\            'bdli:n': 'border-left-image:none;',
\            'bdci': 'border-corner-image:url(|);',
\            'bdci:n': 'border-corner-image:none;',
\            'bdci:c': 'border-corner-image:continue;',
\            'bdtli': 'border-top-left-image:url(|);',
\            'bdtli:n': 'border-top-left-image:none;',
\            'bdtli:c': 'border-top-left-image:continue;',
\            'bdtri': 'border-top-right-image:url(|);',
\            'bdtri:n': 'border-top-right-image:none;',
\            'bdtri:c': 'border-top-right-image:continue;',
\            'bdbri': 'border-bottom-right-image:url(|);',
\            'bdbri:n': 'border-bottom-right-image:none;',
\            'bdbri:c': 'border-bottom-right-image:continue;',
\            'bdbli': 'border-bottom-left-image:url(|);',
\            'bdbli:n': 'border-bottom-left-image:none;',
\            'bdbli:c': 'border-bottom-left-image:continue;',
\            'bdf': 'border-fit:|;',
\            'bdf:c': 'border-fit:clip;',
\            'bdf:r': 'border-fit:repeat;',
\            'bdf:sc': 'border-fit:scale;',
\            'bdf:st': 'border-fit:stretch;',
\            'bdf:ow': 'border-fit:overwrite;',
\            'bdf:of': 'border-fit:overflow;',
\            'bdf:sp': 'border-fit:space;',
\            'bdl': 'border-left:|;',
\            'bdl:a': 'border-length:auto;',
\            'bdsp': 'border-spacing:|;',
\            'bds': 'border-style:|;',
\            'bds:n': 'border-style:none;',
\            'bds:h': 'border-style:hidden;',
\            'bds:dt': 'border-style:dotted;',
\            'bds:ds': 'border-style:dashed;',
\            'bds:s': 'border-style:solid;',
\            'bds:db': 'border-style:double;',
\            'bds:dtds': 'border-style:dot-dash;',
\            'bds:dtdtds': 'border-style:dot-dot-dash;',
\            'bds:w': 'border-style:wave;',
\            'bds:g': 'border-style:groove;',
\            'bds:r': 'border-style:ridge;',
\            'bds:i': 'border-style:inset;',
\            'bds:o': 'border-style:outset;',
\            'bdw': 'border-width:|;',
\            'bdt': 'border-top:|;',
\            'bdt+': 'border-top:1px solid #000;',
\            'bdt:n': 'border-top:none;',
\            'bdtw': 'border-top-width:|;',
\            'bdts': 'border-top-style:|;',
\            'bdts:n': 'border-top-style:none;',
\            'bdtc': 'border-top-color:#000;',
\            'bdr': 'border-right:|;',
\            'bdr+': 'border-right:1px solid #000;',
\            'bdr:n': 'border-right:none;',
\            'bdrw': 'border-right-width:|;',
\            'bdrs': 'border-right-style:|;',
\            'bdrs:n': 'border-right-style:none;',
\            'bdrc': 'border-right-color:#000;',
\            'bdb': 'border-bottom:|;',
\            'bdb+': 'border-bottom:1px solid #000;',
\            'bdb:n': 'border-bottom:none;',
\            'bdbw': 'border-bottom-width:|;',
\            'bdbs': 'border-bottom-style:|;',
\            'bdbs:n': 'border-bottom-style:none;',
\            'bdbc': 'border-bottom-color:#000;',
\            'bdln': 'border-length:|;',
\            'bdl+': 'border-left:1px solid #000;',
\            'bdl:n': 'border-left:none;',
\            'bdlw': 'border-left-width:|;',
\            'bdls': 'border-left-style:|;',
\            'bdls:n': 'border-left-style:none;',
\            'bdlc': 'border-left-color:#000;',
\            'bdrus': 'border-radius:|;',
\            'bdtrrs': 'border-top-right-radius:|;',
\            'bdtlrs': 'border-top-left-radius:|;',
\            'bdbrrs': 'border-bottom-right-radius:|;',
\            'bdblrs': 'border-bottom-left-radius:|;',
\            'bg': 'background:|;',
\            'bg+': 'background:#FFF url(|) 0 0 no-repeat;',
\            'bg:n': 'background:none;',
\            'bg:ie': 'filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src=''|x.png'');',
\            'bgc': 'background-color:#FFF;',
\            'bgi': 'background-image:url(|);',
\            'bgi:n': 'background-image:none;',
\            'bgr': 'background-repeat:|;',
\            'bgr:n': 'background-repeat:no-repeat;',
\            'bgr:x': 'background-repeat:repeat-x;',
\            'bgr:y': 'background-repeat:repeat-y;',
\            'bga': 'background-attachment:|;',
\            'bga:f': 'background-attachment:fixed;',
\            'bga:s': 'background-attachment:scroll;',
\            'bgp': 'background-position:0 0;',
\            'bgpx': 'background-position-x:|;',
\            'bgpy': 'background-position-y:|;',
\            'bgbk': 'background-break:|;',
\            'bgbk:bb': 'background-break:bounding-box;',
\            'bgbk:eb': 'background-break:each-box;',
\            'bgbk:c': 'background-break:continuous;',
\            'bgcp': 'background-clip:|;',
\            'bgcp:bb': 'background-clip:border-box;',
\            'bgcp:pb': 'background-clip:padding-box;',
\            'bgcp:cb': 'background-clip:content-box;',
\            'bgcp:nc': 'background-clip:no-clip;',
\            'bgo': 'background-origin:|;',
\            'bgo:pb': 'background-origin:padding-box;',
\            'bgo:bb': 'background-origin:border-box;',
\            'bgo:cb': 'background-origin:content-box;',
\            'bgz': 'background-size:|;',
\            'bgz:a': 'background-size:auto;',
\            'bgz:ct': 'background-size:contain;',
\            'bgz:cv': 'background-size:cover;',
\            'c': 'color:#000;',
\            'tbl': 'table-layout:|;',
\            'tbl:a': 'table-layout:auto;',
\            'tbl:f': 'table-layout:fixed;',
\            'cps': 'caption-side:|;',
\            'cps:t': 'caption-side:top;',
\            'cps:b': 'caption-side:bottom;',
\            'ec': 'empty-cells:|;',
\            'ec:s': 'empty-cells:show;',
\            'ec:h': 'empty-cells:hide;',
\            'lis': 'list-style:|;',
\            'lis:n': 'list-style:none;',
\            'lisp': 'list-style-position:|;',
\            'lisp:i': 'list-style-position:inside;',
\            'lisp:o': 'list-style-position:outside;',
\            'list': 'list-style-type:|;',
\            'list:n': 'list-style-type:none;',
\            'list:d': 'list-style-type:disc;',
\            'list:c': 'list-style-type:circle;',
\            'list:s': 'list-style-type:square;',
\            'list:dc': 'list-style-type:decimal;',
\            'list:dclz': 'list-style-type:decimal-leading-zero;',
\            'list:lr': 'list-style-type:lower-roman;',
\            'list:ur': 'list-style-type:upper-roman;',
\            'lisi': 'list-style-image:|;',
\            'lisi:n': 'list-style-image:none;',
\            'q': 'quotes:|;',
\            'q:n': 'quotes:none;',
\            'q:ru': 'quotes:''\00AB'' ''\00BB'' ''\201E'' ''\201C'';',
\            'q:en': 'quotes:''\201C'' ''\201D'' ''\2018'' ''\2019'';',
\            'ct': 'content:|;',
\            'ct:n': 'content:normal;',
\            'ct:oq': 'content:open-quote;',
\            'ct:noq': 'content:no-open-quote;',
\            'ct:cq': 'content:close-quote;',
\            'ct:ncq': 'content:no-close-quote;',
\            'ct:a': 'content:attr(|);',
\            'ct:c': 'content:counter(|);',
\            'ct:cs': 'content:counters(|);',
\            'coi': 'counter-increment:|;',
\            'cor': 'counter-reset:|;',
\            'va': 'vertical-align:|;',
\            'va:sup': 'vertical-align:super;',
\            'va:t': 'vertical-align:top;',
\            'va:tt': 'vertical-align:text-top;',
\            'va:m': 'vertical-align:middle;',
\            'va:bl': 'vertical-align:baseline;',
\            'va:b': 'vertical-align:bottom;',
\            'va:tb': 'vertical-align:text-bottom;',
\            'va:sub': 'vertical-align:sub;',
\            'ta': 'text-align:|;',
\            'ta:l': 'text-align:left;',
\            'ta:c': 'text-align:center;',
\            'ta:r': 'text-align:right;',
\            'tal': 'text-align-last:|;',
\            'tal:a': 'text-align-last:auto;',
\            'tal:l': 'text-align-last:left;',
\            'tal:c': 'text-align-last:center;',
\            'tal:r': 'text-align-last:right;',
\            'td': 'text-decoration:|;',
\            'td:n': 'text-decoration:none;',
\            'td:u': 'text-decoration:underline;',
\            'td:o': 'text-decoration:overline;',
\            'td:l': 'text-decoration:line-through;',
\            'te': 'text-emphasis:|;',
\            'te:n': 'text-emphasis:none;',
\            'te:ac': 'text-emphasis:accent;',
\            'te:dt': 'text-emphasis:dot;',
\            'te:c': 'text-emphasis:circle;',
\            'te:ds': 'text-emphasis:disc;',
\            'te:b': 'text-emphasis:before;',
\            'te:a': 'text-emphasis:after;',
\            'th': 'text-height:|;',
\            'th:a': 'text-height:auto;',
\            'th:f': 'text-height:font-size;',
\            'th:t': 'text-height:text-size;',
\            'th:m': 'text-height:max-size;',
\            'ti': 'text-indent:|;',
\            'ti:-': 'text-indent:-9999px;',
\            'tj': 'text-justify:|;',
\            'tj:a': 'text-justify:auto;',
\            'tj:iw': 'text-justify:inter-word;',
\            'tj:ii': 'text-justify:inter-ideograph;',
\            'tj:ic': 'text-justify:inter-cluster;',
\            'tj:d': 'text-justify:distribute;',
\            'tj:k': 'text-justify:kashida;',
\            'tj:t': 'text-justify:tibetan;',
\            'to': 'text-outline:|;',
\            'to+': 'text-outline:0 0 #000;',
\            'to:n': 'text-outline:none;',
\            'tr': 'text-replace:|;',
\            'tr:n': 'text-replace:none;',
\            'tt': 'text-transform:|;',
\            'tt:n': 'text-transform:none;',
\            'tt:c': 'text-transform:capitalize;',
\            'tt:u': 'text-transform:uppercase;',
\            'tt:l': 'text-transform:lowercase;',
\            'tw': 'text-wrap:|;',
\            'tw:n': 'text-wrap:normal;',
\            'tw:no': 'text-wrap:none;',
\            'tw:u': 'text-wrap:unrestricted;',
\            'tw:s': 'text-wrap:suppress;',
\            'tsh': 'text-shadow:|;',
\            'tsh+': 'text-shadow:0 0 0 #000;',
\            'tsh:n': 'text-shadow:none;',
\            'lh': 'line-height:|;',
\            'whs': 'white-space:|;',
\            'whs:n': 'white-space:normal;',
\            'whs:p': 'white-space:pre;',
\            'whs:nw': 'white-space:nowrap;',
\            'whs:pw': 'white-space:pre-wrap;',
\            'whs:pl': 'white-space:pre-line;',
\            'whsc': 'white-space-collapse:|;',
\            'whsc:n': 'white-space-collapse:normal;',
\            'whsc:k': 'white-space-collapse:keep-all;',
\            'whsc:l': 'white-space-collapse:loose;',
\            'whsc:bs': 'white-space-collapse:break-strict;',
\            'whsc:ba': 'white-space-collapse:break-all;',
\            'wob': 'word-break:|;',
\            'wob:n': 'word-break:normal;',
\            'wob:k': 'word-break:keep-all;',
\            'wob:l': 'word-break:loose;',
\            'wob:bs': 'word-break:break-strict;',
\            'wob:ba': 'word-break:break-all;',
\            'wos': 'word-spacing:|;',
\            'wow': 'word-wrap:|;',
\            'wow:nm': 'word-wrap:normal;',
\            'wow:n': 'word-wrap:none;',
\            'wow:u': 'word-wrap:unrestricted;',
\            'wow:s': 'word-wrap:suppress;',
\            'lts': 'letter-spacing:|;',
\            'f': 'font:|;',
\            'f+': 'font:1em Arial,sans-serif;',
\            'fw': 'font-weight:|;',
\            'fw:n': 'font-weight:normal;',
\            'fw:b': 'font-weight:bold;',
\            'fw:br': 'font-weight:bolder;',
\            'fw:lr': 'font-weight:lighter;',
\            'fs': 'font-style:|;',
\            'fs:n': 'font-style:normal;',
\            'fs:i': 'font-style:italic;',
\            'fs:o': 'font-style:oblique;',
\            'fv': 'font-variant:|;',
\            'fv:n': 'font-variant:normal;',
\            'fv:sc': 'font-variant:small-caps;',
\            'fz': 'font-size:|;',
\            'fza': 'font-size-adjust:|;',
\            'fza:n': 'font-size-adjust:none;',
\            'ff': 'font-family:|;',
\            'ff:s': 'font-family:serif;',
\            'ff:ss': 'font-family:sans-serif;',
\            'ff:c': 'font-family:cursive;',
\            'ff:f': 'font-family:fantasy;',
\            'ff:m': 'font-family:monospace;',
\            'fef': 'font-effect:|;',
\            'fef:n': 'font-effect:none;',
\            'fef:eg': 'font-effect:engrave;',
\            'fef:eb': 'font-effect:emboss;',
\            'fef:o': 'font-effect:outline;',
\            'fem': 'font-emphasize:|;',
\            'femp': 'font-emphasize-position:|;',
\            'femp:b': 'font-emphasize-position:before;',
\            'femp:a': 'font-emphasize-position:after;',
\            'fems': 'font-emphasize-style:|;',
\            'fems:n': 'font-emphasize-style:none;',
\            'fems:ac': 'font-emphasize-style:accent;',
\            'fems:dt': 'font-emphasize-style:dot;',
\            'fems:c': 'font-emphasize-style:circle;',
\            'fems:ds': 'font-emphasize-style:disc;',
\            'fsm': 'font-smooth:|;',
\            'fsm:a': 'font-smooth:auto;',
\            'fsm:n': 'font-smooth:never;',
\            'fsm:aw': 'font-smooth:always;',
\            'fst': 'font-stretch:|;',
\            'fst:n': 'font-stretch:normal;',
\            'fst:uc': 'font-stretch:ultra-condensed;',
\            'fst:ec': 'font-stretch:extra-condensed;',
\            'fst:c': 'font-stretch:condensed;',
\            'fst:sc': 'font-stretch:semi-condensed;',
\            'fst:se': 'font-stretch:semi-expanded;',
\            'fst:e': 'font-stretch:expanded;',
\            'fst:ee': 'font-stretch:extra-expanded;',
\            'fst:ue': 'font-stretch:ultra-expanded;',
\            'op': 'opacity:|;',
\            'op:ie': 'filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=100);',
\            'op:ms': '-ms-filter:''progid:DXImageTransform.Microsoft.Alpha(Opacity=100)'';',
\            'rz': 'resize:|;',
\            'rz:n': 'resize:none;',
\            'rz:b': 'resize:both;',
\            'rz:h': 'resize:horizontal;',
\            'rz:v': 'resize:vertical;',
\            'cur': 'cursor:|;',
\            'cur:a': 'cursor:auto;',
\            'cur:d': 'cursor:default;',
\            'cur:c': 'cursor:crosshair;',
\            'cur:ha': 'cursor:hand;',
\            'cur:he': 'cursor:help;',
\            'cur:m': 'cursor:move;',
\            'cur:p': 'cursor:pointer;',
\            'cur:t': 'cursor:text;',
\            'pgbb': 'page-break-before:|;',
\            'pgbb:au': 'page-break-before:auto;',
\            'pgbb:al': 'page-break-before:always;',
\            'pgbb:l': 'page-break-before:left;',
\            'pgbb:r': 'page-break-before:right;',
\            'pgbi': 'page-break-inside:|;',
\            'pgbi:au': 'page-break-inside:auto;',
\            'pgbi:av': 'page-break-inside:avoid;',
\            'pgba': 'page-break-after:|;',
\            'pgba:au': 'page-break-after:auto;',
\            'pgba:al': 'page-break-after:always;',
\            'pgba:l': 'page-break-after:left;',
\            'pgba:r': 'page-break-after:right;',
\            'orp': 'orphans:|;',
\            'wid': 'widows:|;'
\        }
\    },
\    'html': {
\        'snippets': {
\            'cc:ie6': "<!--[if lte IE 6]>\n\t${child}|\n<![endif]-->",
\            'cc:ie': "<!--[if IE]>\n\t${child}|\n<![endif]-->",
\            'cc:noie': "<!--[if !IE]><!-->\n\t${child}|\n<!--<![endif]-->",
\            'html:4t': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:4s': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xt': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\" />\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\" />\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:xxs': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\n"
\                    ."<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\" />\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>",
\            'html:5': "<!DOCTYPE HTML>\n"
\                    ."<html lang=\"${lang}\">\n"
\                    ."<head>\n"
\                    ."    <title></title>\n"
\                    ."    <meta charset=\"UTF-8\">\n"
\                    ."</head>\n"
\                    ."<body>\n\t${child}|\n</body>\n"
\                    ."</html>"
\        },
\        'default_attributes': {
\            'a': {'href': ''},
\            'a:link': {'href': 'http://|'},
\            'a:mail': {'href': 'mailto:|'},
\            'abbr': {'title': ''},
\            'acronym': {'title': ''},
\            'base': {'href': ''},
\            'bdo': {'dir': ''},
\            'bdo:r': {'dir': 'rtl'},
\            'bdo:l': {'dir': 'ltr'},
\            'link:css': [{'rel': 'stylesheet'}, {'type': 'text/css'}, {'href': '|style.css'}, {'media': 'all'}],
\            'link:print': [{'rel': 'stylesheet'}, {'type': 'text/css'}, {'href': '|print.css'}, {'media': 'print'}],
\            'link:favicon': [{'rel': 'shortcut icon'}, {'type': 'image/x-icon'}, {'href': '|favicon.ico'}],
\            'link:touch': [{'rel': 'apple-touch-icon'}, {'href': '|favicon.png'}],
\            'link:rss': [{'rel': 'alternate'}, {'type': 'application/rss+xml'}, {'title': 'RSS'}, {'href': '|rss.xml'}],
\            'link:atom': [{'rel': 'alternate'}, {'type': 'application/atom+xml'}, {'title': 'Atom'}, {'href': 'atom.xml'}],
\            'meta:utf': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=UTF-8'}],
\            'meta:win': [{'http-equiv': 'Content-Type'}, {'content': 'text/html;charset=Win-1251'}],
\            'meta:compat': [{'http-equiv': 'X-UA-Compatible'}, {'content': 'IE=7'}],
\            'style': {'type': 'text/css'},
\            'script': {'type': 'text/javascript'},
\            'script:src': [{'type': 'text/javascript'}, {'src': ''}],
\            'img': [{'src': ''}, {'alt': ''}],
\            'iframe': [{'src': ''}, {'frameborder': '0'}],
\            'embed': [{'src': ''}, {'type': ''}],
\            'object': [{'data': ''}, {'type': ''}],
\            'param': [{'name': ''}, {'value': ''}],
\            'map': {'name': ''},
\            'area': [{'shape': ''}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:d': [{'shape': 'default'}, {'href': ''}, {'alt': ''}],
\            'area:c': [{'shape': 'circle'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:r': [{'shape': 'rect'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'area:p': [{'shape': 'poly'}, {'coords': ''}, {'href': ''}, {'alt': ''}],
\            'link': [{'rel': 'stylesheet'}, {'href': ''}],
\            'form': {'action': ''},
\            'form:get': {'action': '', 'method': 'get'},
\            'form:post': {'action': '', 'method': 'post'},
\            'label': {'for': ''},
\            'input': {'type': ''},
\            'input:hidden': [{'type': 'hidden'}, {'name': ''}],
\            'input:h': [{'type': 'hidden'}, {'name': ''}],
\            'input:text': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:t': [{'type': 'text'}, {'name': ''}, {'id': ''}],
\            'input:search': [{'type': 'search'}, {'name': ''}, {'id': ''}],
\            'input:email': [{'type': 'email'}, {'name': ''}, {'id': ''}],
\            'input:url': [{'type': 'url'}, {'name': ''}, {'id': ''}],
\            'input:password': [{'type': 'password'}, {'name': ''}, {'id': ''}],
\            'input:p': [{'type': 'password'}, {'name': ''}, {'id': ''}],
\            'input:datetime': [{'type': 'datetime'}, {'name': ''}, {'id': ''}],
\            'input:date': [{'type': 'date'}, {'name': ''}, {'id': ''}],
\            'input:datetime-local': [{'type': 'datetime-local'}, {'name': ''}, {'id': ''}],
\            'input:month': [{'type': 'month'}, {'name': ''}, {'id': ''}],
\            'input:week': [{'type': 'week'}, {'name': ''}, {'id': ''}],
\            'input:time': [{'type': 'time'}, {'name': ''}, {'id': ''}],
\            'input:number': [{'type': 'number'}, {'name': ''}, {'id': ''}],
\            'input:color': [{'type': 'color'}, {'name': ''}, {'id': ''}],
\            'input:checkbox': [{'type': 'checkbox'}, {'name': ''}, {'id': ''}],
\            'input:c': [{'type': 'checkbox'}, {'name': ''}, {'id': ''}],
\            'input:radio': [{'type': 'radio'}, {'name': ''}, {'id': ''}],
\            'input:r': [{'type': 'radio'}, {'name': ''}, {'id': ''}],
\            'input:range': [{'type': 'range'}, {'name': ''}, {'id': ''}],
\            'input:file': [{'type': 'file'}, {'name': ''}, {'id': ''}],
\            'input:f': [{'type': 'file'}, {'name': ''}, {'id': ''}],
\            'input:submit': [{'type': 'submit'}, {'value': ''}],
\            'input:s': [{'type': 'submit'}, {'value': ''}],
\            'input:image': [{'type': 'image'}, {'src': ''}, {'alt': ''}],
\            'input:i': [{'type': 'image'}, {'src': ''}, {'alt': ''}],
\            'input:reset': [{'type': 'reset'}, {'value': ''}],
\            'input:button': [{'type': 'button'}, {'value': ''}],
\            'input:b': [{'type': 'button'}, {'value': ''}],
\            'select': [{'name': ''}, {'id': ''}],
\            'option': {'value': ''},
\            'textarea': [{'name': ''}, {'id': ''}, {'cols': '30'}, {'rows': '10'}],
\            'menu:context': {'type': 'context'},
\            'menu:c': {'type': 'context'},
\            'menu:toolbar': {'type': 'toolbar'},
\            'menu:t': {'type': 'toolbar'},
\            'video': {'src': ''},
\            'audio': {'src': ''},
\            'html:xml': [{'xmlns': 'http://www.w3.org/1999/xhtml'}, {'xml:lang': 'ru'}]
\        },
\        'aliases': {
\            'link:*': 'link',
\            'meta:*': 'meta',
\            'area:*': 'area',
\            'bdo:*': 'bdo',
\            'form:*': 'form',
\            'input:*': 'input',
\            'script:*': 'script',
\            'html:*': 'html',
\            'a:*': 'a',
\            'menu:*': 'menu',
\            'bq': 'blockquote',
\            'acr': 'acronym',
\            'fig': 'figure',
\            'ifr': 'iframe',
\            'emb': 'embed',
\            'obj': 'object',
\            'src': 'source',
\            'cap': 'caption',
\            'colg': 'colgroup',
\            'fst': 'fieldset',
\            'btn': 'button',
\            'optg': 'optgroup',
\            'opt': 'option',
\            'tarea': 'textarea',
\            'leg': 'legend',
\            'sect': 'section',
\            'art': 'article',
\            'hdr': 'header',
\            'ftr': 'footer',
\            'adr': 'address',
\            'dlg': 'dialog',
\            'str': 'strong',
\            'sty': 'style',
\            'prog': 'progress',
\            'fset': 'fieldset',
\            'datag': 'datagrid',
\            'datal': 'datalist',
\            'kg': 'keygen',
\            'out': 'output',
\            'det': 'details',
\            'cmd': 'command'
\        },
\        'expandos': {
\            'ol': 'ol>li',
\            'ul': 'ul>li',
\            'dl': 'dl>dt+dd',
\            'map': 'map>area',
\            'table': 'table>tr>td',
\            'colgroup': 'colgroup>col',
\            'colg': 'colgroup>col',
\            'tr': 'tr>td',
\            'select': 'select>option',
\            'optgroup': 'optgroup>option',
\            'optg': 'optgroup>option'
\        },
\        'empty_elements': 'area,base,basefont,br,col,frame,hr,img,input,isindex,link,meta,param,embed,keygen,command',
\        'block_elements': 'address,applet,blockquote,button,center,dd,del,dir,div,dl,dt,fieldset,form,frameset,hr,iframe,ins,isindex,link,map,menu,noframes,noscript,object,ol,p,pre,script,table,tbody,td,tfoot,th,thead,tr,ul,h1,h2,h3,h4,h5,h6,style',
\        'inline_elements': 'a,abbr,acronym,applet,b,basefont,bdo,big,br,button,cite,code,del,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,object,q,s,samp,script,select,small,span,strike,strong,sub,sup,textarea,tt,u,var',
\    },
\    'xsl': {
\        'default_attributes': {
\            'tmatch': [{'match': ''}, {'mode': ''}],
\            'tname': [{'name': ''}],
\            'xsl:when': {'test': ''},
\            'var': [{'name': ''}, {'select': ''}],
\            'vari': {'name': ''},
\            'if': {'test': ''},
\            'call': {'name': ''},
\            'attr': {'name': ''},
\            'wp': [{'name': ''}, {'select': ''}],
\            'par': [{'name': ''}, {'select': ''}],
\            'val': {'select': ''},
\            'co': {'select': ''},
\            'each': {'select': ''},
\            'ap': [{'select': ''}, {'mode': ''}]
\        },
\        'aliases': {
\            'tmatch': 'xsl:template',
\            'tname': 'xsl:template',
\            'var': 'xsl:variable',
\            'vari': 'xsl:variable',
\            'if': 'xsl:if',
\            'call': 'xsl:call-template',
\            'wp': 'xsl:with-param',
\            'par': 'xsl:param',
\            'val': 'xsl:value-of',
\            'attr': 'xsl:attribute',
\            'co' : 'xsl:copy-of',
\            'each' : 'xsl:for-each',
\            'ap' : 'xsl:apply-templates'
\        },
\        'expandos': {
\            'choose': 'xsl:choose>xsl:when+xsl:otherwise'
\        }
\    }
\}

function! s:zen_expandos(key, type)
  if has_key(s:zen_settings[a:type], 'expandos')
    if has_key(s:zen_settings[a:type]['expandos'], a:key)
      return s:zen_settings[a:type]['expandos'][a:key]
   endif
 endif
 return a:key
endfunction

function! s:zen_parseIntoTree(abbr, type)
  let abbr = a:abbr
  let type = a:type
  if len(type) == 0 | let type = 'html' | endif
  if !has_key(s:zen_settings, type)
    return { 'child': [] }
  endif

  let abbr = substitute(abbr, '\([a-z][a-z0-9]*\)\++\{-}$', '\=s:zen_expandos(submatch(1), type)', 'i')
  let mx = '\([\+>#]\|<\+\)\{-}\s*\(@\{-}[a-z][a-z0-9:\!\-]*\|{[^}]\+}\)\(\%(\%(#[0-9A-Za-z_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|\%(\.[0-9A-Za-z_\-\$]\+\)\)*\)\%(\({[^}]\+}\)\)\{0,1}\%(\*\([0-9]\+\)\)\{0,1}'
  let last = {}
  let parent = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'brother': 0 }
  let granma = parent
  let root = parent
  while len(abbr)
    let match = matchstr(abbr, mx)
    let str = substitute(match, mx, '\0', 'ig')
    let operator = substitute(match, mx, '\1', 'ig')
    let tag_name = substitute(match, mx, '\2', 'ig')
    let attributes = substitute(match, mx, '\3', 'ig')
    let value = substitute(match, mx, '\4', 'ig')
    let multiplier = 0 + substitute(match, mx, '\5', 'ig')
    if len(str) == 0
      break
    endif
    if operator == '#'
      let attributes = '#' . tag_name . attributes
      let tag_name = 'div'
      let operator = ''
    endif
    if multiplier <= 0
      let multiplier = 1
    endif
    if has_key(s:zen_settings[type], 'aliases')
      if has_key(s:zen_settings[type]['aliases'], tag_name)
        let tag_name = s:zen_settings[type]['aliases'][tag_name]
      endif
    endif
    let current = { 'name': '', 'attr': {}, 'child': [], 'snippet': '', 'multiplier': 1, 'parent': {}, 'value': '', 'brother': 0 }
    if has_key(s:zen_settings[type]['snippets'], tag_name)
      let current['snippet'] = s:zen_settings[type]['snippets'][tag_name]
    else
      let current['name'] = substitute(tag_name, ':.*$', '', '')
      if has_key(s:zen_settings[type], 'default_attributes')
        let default_attributes = s:zen_settings[type]['default_attributes']
        if has_key(default_attributes, tag_name)
          if type(default_attributes[tag_name]) == 4
            let a = default_attributes[tag_name]
            for k in keys(a)
              let current['attr'][k] = a[k]
            endfor
          else
            for a in default_attributes[tag_name]
              for k in keys(a)
                let current['attr'][k] = a[k]
              endfor
            endfor
          endif
        endif
      endif
    endif
    if len(attributes)
      let attr = attributes
      while len(attr)
        let item = matchstr(attr, '\(\%(\%(#[0-9A-Za-z_\-\$]\+\)\|\%(\[[^\]]\+\]\)\|\%(\.[0-9A-Za-z_\-\$]\+\)\)\)')
        if len(item) == 0
          break
        endif
        if item[0] == '#'
          let current['attr']['id'] = item[1:]
        endif
        if item[0] == '.'
          let current['attr']['class'] = substitute(item[1:], '\.', '', 'g')
        endif
        if item[0] == '['
          let kk = split(item[1:-2], '=')
          let current['attr'][kk[0]] = len(kk) > 1 ? join(kk[1:], '=') : ''
        endif
        let attr = substitute(strpart(attr, len(item)), '^\s*', '', '')
      endwhile
    endif
    if tag_name =~ '^{.*}$'
      let current['name'] = ''
      let current['value'] = str
    else
      let current['value'] = value
    endif
    let current['multiplier'] = multiplier
    if operator == '>' && !empty(last)
      let tmp = parent
      unlet! parent
      let parent = last
      let parent['parent'] = tmp
    endif
    if operator == '+'
      let last['brother'] = 1
    endif
    if operator =~ '<'
      for c in range(len(operator))
        let tmp = parent['parent']
        if empty(tmp)
          break
        endif
        let parent = tmp
      endfor
    endif
    call add(parent['child'], current)
    let last = current
    if 0
      echo "str=".str
      echo "tag_name=".tag_name
      echo "operator=".operator
      echo "attributes=".attributes
      echo "value=".value
      echo "multiplier=".multiplier
      echo "\n"
    endif
    if len(tag_name) == 0
      let current['name'] = 'div'
    endif
    let abbr = abbr[stridx(abbr, match) + len(match):]
  endwhile
  return root
endfunction

function! s:zen_toString(...)
  let current = a:1
  if a:0 > 1
    let type = a:2
  else
    let type = ''
  endif
  if len(type) == 0 | let type = 'html' | endif

  if has_key(s:zen_settings[type], 'indentation')
    let indent = s:zen_settings[type]['indentation']
  else
    let indent = s:zen_settings['indentation']
  endif
  let m = 0
  let str = ''
  while m < current['multiplier']
    if len(current['name']) && type == 'html'
      let str .= '<' . current['name']
      for attr in keys(current['attr'])
        if current['multiplier'] > 1 && current['attr'][attr] =~ '\$'
          let str .= ' ' . attr . '="' . substitute(current['attr'][attr], '\$', m+1, 'g') . '"'
        else
          let str .= ' ' . attr . '="' . current['attr'][attr] . '"'
        endif
      endfor
      let inner = current['value'][1:-2]
      for child in current['child']
        let inner .= s:zen_toString(child, type)
      endfor
      if len(current['child'])
        let inner = substitute(inner, "\n", "\n" . indent, 'g')
        let inner = substitute(inner, indent . "$", "", 'g')
        let str .= ">\n" . indent . inner . "</" . current['name'] . ">\n"
      else
        if stridx(','.s:zen_settings[type]['empty_elements'].',', ','.current['name'].',') != -1
          let str .= " />\n"
        else
          if stridx(','.s:zen_settings[type]['block_elements'].',', ','.current['name'].',') != -1 && len(current['child'])
            let str .= ">\n" . inner . "|</" . current['name'] . ">\n"
          else
            let str .= ">" . inner . "|</" . current['name'] . ">\n"
          endif
        endif
      endif
    else
      let str .= '' . current['snippet']
      if len(str) == 0
        let str = current['name']
        if len(current['value'])
          let str .= current['value'][1:-2]
        endif
      endif
      let inner = ''
      if len(current['child'])
        for n in current['child']
          let inner .= s:zen_toString(n, type)
        endfor
        let inner = substitute(inner, "\n", "\n" . indent, 'g')
      endif
      let str = substitute(str, '\${child}', inner, '')
    endif
    let m = m + 1
  endwhile
  return str
endfunction

function! s:zen_get_filetype()
  let type = &ft
  if len(type) == 0 | let type = 'html' | endif
  if type == 'xhtml' | let type = 'html' | endif
  return type
endfunction

function! s:zen_expand(mode) range
  let type = s:zen_get_filetype()
  let expand = ''
  if a:mode == 2
    let leader = input('Tag: ', '')
    if len(leader) == 0
      return
    endif
    let line = ''
    let part = ''
    let rest = ''
    if leader =~ '\*$'
      for n in range(a:firstline, a:lastline)
        let items = s:zen_parseIntoTree(leader[:-2] . '{' . getline(n) . '}', type)['child']
        for item in items
          let expand .= s:zen_toString(item, type)
        endfor
      endfor
    else
      let str = '' 
      if a:firstline != a:lastline
        for n in range(a:firstline, a:lastline)
          let str .= getline(n) . "\n"
        endfor
        let items = s:zen_parseIntoTree(leader . "{\n" . str . "}", type)['child']
      else
        let str .= getline(a:firstline)
        let items = s:zen_parseIntoTree(leader . "{" . str . "}", type)['child']
      endif
      for item in items
        let expand .= s:zen_toString(item, type)
      endfor
    endif
    silent! exe "normal! gvc"
  else
    let line = getline('.')[:col('.')-1]
    if a:mode == 1 || type != 'html'
      let part = matchstr(line, '\([0-9A-Za-z_\@:]\+\)$')
    else
      let part = matchstr(line, '\(\S.*\)$')
    endif
    let rest = getline('.')[col('.'):]
    let items = s:zen_parseIntoTree(part, type)['child']
    for item in items
      let expand .= s:zen_toString(item, type)
    endfor
  endif
  if len(expand)
    let expand = substitute(expand, '|', '$cursor$', '')
    let expand = substitute(expand, '|', '', 'g')
    let expand = substitute(expand, '\$cursor\$', '|', '')
    if expand !~ '|'
      let expand .= '|'
    endif
    let expand = substitute(expand, '${lang}', s:zen_settings['lang'], 'g')
    if line[:-len(part)-1] =~ '^\s\+$'
      let size = len(line) - len(part)
      let indent = repeat(s:zen_settings['indentation'], size)
    else
      let indent = ''
    endif
    let expand = substitute(expand, '\n\s*$', '', 'g')
    let expand = line[:-len(part)-1] . substitute(expand, "\n", "\n" . indent, 'g') . rest
    let lines = split(expand, '\n')
    call setline(line('.'), lines[0])
    if len(lines) > 1
      call append(line('.'), lines[1:])
    endif
  endif
  if search('|')
    silent! exe "normal! a\<c-h>"
  endif
endfunction

function! ZenExpand(abbr, type)
  let items = s:zen_parseIntoTree(a:abbr, a:type)['child']
  let expand = ''
  for item in items
    let expand .= s:zen_toString(item, a:type)
  endfor
  return expand
endfunction

function! s:zen_mergeConfig(lhs, rhs)
  if type(a:lhs) == 3 && type(a:rhs) == 3
    call remove(a:lhs, 0, len(a:lhs)-1)
    for index in a:rhs
      call add(a:lhs, a:rhs[index])
    endfor
  elseif type(a:lhs) == 4 && type(a:rhs) == 4
    for key in keys(a:rhs)
      if type(a:rhs[key]) == 3
        call s:zen_mergeConfig(a:lhs[key], a:rhs[key])
      elseif type(a:rhs[key]) == 4
        if has_key(a:lhs, key)
          call s:zen_mergeConfig(a:lhs[key], a:rhs[key])
        else
          let a:lhs[key] = a:rhs[key]
        endif
      else
        let a:lhs[key] = a:rhs[key]
      endif
    endfor
  endif
endfunction

function! ZenCompleteTag(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[a-zA-Z0-9:\@]'
      let start -= 1
    endwhile
    return start
  else
    let type = &ft
    let res = []
    if !has_key(s:zen_settings, type)
      return res
    endif
    if len(type) == 0 | let type = 'html' | endif
    for item in keys(s:zen_settings[type]['snippets'])
      if stridx(item, a:base) != -1
        call add(res, item)
      endif
    endfor
    if has_key(s:zen_settings[type], 'aliases')
      for item in values(s:zen_settings[type]['aliases'])
        if stridx(item, a:base) != -1
          call add(res, item)
        endif
      endfor
    endif
    return res
  endif
endfunction

if exists('g:user_zen_settings')
  call s:zen_mergeConfig(s:zen_settings, g:user_zen_settings)
endif

" test
"echo ZenExpand('html:xt>div#header>div#logo+ul#nav>li.item-$*5>a', '')
"echo ZenExpand('ol>li*2', '')
"echo ZenExpand('a', '')
"echo ZenExpand('obj', '')
"echo ZenExpand('cc:ie6>p+blockquote#sample$.so.many.classes*2', '')
"echo ZenExpand('tm>if>div.message', '')
"echo ZenExpand('@i', 'css')
"echo ZenExpand('req', 'perl')
"echo ZenExpand('html:4t>div#wrapper>div#header+div#contents+div#footer', '')
"echo ZenExpand('a[href=http://www.google.com/].foo#hoge', '')
"echo ZenExpand('a+b', '')
"echo ZenExpand('a>b>c<d', '')
"echo ZenExpand('a>b>c<<d', '')
"echo ZenExpand('a[href=foo][class=bar]', '')
"echo ZenExpand('a[a=b][b=c=d][e]{foo}*2', '')
"echo ZenExpand('a[a=b][b=c=d][e]*2{foo}', '')
"echo ZenExpand('a*2{foo}a', '')
"echo ZenExpand('a{foo}*2>b', '')
"echo ZenExpand('a*2{foo}>b', '')
"echo ZenExpand('table>tr>td.name#foo+td*3', '')
"echo ZenExpand('div#header + div#footer', '')
"echo ZenExpand('#header + div#footer', '')
"echo ZenExpand('#header > ul > li < p{Footer}', '')
"echo ZenExpand('a#foo$$$*3', '')
"echo ZenExpand('@i', 'css')
"echo ZenExpand('fs:n', 'css')
"echo ZenExpand('link:css', '')
"echo ZenExpand('ul+', '')

" vim:set et:

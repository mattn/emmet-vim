let s:suite = themis#suite('others')
let s:assert = themis#helper('assert')

let s:emmet = themis#helper('emmet')

function! s:suite.__setup() abort
  call s:emmet.setup()
endfunction

" xsl {{{
function! s:suite.__xsl()
  let xsl = themis#suite('xsl')

  function! xsl.vari() abort
    call s:assert.equals(s:emmet.expand_word('vari', 'xsl'), "<xsl:variable name=\"\"></xsl:variable>\n")
  endfunction

  function! xsl.ap_wp() abort
    call s:assert.equals(s:emmet.expand_word('ap>wp', 'xsl'), "<xsl:apply-templates select=\"\" mode=\"\">\n\t<xsl:with-param name=\"\" select=\"\"></xsl:with-param>\n</xsl:apply-templates>\n")
  endfunction
endfunction
" }}}

" xsd {{{
function! s:suite.__xsd()
  let xsd = themis#suite('xsd')

  function! xsd.w3c() abort
    call s:assert.equals(s:emmet.expand_word('xsd:w3c', 'xsd'), "<?xml version=\"1.0\"?>\n<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n\t<xsd:element name=\"\" type=\"\"/>\n</xsd:schema>\n")
  endfunction
endfunction
" }}}

" mustache {{{
function! s:suite.__mustache()
  let mustache = themis#suite('mustache')

  function! mustache.id() abort
    call s:assert.equals(s:emmet.expand_word('div#{{foo}}', 'mustache'), "<div id=\"{{foo}}\"></div>\n")
  endfunction

  function! mustache.class() abort
    call s:assert.equals(s:emmet.expand_word('div.{{foo}}', 'mustache'), "<div class=\"{{foo}}\"></div>\n")
  endfunction
endfunction
" }}}

" scss {{{
function! s:suite.__scss()
  let scss = themis#suite('scss')

  function! scss.import() abort
    let res = s:emmet.expand_in_buffer('@i$$$$', 'scss', '@import url();')
    call s:assert.equals(res, '@import url();')
  endfunction

  function! scss.font_style() abort
    let res = s:emmet.expand_in_buffer('{fs:n$$$$}', 'scss', '{font-style: normal;}')
    call s:assert.equals(res, '{font-style: normal;}')
  endfunction

  function! scss.float_left() abort
    let res = s:emmet.expand_in_buffer('{fl:l|fc$$$$}', 'scss', '{float: left;}')
    call s:assert.equals(res, '{float: left;}')
  endfunction

  function! scss.background_plus() abort
    let res = s:emmet.expand_in_buffer('{bg+$$$$}', 'scss', '{background: $$$$#fff url() 0 0 no-repeat;}')
    call s:assert.equals(res, '{background: $$$$#fff url() 0 0 no-repeat;}')
  endfunction

  function! scss.background_plus_important() abort
    let res = s:emmet.expand_in_buffer('{bg+!$$$$}', 'scss', '{background: $$$$#fff url() 0 0 no-repeat !important;}')
    call s:assert.equals(res, '{background: $$$$#fff url() 0 0 no-repeat !important;}')
  endfunction

  function! scss.margin() abort
    let res = s:emmet.expand_in_buffer('{m$$$$}', 'scss', '{margin: $$$$;}')
    call s:assert.equals(res, '{margin: $$$$;}')
  endfunction

  function! scss.margin_percent() abort
    let res = s:emmet.expand_in_buffer('{m0.1p$$$$}', 'scss', '{margin: 0.1%;}')
    call s:assert.equals(res, '{margin: 0.1%;}')
  endfunction

  function! scss.margin_em() abort
    let res = s:emmet.expand_in_buffer('{m1.0$$$$}', 'scss', '{margin: 1.0em;}')
    call s:assert.equals(res, '{margin: 1.0em;}')
  endfunction

  function! scss.margin_px() abort
    let res = s:emmet.expand_in_buffer('{m2$$$$}', 'scss', '{margin: 2px;}')
    call s:assert.equals(res, '{margin: 2px;}')
  endfunction

  function! scss.border_radius() abort
    let res = s:emmet.expand_in_buffer('{bdrs10$$$$}', 'scss', '{border-radius: 10px;}')
    call s:assert.equals(res, '{border-radius: 10px;}')
  endfunction

  function! scss.vendor_prefix() abort
    let res = s:emmet.expand_in_buffer('{-bdrs20$$$$}', 'scss', "{-webkit-border-radius: 20px;\n-moz-border-radius: 20px;\n-o-border-radius: 20px;\n-ms-border-radius: 20px;\nborder-radius: 20px;}")
    call s:assert.equals(res, "{-webkit-border-radius: 20px;\n-moz-border-radius: 20px;\n-o-border-radius: 20px;\n-ms-border-radius: 20px;\nborder-radius: 20px;}")
  endfunction

  function! scss.linear_gradient() abort
    let res = s:emmet.expand_in_buffer('{lg(top,#fff,#000)$$$$}', 'scss', "{background-image: -webkit-gradient(top, 0 0, 0 100, from(#fff), to(#000));\nbackground-image: -webkit-linear-gradient(#fff, #000);\nbackground-image: -moz-linear-gradient(#fff, #000);\nbackground-image: -o-linear-gradient(#fff, #000);\nbackground-image: linear-gradient(#fff, #000);\n}")
    call s:assert.equals(res, "{background-image: -webkit-gradient(top, 0 0, 0 100, from(#fff), to(#000));\nbackground-image: -webkit-linear-gradient(#fff, #000);\nbackground-image: -moz-linear-gradient(#fff, #000);\nbackground-image: -o-linear-gradient(#fff, #000);\nbackground-image: linear-gradient(#fff, #000);\n}")
  endfunction

  function! scss.margin_multi() abort
    let res = s:emmet.expand_in_buffer('{m10-5-0$$$$}', 'scss', '{margin: 10px 5px 0;}')
    call s:assert.equals(res, '{margin: 10px 5px 0;}')
  endfunction

  function! scss.margin_negative() abort
    let res = s:emmet.expand_in_buffer('{m-10--5$$$$}', 'scss', '{margin: -10px -5px;}')
    call s:assert.equals(res, '{margin: -10px -5px;}')
  endfunction

  function! scss.margin_auto() abort
    let res = s:emmet.expand_in_buffer('{m10-auto$$$$}', 'scss', '{margin: 10px auto;}')
    call s:assert.equals(res, '{margin: 10px auto;}')
  endfunction

  function! scss.width_percent() abort
    let res = s:emmet.expand_in_buffer('{w100p$$$$}', 'scss', '{width: 100%;}')
    call s:assert.equals(res, '{width: 100%;}')
  endfunction

  function! scss.height_em() abort
    let res = s:emmet.expand_in_buffer('{h50e$$$$}', 'scss', '{height: 50em;}')
    call s:assert.equals(res, '{height: 50em;}')
  endfunction

  function! scss.multi_property_group() abort
    let res = s:emmet.expand_in_buffer('{(bg+)+c$$$$}', 'scss', "{background: $$$$#fff url() 0 0 no-repeat;\ncolor: #000;}")
    call s:assert.equals(res, "{background: $$$$#fff url() 0 0 no-repeat;\ncolor: #000;}")
  endfunction
endfunction
" }}}

" jade {{{
function! s:suite.__jade()
  let jade = themis#suite('jade')

  function! jade.doctype() abort
    let res = s:emmet.expand_in_buffer("!!!$$$$\\<c-y>,$$$$", 'jade', "doctype html\n\n")
    call s:assert.equals(res, "doctype html\n\n")
  endfunction

  function! jade.span_class() abort
    let res = s:emmet.expand_in_buffer("span.my-span$$$$\\<c-y>,$$$$", 'jade', 'span.my-span')
    call s:assert.equals(res, 'span.my-span')
  endfunction

  function! jade.input() abort
    let res = s:emmet.expand_in_buffer("input$$$$\\<c-y>,text$$$$", 'jade', 'input(type="text")')
    call s:assert.equals(res, 'input(type="text")')
  endfunction
endfunction
" }}}

" pug {{{
function! s:suite.__pug()
  let pug = themis#suite('pug')

  function! pug.doctype() abort
    let res = s:emmet.expand_in_buffer("!!!$$$$\\<c-y>,$$$$", 'pug', "doctype html\n\n")
    call s:assert.equals(res, "doctype html\n\n")
  endfunction

  function! pug.span_class() abort
    let res = s:emmet.expand_in_buffer("span.my-span$$$$\\<c-y>,$$$$", 'pug', 'span.my-span')
    call s:assert.equals(res, 'span.my-span')
  endfunction

  function! pug.input() abort
    let res = s:emmet.expand_in_buffer("input$$$$\\<c-y>,text$$$$", 'pug', 'input(type="text")')
    call s:assert.equals(res, 'input(type="text")')
  endfunction
endfunction
" }}}

" jsx {{{
function! s:suite.__jsx()
  let jsx = themis#suite('jsx')

  function! jsx.img() abort
    let res = s:emmet.expand_in_buffer("img$$$$\\<c-y>,$$$$", 'javascript.jsx', '<img src="" alt="" />')
    call s:assert.equals(res, '<img src="" alt="" />')
  endfunction

  function! jsx.span_class() abort
    let res = s:emmet.expand_in_buffer("span.my-span$$$$\\<c-y>,$$$$", 'javascript.jsx', '<span className="my-span"></span>')
    call s:assert.equals(res, '<span className="my-span"></span>')
  endfunction

  function! jsx.in_function() abort
    let res = s:emmet.expand_in_buffer("function() { return span.my-span$$$$\\<c-y>,$$$$; }", 'javascript.jsx', 'function() { return <span className="my-span"></span>; }')
    call s:assert.equals(res, 'function() { return <span className="my-span"></span>; }')
  endfunction
endfunction
" }}}

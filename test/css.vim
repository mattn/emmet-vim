let s:suite = themis#suite('css')
let s:assert = themis#helper('assert')

let s:emmet = themis#helper('emmet')

function! s:suite.__setup() abort
  call s:emmet.setup()
endfunction

function! s:suite.__expand_abbreviation()
  let expand = themis#suite('expand abbreviation')

  function! expand.font_style_normal() abort
    let res = s:emmet.expand_in_buffer('{fs:n$$$$}', 'css', '{font-style: normal;}')
    call s:assert.equals(res, '{font-style: normal;}')
  endfunction

  function! expand.float_left_fc() abort
    let res = s:emmet.expand_in_buffer('{fl:l|fc$$$$}', 'css', '{float: left;}')
    call s:assert.equals(res, '{float: left;}')
  endfunction

  function! expand.background_plus() abort
    let res = s:emmet.expand_in_buffer('{bg+$$$$}', 'css', '{background: $$$$#fff url() 0 0 no-repeat;}')
    call s:assert.equals(res, '{background: $$$$#fff url() 0 0 no-repeat;}')
  endfunction

  function! expand.background_plus_important() abort
    let res = s:emmet.expand_in_buffer('{bg+!$$$$}', 'css', '{background: $$$$#fff url() 0 0 no-repeat !important;}')
    call s:assert.equals(res, '{background: $$$$#fff url() 0 0 no-repeat !important;}')
  endfunction

  function! expand.margin() abort
    let res = s:emmet.expand_in_buffer('{m$$$$}', 'css', '{margin: $$$$;}')
    call s:assert.equals(res, '{margin: $$$$;}')
  endfunction

  function! expand.margin_percent() abort
    let res = s:emmet.expand_in_buffer('{m0.1p$$$$}', 'css', '{margin: 0.1%;}')
    call s:assert.equals(res, '{margin: 0.1%;}')
  endfunction

  function! expand.margin_em() abort
    let res = s:emmet.expand_in_buffer('{m1.0$$$$}', 'css', '{margin: 1.0em;}')
    call s:assert.equals(res, '{margin: 1.0em;}')
  endfunction

  function! expand.margin_px() abort
    let res = s:emmet.expand_in_buffer('{m2$$$$}', 'css', '{margin: 2px;}')
    call s:assert.equals(res, '{margin: 2px;}')
  endfunction

  function! expand.border_radius() abort
    let res = s:emmet.expand_in_buffer('{bdrs10$$$$}', 'css', '{border-radius: 10px;}')
    call s:assert.equals(res, '{border-radius: 10px;}')
  endfunction

  function! expand.vendor_prefix_border_radius() abort
    let res = s:emmet.expand_in_buffer('{-bdrs20$$$$}', 'css', "{-webkit-border-radius: 20px;\n-moz-border-radius: 20px;\n-o-border-radius: 20px;\n-ms-border-radius: 20px;\nborder-radius: 20px;}")
    call s:assert.equals(res, "{-webkit-border-radius: 20px;\n-moz-border-radius: 20px;\n-o-border-radius: 20px;\n-ms-border-radius: 20px;\nborder-radius: 20px;}")
  endfunction

  function! expand.linear_gradient() abort
    let res = s:emmet.expand_in_buffer('{lg(top,#fff,#000)$$$$}', 'css', "{background-image: -webkit-gradient(top, 0 0, 0 100, from(#fff), to(#000));\nbackground-image: -webkit-linear-gradient(#fff, #000);\nbackground-image: -moz-linear-gradient(#fff, #000);\nbackground-image: -o-linear-gradient(#fff, #000);\nbackground-image: linear-gradient(#fff, #000);\n}")
    call s:assert.equals(res, "{background-image: -webkit-gradient(top, 0 0, 0 100, from(#fff), to(#000));\nbackground-image: -webkit-linear-gradient(#fff, #000);\nbackground-image: -moz-linear-gradient(#fff, #000);\nbackground-image: -o-linear-gradient(#fff, #000);\nbackground-image: linear-gradient(#fff, #000);\n}")
  endfunction

  function! expand.margin_multi_value() abort
    let res = s:emmet.expand_in_buffer('{m10-5-0$$$$}', 'css', '{margin: 10px 5px 0;}')
    call s:assert.equals(res, '{margin: 10px 5px 0;}')
  endfunction

  function! expand.margin_negative() abort
    let res = s:emmet.expand_in_buffer('{m-10--5$$$$}', 'css', '{margin: -10px -5px;}')
    call s:assert.equals(res, '{margin: -10px -5px;}')
  endfunction

  function! expand.margin_auto() abort
    let res = s:emmet.expand_in_buffer('{m10-auto$$$$}', 'css', '{margin: 10px auto;}')
    call s:assert.equals(res, '{margin: 10px auto;}')
  endfunction

  function! expand.width_percent() abort
    let res = s:emmet.expand_in_buffer('{w100p$$$$}', 'css', '{width: 100%;}')
    call s:assert.equals(res, '{width: 100%;}')
  endfunction

  function! expand.height_em() abort
    let res = s:emmet.expand_in_buffer('{h50e$$$$}', 'css', '{height: 50em;}')
    call s:assert.equals(res, '{height: 50em;}')
  endfunction

  function! expand.multi_property_group() abort
    let res = s:emmet.expand_in_buffer('{(bg+)+c$$$$}', 'css', "{background: $$$$#fff url() 0 0 no-repeat;\ncolor: #000;}")
    call s:assert.equals(res, "{background: $$$$#fff url() 0 0 no-repeat;\ncolor: #000;}")
  endfunction

  function! expand.multi_property() abort
    let res = s:emmet.expand_in_buffer('{m0+bgi+bg++p0$$$$}', 'css', "{margin: 0;\nbackground-image: url($$$$);\nbackground: #fff url() 0 0 no-repeat;\npadding: 0;}")
    call s:assert.equals(res, "{margin: 0;\nbackground-image: url($$$$);\nbackground: #fff url() 0 0 no-repeat;\npadding: 0;}")
  endfunction

  function! expand.fuzzy_border_left() abort
    let res = s:emmet.expand_in_buffer('{borle$$$$}', 'css', '{border-left: $$$$;}')
    call s:assert.equals(res, '{border-left: $$$$;}')
  endfunction

  function! expand.color_shorthand() abort
    let res = s:emmet.expand_in_buffer('{c#dba$$$$}', 'css', '{color: rgb(221, 187, 170);}')
    call s:assert.equals(res, '{color: rgb(221, 187, 170);}')
  endfunction

  function! expand.color_shorthand_alpha() abort
    let res = s:emmet.expand_in_buffer('{c#dba.7$$$$}', 'css', '{color: rgb(221, 187, 170, 0.7);}')
    call s:assert.equals(res, '{color: rgb(221, 187, 170, 0.7);}')
  endfunction

  function! expand.display_none() abort
    let res = s:emmet.expand_in_buffer('{dn$$$$}', 'css', '{display: none;}')
    call s:assert.equals(res, '{display: none;}')
  endfunction

  function! expand.padding_percent_sign() abort
    let res = s:emmet.expand_in_buffer('{p10%$$$$}', 'css', '{padding: 10%;}')
    call s:assert.equals(res, '{padding: 10%;}')
  endfunction

  function! expand.padding_p_suffix() abort
    let res = s:emmet.expand_in_buffer('{p10p$$$$}', 'css', '{padding: 10%;}')
    call s:assert.equals(res, '{padding: 10%;}')
  endfunction

  function! expand.padding_e_suffix() abort
    let res = s:emmet.expand_in_buffer('{p10e$$$$}', 'css', '{padding: 10em;}')
    call s:assert.equals(res, '{padding: 10em;}')
  endfunction

  function! expand.padding_em_suffix() abort
    let res = s:emmet.expand_in_buffer('{p10em$$$$}', 'css', '{padding: 10em;}')
    call s:assert.equals(res, '{padding: 10em;}')
  endfunction

  function! expand.padding_re_suffix() abort
    let res = s:emmet.expand_in_buffer('{p10re$$$$}', 'css', '{padding: 10rem;}')
    call s:assert.equals(res, '{padding: 10rem;}')
  endfunction

  function! expand.padding_rem_suffix() abort
    let res = s:emmet.expand_in_buffer('{p10rem$$$$}', 'css', '{padding: 10rem;}')
    call s:assert.equals(res, '{padding: 10rem;}')
  endfunction
endfunction

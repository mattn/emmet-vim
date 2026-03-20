let s:suite = themis#suite('html')
let s:assert = themis#helper('assert')

let s:emmet = themis#helper('emmet')

function! s:suite.__setup() abort
  call s:emmet.setup()
endfunction

" expand abbreviation {{{
function! s:suite.__expand_abbreviation()
  let expand = themis#suite('expand abbreviation')

  function! expand.div() abort
    call s:assert.equals(s:emmet.expand_word('div', 'html'), "<div></div>\n")
  endfunction

  function! expand.div_id() abort
    call s:assert.equals(s:emmet.expand_word('div#wrapper', 'html'), "<div id=\"wrapper\"></div>\n")
  endfunction

  function! expand.div_class() abort
    call s:assert.equals(s:emmet.expand_word('div.box', 'html'), "<div class=\"box\"></div>\n")
  endfunction

  function! expand.a_with_title() abort
    call s:assert.equals(s:emmet.expand_word('a[title=TITLE]', 'html'), "<a href=\"\" title=\"TITLE\"></a>\n")
  endfunction

  function! expand.div_id_class() abort
    call s:assert.equals(s:emmet.expand_word('div#wrapper.box', 'html'), "<div id=\"wrapper\" class=\"box\"></div>\n")
  endfunction

  function! expand.div_id_multi_class() abort
    call s:assert.equals(s:emmet.expand_word('div#wrapper.box.current', 'html'), "<div id=\"wrapper\" class=\"box current\"></div>\n")
  endfunction

  function! expand.div_id_multi_class_attrs() abort
    call s:assert.equals(s:emmet.expand_word('div#wrapper.box.current[title=TITLE rel]', 'html'), "<div id=\"wrapper\" class=\"box current\" title=\"TITLE\" rel=\"\"></div>\n")
  endfunction

  function! expand.sibling() abort
    call s:assert.equals(s:emmet.expand_word('div#main+div#sub', 'html'), "<div id=\"main\"></div>\n<div id=\"sub\"></div>\n")
  endfunction

  function! expand.child() abort
    call s:assert.equals(s:emmet.expand_word('div#main>div#sub', 'html'), "<div id=\"main\">\n\t<div id=\"sub\"></div>\n</div>\n")
  endfunction

  function! expand.html_xt_complex() abort
    call s:assert.equals(s:emmet.expand_word('html:xt>div#header>div#logo+ul#nav>li.item-$*5>a', 'html'), "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n<head>\n\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\" />\n\t<title></title>\n</head>\n<body>\n\t<div id=\"header\">\n\t\t<div id=\"logo\"></div>\n\t\t<ul id=\"nav\">\n\t\t\t<li class=\"item-1\"><a href=\"\"></a></li>\n\t\t\t<li class=\"item-2\"><a href=\"\"></a></li>\n\t\t\t<li class=\"item-3\"><a href=\"\"></a></li>\n\t\t\t<li class=\"item-4\"><a href=\"\"></a></li>\n\t\t\t<li class=\"item-5\"><a href=\"\"></a></li>\n\t\t</ul>\n\t</div>\n\t\n</body>\n</html>")
  endfunction

  function! expand.ol_li_multiplier() abort
    call s:assert.equals(s:emmet.expand_word('ol>li*2', 'html'), "<ol>\n\t<li></li>\n\t<li></li>\n</ol>\n")
  endfunction

  function! expand.a_default_attr() abort
    call s:assert.equals(s:emmet.expand_word('a', 'html'), "<a href=\"\"></a>\n")
  endfunction

  function! expand.obj_alias() abort
    call s:assert.equals(s:emmet.expand_word('obj', 'html'), "<object data=\"\" type=\"\"></object>\n")
  endfunction

  function! expand.cc_ie6_complex() abort
    call s:assert.equals(s:emmet.expand_word('cc:ie6>p+blockquote#sample$.so.many.classes*2', 'html'), "<!--[if lte IE 6]>\n\t<p></p>\n\t<blockquote id=\"sample1\" class=\"so many classes\"></blockquote>\n\t<blockquote id=\"sample2\" class=\"so many classes\"></blockquote>\n\t\n<![endif]-->")
  endfunction

  function! expand.html_4t_complex() abort
    call s:assert.equals(s:emmet.expand_word('html:4t>div#wrapper>div#header+div#contents+div#footer', 'html'), "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n<html lang=\"en\">\n<head>\n\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n\t<title></title>\n</head>\n<body>\n\t<div id=\"wrapper\">\n\t\t<div id=\"header\"></div>\n\t\t<div id=\"contents\"></div>\n\t\t<div id=\"footer\"></div>\n\t</div>\n\t\n</body>\n</html>")
  endfunction

  function! expand.a_href_class_id() abort
    call s:assert.equals(s:emmet.expand_word('a[href=http://www.google.com/].foo#hoge', 'html'), "<a id=\"hoge\" class=\"foo\" href=\"http://www.google.com/\"></a>\n")
  endfunction

  function! expand.a_href_text() abort
    call s:assert.equals(s:emmet.expand_word('a[href=http://www.google.com/]{Google}', 'html'), "<a href=\"http://www.google.com/\">Google</a>\n")
  endfunction

  function! expand.text_only() abort
    call s:assert.equals(s:emmet.expand_word('{Emmet}', 'html'), 'Emmet')
  endfunction

  function! expand.a_plus_b() abort
    call s:assert.equals(s:emmet.expand_word('a+b', 'html'), "<a href=\"\"></a>\n<b></b>\n")
  endfunction

  function! expand.climb_up_lt() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i<b', 'html'), "<a href=\"\"><b><i></i></b><b></b></a>\n")
  endfunction

  function! expand.climb_up_caret() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i^b', 'html'), "<a href=\"\"><b><i></i></b><b></b></a>\n")
  endfunction

  function! expand.climb_up_double_lt() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i<<b', 'html'), "<a href=\"\"><b><i></i></b></a>\n<b></b>\n")
  endfunction

  function! expand.climb_up_double_caret() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i^^b', 'html'), "<a href=\"\"><b><i></i></b></a>\n<b></b>\n")
  endfunction

  function! expand.blockquote_climb_up_lt() abort
    call s:assert.equals(s:emmet.expand_word('blockquote>b>i<<b', 'html'), "<blockquote>\n\t<b><i></i></b>\n</blockquote>\n<b></b>\n")
  endfunction

  function! expand.blockquote_climb_up_caret() abort
    call s:assert.equals(s:emmet.expand_word('blockquote>b>i^^b', 'html'), "<blockquote>\n\t<b><i></i></b>\n</blockquote>\n<b></b>\n")
  endfunction

  function! expand.multi_attr() abort
    call s:assert.equals(s:emmet.expand_word('a[href=foo][class=bar]', 'html'), "<a class=\"bar\" href=\"foo\"></a>\n")
  endfunction

  function! expand.complex_attrs_multiplier() abort
    call s:assert.equals(s:emmet.expand_word('a[a=b][b=c=d][e]{foo}*2', 'html'), "<a href=\"e\" a=\"b\" b=\"c=d\">foo</a>\n<a href=\"e\" a=\"b\" b=\"c=d\">foo</a>\n")
  endfunction

  function! expand.attrs_multiplier_text_after() abort
    call s:assert.equals(s:emmet.expand_word('a[a=b][b=c=d][e]*2{foo}', 'html'), "<a href=\"e\" a=\"b\" b=\"c=d\"></a>\n<a href=\"e\" a=\"b\" b=\"c=d\"></a>\nfoo")
  endfunction

  function! expand.multiplier_text_tag() abort
    call s:assert.equals(s:emmet.expand_word('a*2{foo}a', 'html'), "<a href=\"\"></a>\n<a href=\"\"></a>\nfoo<a href=\"\"></a>\n")
  endfunction

  function! expand.text_multiplier_child() abort
    call s:assert.equals(s:emmet.expand_word('a{foo}*2>b', 'html'), "<a href=\"\">foo<b></b></a>\n<a href=\"\">foo<b></b></a>\n")
  endfunction

  function! expand.multiplier_text_child() abort
    call s:assert.equals(s:emmet.expand_word('a*2{foo}>b', 'html'), "<a href=\"\"></a>\n<a href=\"\"></a>\nfoo")
  endfunction

  function! expand.table_complex() abort
    call s:assert.equals(s:emmet.expand_word('table>tr>td.name#foo+td*3', 'html'), "<table>\n\t<tr>\n\t\t<td id=\"foo\" class=\"name\"></td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n</table>\n")
  endfunction

  function! expand.sibling_ids() abort
    call s:assert.equals(s:emmet.expand_word('div#header+div#footer', 'html'), "<div id=\"header\"></div>\n<div id=\"footer\"></div>\n")
  endfunction

  function! expand.implicit_div_sibling() abort
    call s:assert.equals(s:emmet.expand_word('#header+div#footer', 'html'), "<div id=\"header\"></div>\n<div id=\"footer\"></div>\n")
  endfunction

  function! expand.climb_up_with_text_lt() abort
    call s:assert.equals(s:emmet.expand_word('#header>ul>li<p{Footer}', 'html'), "<div id=\"header\">\n\t<ul>\n\t\t<li></li>\n\t</ul>\n\t<p>Footer</p>\n</div>\n")
  endfunction

  function! expand.climb_up_with_text_caret() abort
    call s:assert.equals(s:emmet.expand_word('#header>ul>li^p{Footer}', 'html'), "<div id=\"header\">\n\t<ul>\n\t\t<li></li>\n\t</ul>\n\t<p>Footer</p>\n</div>\n")
  endfunction

  function! expand.dollar_padding() abort
    call s:assert.equals(s:emmet.expand_word('a#foo$$$*3', 'html'), "<a id=\"foo001\" href=\"\"></a>\n<a id=\"foo002\" href=\"\"></a>\n<a id=\"foo003\" href=\"\"></a>\n")
  endfunction

  function! expand.ul_expando() abort
    call s:assert.equals(s:emmet.expand_word('ul+', 'html'), "<ul>\n\t<li></li>\n</ul>\n")
  endfunction

  function! expand.table_expando() abort
    call s:assert.equals(s:emmet.expand_word('table+', 'html'), "<table>\n\t<tr>\n\t\t<td></td>\n\t</tr>\n</table>\n")
  endfunction

  function! expand.header_climb_content_lt() abort
    call s:assert.equals(s:emmet.expand_word('#header>li<#content', 'html'), "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n")
  endfunction

  function! expand.header_climb_content_caret() abort
    call s:assert.equals(s:emmet.expand_word('#header>li^#content', 'html'), "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n")
  endfunction

  function! expand.group_climb_lt() abort
    call s:assert.equals(s:emmet.expand_word('(#header>li)<#content', 'html'), "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n")
  endfunction

  function! expand.group_climb_caret() abort
    call s:assert.equals(s:emmet.expand_word('(#header>li)^#content', 'html'), "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n")
  endfunction

  function! expand.double_climb_lt() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i<<div', 'html'), "<a href=\"\"><b><i></i></b></a>\n<div></div>\n")
  endfunction

  function! expand.double_climb_caret() abort
    call s:assert.equals(s:emmet.expand_word('a>b>i^^div', 'html'), "<a href=\"\"><b><i></i></b></a>\n<div></div>\n")
  endfunction

  function! expand.group_sibling() abort
    call s:assert.equals(s:emmet.expand_word('(#header>h1)+#content+#footer', 'html'), "<div id=\"header\">\n\t<h1></h1>\n</div>\n<div id=\"content\"></div>\n<div id=\"footer\"></div>\n")
  endfunction

  function! expand.complex_nested_groups() abort
    call s:assert.equals(s:emmet.expand_word('(#header>h1)+(#content>(#main>h2+div#entry$.section*5>(h3>a)+div>p*3+ul+)+(#utilities))+(#footer>address)', 'html'), "<div id=\"header\">\n\t<h1></h1>\n</div>\n<div id=\"content\">\n\t<div id=\"main\">\n\t\t<h2></h2>\n\t\t<div id=\"entry1\" class=\"section\">\n\t\t\t<h3><a href=\"\"></a></h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry2\" class=\"section\">\n\t\t\t<h3><a href=\"\"></a></h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry3\" class=\"section\">\n\t\t\t<h3><a href=\"\"></a></h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry4\" class=\"section\">\n\t\t\t<h3><a href=\"\"></a></h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry5\" class=\"section\">\n\t\t\t<h3><a href=\"\"></a></h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n\t<div id=\"utilities\"></div>\n</div>\n<div id=\"footer\">\n\t<address></address>\n</div>\n")
  endfunction

  function! expand.nested_multiplier_groups() abort
    call s:assert.equals(s:emmet.expand_word('(div>(ul*2)*2)+(#utilities)', 'html'), "<div>\n\t<ul></ul>\n\t<ul></ul>\n\t<ul></ul>\n\t<ul></ul>\n</div>\n<div id=\"utilities\"></div>\n")
  endfunction

  function! expand.table_multiplier_group() abort
    call s:assert.equals(s:emmet.expand_word('table>(tr>td*3)*4', 'html'), "<table>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n</table>\n")
  endfunction

  function! expand.nested_multiplier_groups_deep() abort
    call s:assert.equals(s:emmet.expand_word('(((a#foo+a#bar)*2)*3)', 'html'), "<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n")
  endfunction

  function! expand.multiplier_with_child() abort
    call s:assert.equals(s:emmet.expand_word('div#box$*3>h3+p*2', 'html'), "<div id=\"box1\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n<div id=\"box2\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n<div id=\"box3\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n")
  endfunction

  function! expand.dollar_multi_class() abort
    call s:assert.equals(s:emmet.expand_word('div#box.foo$$$.bar$$$*3', 'html'), "<div id=\"box\" class=\"foo001 bar001\"></div>\n<div id=\"box\" class=\"foo002 bar002\"></div>\n<div id=\"box\" class=\"foo003 bar003\"></div>\n")
  endfunction

  function! expand.escape_filter() abort
    call s:assert.equals(s:emmet.expand_word('div#box$*3>h3+p.bar*2|e', 'html'), "&lt;div id=\"box1\"&gt;\n\t&lt;h3&gt;&lt;/h3&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n&lt;/div&gt;\n&lt;div id=\"box2\"&gt;\n\t&lt;h3&gt;&lt;/h3&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n&lt;/div&gt;\n&lt;div id=\"box3\"&gt;\n\t&lt;h3&gt;&lt;/h3&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n\t&lt;p class=\"bar\"&gt;&lt;/p&gt;\n&lt;/div&gt;\n")
  endfunction

  function! expand.comment_filter() abort
    call s:assert.equals(s:emmet.expand_word('div>div#page>p.title+p|c', 'html'), "<div>\n\t<!-- #page -->\n\t<div id=\"page\">\n\t\t<!-- .title -->\n\t\t<p class=\"title\"></p>\n\t\t<!-- /.title -->\n\t\t<p></p>\n\t</div>\n\t<!-- /#page -->\n</div>\n")
  endfunction

  function! expand.single_line_filter() abort
    call s:assert.equals(s:emmet.expand_word('kbd*2|s', 'html'), '<kbd></kbd><kbd></kbd>')
  endfunction

  function! expand.link_css() abort
    call s:assert.equals(s:emmet.expand_word('link:css', 'html'), "<link rel=\"stylesheet\" href=\"style.css\" media=\"all\">\n")
  endfunction

  function! expand.attr_with_quote() abort
    call s:assert.equals(s:emmet.expand_word("a[title=\"Hello', world\" rel]", 'html'), "<a href=\"\" title=\"Hello', world\" rel=\"\"></a>\n")
  endfunction

  function! expand.child_with_text() abort
    call s:assert.equals(s:emmet.expand_word('div>a#foo{bar}', 'html'), "<div><a id=\"foo\" href=\"\">bar</a></div>\n")
  endfunction

  function! expand.class_with_text() abort
    call s:assert.equals(s:emmet.expand_word('.content{Hello!}', 'html'), "<div class=\"content\">Hello!</div>\n")
  endfunction

  function! expand.logo_group_siblings() abort
    call s:assert.equals(s:emmet.expand_word('div.logo+(div#navigation)+(div#links)', 'html'), "<div class=\"logo\"></div>\n<div id=\"navigation\"></div>\n<div id=\"links\"></div>\n")
  endfunction

  function! expand.mixed_text_and_tags() abort
    call s:assert.equals(s:emmet.expand_word('h1{header}+{Text}+a[href=http://link.org]{linktext}+{again some text}+a[href=http://anoterlink.org]{click me!}+{some final text}', 'html'), "<h1>header</h1>\nText<a href=\"http://link.org\">linktext</a>\nagain some text<a href=\"http://anoterlink.org\">click me!</a>\nsome final text")
  endfunction

  function! expand.ampersand_text() abort
    call s:assert.equals(s:emmet.expand_word('a{&}+div{&&}', 'html'), "<a href=\"\">&</a>\n<div>&&</div>\n")
  endfunction

  function! expand.span_after_tag() abort
    let res = s:emmet.expand_in_buffer('<foo/>span$$$$\<c-y>,$$$$', 'html', '<foo/><span></span>')
    call s:assert.equals(res, '<foo/><span></span>')
  endfunction

  function! expand.span_after_text() abort
    let res = s:emmet.expand_in_buffer('foo span$$$$\<c-y>,$$$$', 'html', 'foo <span></span>')
    call s:assert.equals(res, 'foo <span></span>')
  endfunction

  function! expand.span_after_text_before_text() abort
    let res = s:emmet.expand_in_buffer('foo span$$$$\<c-y>,$$$$ bar', 'html', 'foo <span></span> bar')
    call s:assert.equals(res, 'foo <span></span> bar')
  endfunction

  function! expand.visual_word_wrap() abort
    let res = s:emmet.expand_in_buffer("foo $$$$\\<c-o>ve\\<c-y>,p\\<cr>$$$$bar baz", 'html', 'foo <p>bar</p> baz')
    call s:assert.equals(res, 'foo <p>bar</p> baz')
  endfunction

  function! expand.visual_multi_word_wrap() abort
    let res = s:emmet.expand_in_buffer("foo $$$$\\<c-o>vee\\<c-y>,p\\<cr>$$$$bar baz", 'html', 'foo <p>bar baz</p>')
    call s:assert.equals(res, 'foo <p>bar baz</p>')
  endfunction

  function! expand.complex_nested() abort
    let res = s:emmet.expand_in_buffer("f div.boxes>article.box2>header>(hgroup>h2{aaa}+h3{bbb})+p{ccc}$$$$", 'html', "f <div class=\"boxes\">\n\t<article class=\"box2\">\n\t\t<header>\n\t\t\t<hgroup>\n\t\t\t\t<h2>aaa</h2>\n\t\t\t\t<h3>bbb</h3>\n\t\t\t</hgroup>\n\t\t\t<p>ccc</p>\n\t\t</header>\n\t</article>\n</div>")
    call s:assert.equals(res, "f <div class=\"boxes\">\n\t<article class=\"box2\">\n\t\t<header>\n\t\t\t<hgroup>\n\t\t\t\t<h2>aaa</h2>\n\t\t\t\t<h3>bbb</h3>\n\t\t\t</hgroup>\n\t\t\t<p>ccc</p>\n\t\t</header>\n\t</article>\n</div>")
  endfunction

  function! expand.complex_boxes() abort
    call s:assert.equals(s:emmet.expand_word("div.boxes>(div.box2>section>h2{a}+p{b})+(div.box1>section>h2{c}+p{d}+p{e}+(bq>h2{f}+h3{g})+p{h})", 'html'), "<div class=\"boxes\">\n\t<div class=\"box2\">\n\t\t<section>\n\t\t\t<h2>a</h2>\n\t\t\t<p>b</p>\n\t\t</section>\n\t</div>\n\t<div class=\"box1\">\n\t\t<section>\n\t\t\t<h2>c</h2>\n\t\t\t<p>d</p>\n\t\t\t<p>e</p>\n\t\t\t<blockquote>\n\t\t\t\t<h2>f</h2>\n\t\t\t\t<h3>g</h3>\n\t\t\t</blockquote>\n\t\t\t<p>h</p>\n\t\t</section>\n\t</div>\n</div>\n")
  endfunction

  function! expand.label_input_group() abort
    call s:assert.equals(s:emmet.expand_word('(div>(label+input))+div', 'html'), "<div>\n\t<label for=\"\"></label>\n\t<input type=\"\">\n</div>\n<div></div>\n")
  endfunction

  function! expand.visual_wrap_multiplier() abort
    let res = s:emmet.expand_in_buffer("test1\ntest2\ntest3$$$$\\<esc>ggVG\\<c-y>,ul>li>span*>a\\<cr>$$$$", 'html', "<ul>\n\t<li>\n\t\t<span><a href=\"\">test1</a></span>\n\t\t<span><a href=\"\">test2</a></span>\n\t\t<span><a href=\"\">test3</a></span>\n\t</li>\n</ul>")
    call s:assert.equals(res, "<ul>\n\t<li>\n\t\t<span><a href=\"\">test1</a></span>\n\t\t<span><a href=\"\">test2</a></span>\n\t\t<span><a href=\"\">test3</a></span>\n\t</li>\n</ul>")
  endfunction

  function! expand.visual_wrap_input() abort
    let res = s:emmet.expand_in_buffer("test1\ntest2\ntest3$$$$\\<esc>ggVG\\<c-y>,input[type=input value=$#]*\\<cr>$$$$", 'html', "<input type=\"input\" value=\"test1\">\n<input type=\"input\" value=\"test2\">\n<input type=\"input\" value=\"test3\">")
    call s:assert.equals(res, "<input type=\"input\" value=\"test1\">\n<input type=\"input\" value=\"test2\">\n<input type=\"input\" value=\"test3\">")
  endfunction

  function! expand.visual_wrap_div_id() abort
    let res = s:emmet.expand_in_buffer("test1\ntest2\ntest3$$$$\\<esc>ggVG\\<c-y>,div[id=$#]*\\<cr>$$$$", 'html', "<div id=\"test1\"></div>\n<div id=\"test2\"></div>\n<div id=\"test3\"></div>")
    call s:assert.equals(res, "<div id=\"test1\"></div>\n<div id=\"test2\"></div>\n<div id=\"test3\"></div>")
  endfunction

  function! expand.nested_id_dollar() abort
    call s:assert.equals(s:emmet.expand_word('div#id-$*5>div#id2-$', 'html'), "<div id=\"id-1\">\n\t<div id=\"id2-1\"></div>\n</div>\n<div id=\"id-2\">\n\t<div id=\"id2-2\"></div>\n</div>\n<div id=\"id-3\">\n\t<div id=\"id2-3\"></div>\n</div>\n<div id=\"id-4\">\n\t<div id=\"id2-4\"></div>\n</div>\n<div id=\"id-5\">\n\t<div id=\"id2-5\"></div>\n</div>\n")
  endfunction

  function! expand.implicit_child_attr() abort
    call s:assert.equals(s:emmet.expand_word('.foo>[bar=2]>.baz', 'html'), "<div class=\"foo\">\n\t<div bar=\"2\">\n\t\t<div class=\"baz\"></div>\n\t</div>\n</div>\n")
  endfunction

  function! expand.text_dollar() abort
    call s:assert.equals(s:emmet.expand_word('{test case $ }*3', 'html'), 'test case 1 test case 2 test case 3 ')
  endfunction

  function! expand.text_dollar_newline() abort
    call s:assert.equals(s:emmet.expand_word('{test case $${nr}}*3', 'html'), "test case 1\ntest case 2\ntest case 3\n")
  endfunction

  function! expand.text_escaped_dollar() abort
    call s:assert.equals(s:emmet.expand_word('{test case \$ }*3', 'html'), 'test case $ test case $ test case $ ')
  endfunction

  function! expand.text_dollar_padding() abort
    call s:assert.equals(s:emmet.expand_word('{test case $$$ }*3', 'html'), 'test case 001 test case 002 test case 003 ')
  endfunction

  function! expand.title_dollar_hash() abort
    call s:assert.equals(s:emmet.expand_word('a[title=$#]{foo}', 'html'), "<a href=\"\" title=\"foo\">foo</a>\n")
  endfunction

  function! expand.span_item_dollar_text() abort
    call s:assert.equals(s:emmet.expand_word('span.item$*2>{item $}', 'html'), "<span class=\"item1\">item 1</span>\n<span class=\"item2\">item 2</span>\n")
  endfunction

  function! expand.visual_wrap_indented() abort
    let res = s:emmet.expand_in_buffer("\t<div class=\"footer_nav\">\n\t\t<a href=\"#\">nav link</a>\n\t</div>$$$$\\<esc>ggVG\\<c-y>,div\\<cr>$$$$", 'html', "\t<div>\n\t\t<div class=\"footer_nav\">\n\t\t\t<a href=\"#\">nav link</a>\n\t\t</div>\n\t</div>")
    call s:assert.equals(res, "\t<div>\n\t\t<div class=\"footer_nav\">\n\t\t\t<a href=\"#\">nav link</a>\n\t\t</div>\n\t</div>")
  endfunction

  function! expand.expand_inside_tag() abort
    let res = s:emmet.expand_in_buffer('<small>a$$$$</small>', 'html', '<small><a href=""></a></small>')
    call s:assert.equals(res, '<small><a href=""></a></small>')
  endfunction

  function! expand.bem_filter() abort
    call s:assert.equals(s:emmet.expand_word('form.search-form._wide>input.-query-string+input:s.-btn_large|bem', 'html'), "<form class=\"search-form search-form_wide\" action=\"\">\n\t<input class=\"search-form__query-string\" type=\"\">\n\t<input class=\"search-form__btn search-form__btn_large\" type=\"submit\" value=\"\">\n</form>\n")
  endfunction

  function! expand.fieldset_legend_label() abort
    call s:assert.equals(s:emmet.expand_word('form>fieldset>legend+(label>input[type="checkbox"])*3', 'html'), "<form action=\"\">\n\t<fieldset>\n\t\t<legend></legend>\n\t\t<label for=\"\"><input type=\"checkbox\"></label>\n\t\t<label for=\"\"><input type=\"checkbox\"></label>\n\t\t<label for=\"\"><input type=\"checkbox\"></label>\n\t</fieldset>\n</form>\n")
  endfunction
endfunction
" }}}

" split join tag {{{
function! s:suite.__split_join_tag()
  let split_join = themis#suite('split join tag')

  function! split_join.join_tag() abort
    let res = s:emmet.expand_in_buffer("<div>\n\t<span>$$$$\\<c-y>j$$$$</span>\n</div>", 'html', "<div>\n\t<span />\n</div>")
    call s:assert.equals(res, "<div>\n\t<span />\n</div>")
  endfunction

  function! split_join.split_tag() abort
    let res = s:emmet.expand_in_buffer("<div>\n\t<span$$$$\\<c-y>j$$$$/>\n</div>", 'html', "<div>\n\t<span></span>\n</div>")
    call s:assert.equals(res, "<div>\n\t<span></span>\n</div>")
  endfunction

  function! split_join.join_with_complex_attr() abort
    let res = s:emmet.expand_in_buffer("<div onclick=\"javascript:console.log(Date.now() % 1000 > 500)\">test$$$$\\<c-y>j$$$$/>\n</div>", 'html', '<div onclick="javascript:console.log(Date.now() % 1000 > 500)" />')
    call s:assert.equals(res, '<div onclick="javascript:console.log(Date.now() % 1000 > 500)" />')
  endfunction

  function! split_join.split_custom_tag() abort
    let res = s:emmet.expand_in_buffer("<div>\n\t<some-tag$$$$\\<c-y>j$$$$/>\n</div>", 'html', "<div>\n\t<some-tag></some-tag>\n</div>")
    call s:assert.equals(res, "<div>\n\t<some-tag></some-tag>\n</div>")
  endfunction
endfunction
" }}}

" toggle comment {{{
function! s:suite.__toggle_comment()
  let comment = themis#suite('toggle comment')

  function! comment.add_comment() abort
    let res = s:emmet.expand_in_buffer("<div>\n\t<span>$$$$\\<c-y>/$$$$</span>\n</div>", 'html', "<div>\n\t<!-- <span></span> -->\n</div>")
    call s:assert.equals(res, "<div>\n\t<!-- <span></span> -->\n</div>")
  endfunction

  function! comment.remove_comment() abort
    let res = s:emmet.expand_in_buffer("<div>\n\t<!-- <span>$$$$\\<c-y>/$$$$</span> -->\n</div>", 'html', "<div>\n\t<span></span>\n</div>")
    call s:assert.equals(res, "<div>\n\t<span></span>\n</div>")
  endfunction
endfunction
" }}}

" image size {{{
function! s:suite.__image_size()
  let imgsize = themis#suite('image size')

  function! imgsize.remote_png() abort
    let res = s:emmet.expand_in_buffer("img[src=http://mattn.kaoriya.net/images/logo.png]$$$$\\<c-y>,\\<c-y>i$$$$", 'html', '<img src="http://mattn.kaoriya.net/images/logo.png" alt="" width="113" height="113">')
    call s:assert.equals(res, '<img src="http://mattn.kaoriya.net/images/logo.png" alt="" width="113" height="113">')
  endfunction

  function! imgsize.local_missing() abort
    let res = s:emmet.expand_in_buffer("img[src=/logo.png]$$$$\\<c-y>,\\<c-y>i$$$$", 'html', '<img src="/logo.png" alt="">')
    call s:assert.equals(res, '<img src="/logo.png" alt="">')
  endfunction

  function! imgsize.overwrite_existing() abort
    let res = s:emmet.expand_in_buffer("img[src=http://mattn.kaoriya.net/images/logo.png width=foo height=bar]$$$$\\<c-y>,\\<c-y>i$$$$", 'html', '<img src="http://mattn.kaoriya.net/images/logo.png" alt="" width="113" height="113">')
    call s:assert.equals(res, '<img src="http://mattn.kaoriya.net/images/logo.png" alt="" width="113" height="113">')
  endfunction
endfunction
" }}}

" move next prev {{{
function! s:suite.__move_next_prev()
  let move = themis#suite('move next prev')

  function! move.move_to_third_attr() abort
    let res = s:emmet.expand_in_buffer("foo+bar+baz[dankogai=\"\"]$$$$\\<c-y>,\\<esc>gg0\\<c-y>n\\<c-y>n\\<c-y>n\\<esc>Byw:%d _\\<cr>p$$$$", 'html', 'dankogai')
    call s:assert.equals(res, 'dankogai')
  endfunction
endfunction
" }}}

" contains dash in attributes {{{
function! s:suite.__dash_in_attributes()
  let dash = themis#suite('contains dash in attributes')

  function! dash.foo_bar_attr() abort
    call s:assert.equals(s:emmet.expand_word('div[foo-bar="baz"]', 'html'), "<div foo-bar=\"baz\"></div>\n")
  endfunction
endfunction
" }}}

" default attributes {{{
function! s:suite.__default_attributes()
  let defattr = themis#suite('default attributes')

  function! defattr.a_href_shorthand() abort
    call s:assert.equals(s:emmet.expand_word('p.title>a[/hoge/]', 'html'), "<p class=\"title\"><a href=\"/hoge/\"></a></p>\n")
  endfunction

  function! defattr.script_src() abort
    call s:assert.equals(s:emmet.expand_word('script[jquery.js]', 'html'), "<script src=\"jquery.js\"></script>\n")
  endfunction
endfunction
" }}}

" multiple group {{{
function! s:suite.__multiple_group()
  let group = themis#suite('multiple group')

  function! group.outer_inner() abort
    call s:assert.equals(s:emmet.expand_word('.outer$*3>.inner$*2', 'html'), "<div class=\"outer1\">\n\t<div class=\"inner1\"></div>\n\t<div class=\"inner2\"></div>\n</div>\n<div class=\"outer2\">\n\t<div class=\"inner1\"></div>\n\t<div class=\"inner2\"></div>\n</div>\n<div class=\"outer3\">\n\t<div class=\"inner1\"></div>\n\t<div class=\"inner2\"></div>\n</div>\n")
  endfunction
endfunction
" }}}

" group itemno {{{
function! s:suite.__group_itemno()
  let itemno = themis#suite('group itemno')

  function! itemno.dl_dt_dd() abort
    call s:assert.equals(s:emmet.expand_word('dl>(dt{$}+dd)*3', 'html'), "<dl>\n\t<dt>1</dt>\n\t<dd></dd>\n\t<dt>2</dt>\n\t<dd></dd>\n\t<dt>3</dt>\n\t<dd></dd>\n</dl>\n")
  endfunction

  function! itemno.nested_multiplier() abort
    call s:assert.equals(s:emmet.expand_word('(div[attr=$]*3)*3', 'html'), "<div attr=\"1\"></div>\n<div attr=\"2\"></div>\n<div attr=\"3\"></div>\n<div attr=\"1\"></div>\n<div attr=\"2\"></div>\n<div attr=\"3\"></div>\n<div attr=\"1\"></div>\n<div attr=\"2\"></div>\n<div attr=\"3\"></div>\n")
  endfunction
endfunction
" }}}

" update tag {{{
function! s:suite.__update_tag()
  let update = themis#suite('update tag')

  function! update.add_class() abort
    let res = s:emmet.expand_in_buffer("<h$$$$\\<c-y>u.global\\<cr>$$$$3></h3>", 'html', '<h3 class="global"></h3>')
    call s:assert.equals(res, '<h3 class="global"></h3>')
  endfunction

  function! update.add_class_preserve_attr() abort
    let res = s:emmet.expand_in_buffer("<button$$$$\\<c-y>u.btn\\<cr>$$$$ disabled></button>", 'html', '<button class="btn" disabled></button>')
    call s:assert.equals(res, '<button class="btn" disabled></button>')
  endfunction
endfunction
" }}}

" base value {{{
function! s:suite.__base_value()
  let base = themis#suite('base value')

  function! base.base_zero() abort
    call s:assert.equals(s:emmet.expand_word('ul>li#id$@0*3', 'html'), "<ul>\n\t<li id=\"id0\"></li>\n\t<li id=\"id1\"></li>\n\t<li id=\"id2\"></li>\n</ul>\n")
  endfunction
endfunction
" }}}

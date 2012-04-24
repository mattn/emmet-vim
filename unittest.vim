if exists('g:user_zen_settings')
  let s:old_user_zen_settings = g:user_zen_settings
  unlet! g:user_zen_settings
endif
so plugin/zencoding.vim

function! s:testExpandAbbr()
  unlet! testgroups
  let testgroups = eval(join(filter(split(substitute(join(readfile(expand('%')), "\n"), '.*\nfinish\n', '', ''), '\n', 1), "v:val !~ '^\"'")))
  let failed = 0
  for testgroup in testgroups
    echohl MatchParen | echon "[" testgroup.category."]\n" | echohl None
    let tests = testgroup.tests
    let start = reltime()
    for n in range(len(tests))
      let testtitle = tests[n].name
      let testtitle = len(testtitle) < 57 ? (testtitle.repeat(' ', 57-len(testtitle))) : strpart(testtitle, 0, 57)
      echohl ModeMsg | echon "testing #".printf("%03d", n+1)
      echohl None | echon ": ".testtitle." ... "
      unlet! res | let res = zencoding#ExpandWord(tests[n].query, tests[n].type, 0)
      if res == tests[n].result
        echohl Title | echon "ok\n" | echohl None
      else
        echohl WarningMsg | echon "ng\n" | echohl None
        echohl ErrorMsg | echo "failed test #".(n+1) | echohl None
        set more
        echo "    expect:".tests[n].result
        echo "       got:".res
        echo ""
        let failed = 1
        break
      endif
    endfor
    if failed
      break
    endif
    echo "past:".reltimestr(reltime(start))."\n"
  endfor
endfunction

function! s:testImageSize()
  silent! 1new
  silent! call setline(1, "img[src=http://mattn.kaoriya.net/images/logo.png]")
  silent! let start = reltime()
  exe "silent! normal A\<c-y>,\<c-y>i"
  let time = reltimestr(reltime(start))
  let line = getline(1)
  silent! bw!
  echohl MatchParen | echon "[image size]\n" | echohl None
  echohl ModeMsg | echon "testing image size" . repeat(' ', 54) . '... ' | echohl None
  let expect = '<img src="http://mattn.kaoriya.net/images/logo.png" alt="" width="96" height="96" />'
  if line == expect
    echohl Title | echon "ok\n" | echohl None
    echo "past:".time."\n"
    echo
  else
    echohl WarningMsg | echon "ng\n" | echohl None
    echohl ErrorMsg | echo "failed test image size" | echohl None
    echo "    expect:".expect
    echo "       got:".line
    echo ""
  endif
endfunction

function! s:testMoveNextPrev()
  silent! 1new
  silent! call setline(1, "<foo></foo>")
  silent! call setline(2, "<bar></bar>")
  silent! call setline(3, "<baz dankogai=\"\"></baz>")
  let start = reltime()
  exe "silent! normal gg0\<c-y>n\<c-y>n\<c-y>n"
  let pos = getpos(".")
  let line = substitute(getline("."), '<baz \(\w\+\)=".*', '\1', '')
  silent! bw!
  echohl MatchParen | echon "[move next prev]\n" | echohl None
  echohl ModeMsg | echon "testing move next prev" . repeat(' ', 50) . '... ' | echohl None
  let time = reltimestr(reltime(start))
  let expect = [0,3,15,0]
  if pos == expect && line == 'dankogai'
    echohl Title | echon "ok\n" | echohl None
    echo "past:".time."\n"
  else
    echohl WarningMsg | echon "ng\n" | echohl None
    echohl ErrorMsg | echo "failed test image size" | echohl None
    echo "    expect:".string(expect)
    echo "       got:".string(pos)
    echo ""
  endif
endfunction

try
  let oldmore = &more
  let &more = 0
  call s:testExpandAbbr()
  call s:testImageSize()
  call s:testMoveNextPrev()
finally
  let &more=oldmore
endtry

if exists('g:user_zen_settings')
  let g:user_zen_settings = s:old_user_zen_settings
endif

echo "done"

finish
[
{
  'category': 'html',
  'tests': [
    {
      'name': "div",
      'query': "div",
      'type': "html",
      'result': "<div></div>\n",
    },
    {
      'name': "div#wrapper",
      'query': "div#wrapper",
      'type': "html",
      'result': "<div id=\"wrapper\"></div>\n",
    },
    {
      'name': "div.box",
      'query': "div.box",
      'type': "html",
      'result': "<div class=\"box\"></div>\n",
    },
    {
      'name': "a[title=TITLE]",
      'query': "a[title=TITLE]",
      'type': "html",
      'result': "<a href=\"\" title=\"TITLE\"></a>\n",
    },
    {
      'name': "div#wrapper.box",
      'query': "div#wrapper.box",
      'type': "html",
      'result': "<div id=\"wrapper\" class=\"box\"></div>\n",
    },
    {
      'name': "div#wrapper.box.current",
      'query': "div#wrapper.box.current",
      'type': "html",
      'result': "<div id=\"wrapper\" class=\"box current\"></div>\n",
    },
    {
      'name': "div#wrapper.box.current[title=TITLE rel]",
      'query': "div#wrapper.box.current[title=TITLE rel]",
      'type': "html",
      'result': "<div id=\"wrapper\" rel=\"\" class=\"box current\" title=\"TITLE\"></div>\n",
    },
    {
      'name': "div#main+div#sub",
      'query': "div#main+div#sub",
      'type': "html",
      'result': "<div id=\"main\"></div>\n<div id=\"sub\"></div>\n",
    },
    {
      'name': "div#main>div#sub",
      'query': "div#main>div#sub",
      'type': "html",
      'result': "<div id=\"main\">\n\t<div id=\"sub\"></div>\n</div>\n",
    },
    {
      'name': "html:xt>div#header>div#logo+ul#nav>li.item-$*5>a",
      'query': "html:xt>div#header>div#logo+ul#nav>li.item-$*5>a",
      'type': "html",
      'result': "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n<head>\n\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\" />\n\t<title></title>\n</head>\n<body>\n\t<div id=\"header\">\n\t\t<div id=\"logo\"></div>\n\t\t<ul id=\"nav\">\n\t\t\t<li class=\"item-1\">\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</li>\n\t\t\t<li class=\"item-2\">\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</li>\n\t\t\t<li class=\"item-3\">\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</li>\n\t\t\t<li class=\"item-4\">\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</li>\n\t\t\t<li class=\"item-5\">\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</li>\n\t\t</ul>\n\t</div>\n\t\n</body>\n</html>",
    },
    {
      'name': "ol>li*2",
      'query': "ol>li*2",
      'type': "html",
      'result': "<ol>\n\t<li></li>\n\t<li></li>\n</ol>\n",
    },
    {
      'name': "a",
      'query': "a",
      'type': "html",
      'result': "<a href=\"\"></a>\n",
    },
    {
      'name': "obj",
      'query': "obj",
      'type': "html",
      'result': "<object data=\"\" type=\"\"></object>\n",
    },
    {
      'name': "cc:ie6>p+blockquote#sample$.so.many.classes*2",
      'query': "cc:ie6>p+blockquote#sample$.so.many.classes*2",
      'type': "html",
      'result': "<!--[if lte IE 6]>\n\t<p></p>\n\t<blockquote id=\"sample1\" class=\"so many classes\"></blockquote>\n\t<blockquote id=\"sample2\" class=\"so many classes\"></blockquote>\n\t\n<![endif]-->",
    },
    {
      'name': "tm>if>div.message",
      'query': "tm>if>div.message",
      'type': "html",
      'result': "<tm>\n\t<if>\n\t\t<div class=\"message\"></div>\n\t</if>\n</tm>\n",
    },
    {
      'name': "html:4t>div#wrapper>div#header+div#contents+div#footer",
      'query': "html:4t>div#wrapper>div#header+div#contents+div#footer",
      'type': "html",
      'result': "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n<html lang=\"en\">\n<head>\n\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n\t<title></title>\n</head>\n<body>\n\t<div id=\"wrapper\">\n\t\t<div id=\"header\"></div>\n\t\t<div id=\"contents\"></div>\n\t\t<div id=\"footer\"></div>\n\t</div>\n\t\n</body>\n</html>",
    },
    {
      'name': "a[href=http://www.google.com/].foo#hoge",
      'query': "a[href=http://www.google.com/].foo#hoge",
      'type': "html",
      'result': "<a id=\"hoge\" href=\"http://www.google.com/\" class=\"foo\"></a>\n",
    },
    {
      'name': "a[href=http://www.google.com/]{Google}",
      'query': "a[href=http://www.google.com/]{Google}",
      'type': "html",
      'result': "<a href=\"http://www.google.com/\">Google</a>\n",
    },
    {
      'name': "{ZenCoding}",
      'query': "{ZenCoding}",
      'type': "html",
      'result': "ZenCoding",
    },
    {
      'name': "a+b",
      'query': "a+b",
      'type': "html",
      'result': "<a href=\"\"></a>\n<b></b>\n",
    },
    {
      'name': "a>b>c<d",
      'query': "a>b>c<d",
      'type': "html",
      'result': "<a href=\"\"><b><c></c></b><d></d></a>\n",
    },
    {
      'name': "a>b>c<<d",
      'query': "a>b>c<<d",
      'type': "html",
      'result': "<a href=\"\"><b><c></c></b></a>\n<d></d>\n",
    },
    {
      'name': "blockquote>b>c<<d",
      'query': "blockquote>b>c<<d",
      'type': "html",
      'result': "<blockquote>\n\t<b><c></c></b>\n</blockquote>\n<d></d>\n",
    },
    {
      'name': "a[href=foo][class=bar]",
      'query': "a[href=foo][class=bar]",
      'type': "html",
      'result': "<a href=\"foo\" class=\"bar\"></a>\n",
    },
    {
      'name': "a[a=b][b=c=d][e]{foo}*2",
      'query': "a[a=b][b=c=d][e]{foo}*2",
      'type': "html",
      'result': "<a a=\"b\" b=\"c=d\" e=\"\" href=\"\">foo</a>\n<a a=\"b\" b=\"c=d\" e=\"\" href=\"\">foo</a>\n",
    },
    {
      'name': "a[a=b][b=c=d][e]*2{foo}",
      'query': "a[a=b][b=c=d][e]*2{foo}",
      'type': "html",
      'result': "<a a=\"b\" b=\"c=d\" e=\"\" href=\"\"></a>\n<a a=\"b\" b=\"c=d\" e=\"\" href=\"\"></a>\nfoo",
    },
    {
      'name': "a*2{foo}a",
      'query': "a*2{foo}a",
      'type': "html",
      'result': "<a href=\"\"></a>\n<a href=\"\"></a>\nfoo<a href=\"\"></a>\n",
    },
    {
      'name': "a{foo}*2>b",
      'query': "a{foo}*2>b",
      'type': "html",
      'result': "<a href=\"\">foo<b></b></a>\n<a href=\"\">foo<b></b></a>\n",
    },
    {
      'name': "a*2{foo}>b",
      'query': "a*2{foo}>b",
      'type': "html",
      'result': "<a href=\"\"></a>\n<a href=\"\"></a>\nfoo",
    },
    {
      'name': "table>tr>td.name#foo+td*3",
      'query': "table>tr>td.name#foo+td*3",
      'type': "html",
      'result': "<table>\n\t<tr>\n\t\t<td id=\"foo\" class=\"name\"></td>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n</table>\n",
    },
    {
      'name': "div#header + div#footer",
      'query': "div#header + div#footer",
      'type': "html",
      'result': "<div id=\"header\"></div>\n<div id=\"footer\"></div>\n",
    },
    {
      'name': "#header + div#footer",
      'query': "#header + div#footer",
      'type': "html",
      'result': "<div id=\"header\"></div>\n<div id=\"footer\"></div>\n",
    },
    {
      'name': "#header > ul > li < p{Footer}",
      'query': "#header > ul > li < p{Footer}",
      'type': "html",
      'result': "<div id=\"header\">\n\t<ul>\n\t\t<li></li>\n\t</ul>\n\t<p>Footer</p>\n</div>\n",
    },
    {
      'name': "a#foo$$$*3",
      'query': "a#foo$$$*3",
      'type': "html",
      'result': "<a id=\"foo001\" href=\"\"></a>\n<a id=\"foo002\" href=\"\"></a>\n<a id=\"foo003\" href=\"\"></a>\n",
    },
    {
      'name': "ul+",
      'query': "ul+",
      'type': "html",
      'result': "<ul>\n\t<li></li>\n</ul>\n",
    },
    {
      'name': "table+",
      'query': "table+",
      'type': "html",
      'result': "<table>\n\t<tr>\n\t\t<td></td>\n\t</tr>\n</table>\n",
    },
    {
      'name': "#header>li<#content",
      'query': "#header>li<#content",
      'type': "html",
      'result': "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n",
    },
    {
      'name': "(#header>li)<#content",
      'query': "(#header>li)<#content",
      'type': "html",
      'result': "<div id=\"header\">\n\t<li></li>\n</div>\n<div id=\"content\"></div>\n",
    },
    {
      'name': "a>b>c<<div",
      'query': "a>b>c<<div",
      'type': "html",
      'result': "<a href=\"\"><b><c></c></b></a>\n<div></div>\n",
    },
    {
      'name': "(#header>h1)+#content+#footer",
      'query': "(#header>h1)+#content+#footer",
      'type': "html",
      'result': "<div id=\"header\">\n\t<h1></h1>\n</div>\n<div id=\"content\"></div>\n<div id=\"footer\"></div>\n",
    },
    {
      'name': "(#header>h1)+(#content>(#main>h2+div#entry$.section*5>(h3>a)+div>p*3+ul+)+(#utilities))+(#footer>address)",
      'query': "(#header>h1)+(#content>(#main>h2+div#entry$.section*5>(h3>a)+div>p*3+ul+)+(#utilities))+(#footer>address)",
      'type': "html",
      'result': "<div id=\"header\">\n\t<h1></h1>\n</div>\n<div id=\"content\">\n\t<div id=\"main\">\n\t\t<h2></h2>\n\t\t<div id=\"entry1\" class=\"section\">\n\t\t\t<h3>\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry2\" class=\"section\">\n\t\t\t<h3>\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry3\" class=\"section\">\n\t\t\t<h3>\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry4\" class=\"section\">\n\t\t\t<h3>\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t\t<div id=\"entry5\" class=\"section\">\n\t\t\t<h3>\n\t\t\t\t<a href=\"\"></a>\n\t\t\t</h3>\n\t\t\t<div>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<p></p>\n\t\t\t\t<ul>\n\t\t\t\t\t<li></li>\n\t\t\t\t</ul>\n\t\t\t</div>\n\t\t</div>\n\t</div>\n\t<div id=\"utilities\"></div>\n</div>\n<div id=\"footer\">\n\t<address></address>\n</div>\n",
    },
    {
      'name': "(div>(ul*2)*2)+(#utilities)",
      'query': "(div>(ul*2)*2)+(#utilities)",
      'type': "html",
      'result': "<div>\n\t<ul></ul>\n\t<ul></ul>\n\t<ul></ul>\n\t<ul></ul>\n</div>\n<div id=\"utilities\"></div>\n",
    },
    {
      'name': "table>(tr>td*3)*4",
      'query': "table>(tr>td*3)*4",
      'type': "html",
      'result': "<table>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n\t<tr>\n\t\t<td></td>\n\t\t<td></td>\n\t\t<td></td>\n\t</tr>\n</table>\n",
    },
    {
      'name': "(((a#foo+a#bar)*2)*3)",
      'query': "(((a#foo+a#bar)*2)*3)",
      'type': "html",
      'result': "<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n<a id=\"foo\" href=\"\"></a>\n<a id=\"bar\" href=\"\"></a>\n",
    },
    {
      'name': "div#box$*3>h3+p*2",
      'query': "div#box$*3>h3+p*2",
      'type': "html",
      'result': "<div id=\"box1\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n<div id=\"box2\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n<div id=\"box3\">\n\t<h3></h3>\n\t<p></p>\n\t<p></p>\n</div>\n"
    },
    {
      'name': "div#box.foo$$$.bar$$$*3",
      'query': "div#box.foo$$$.bar$$$*3",
      'type': "html",
      'result': "<div id=\"box\" class=\"foo001 bar001\"></div>\n<div id=\"box\" class=\"foo002 bar002\"></div>\n<div id=\"box\" class=\"foo003 bar003\"></div>\n",
    },
    {
      'name': "div#box$*3>h3+p.bar*2|e",
      'query': "div#box$*3>h3+p.bar*2|e",
      'type': "html",
      'result': "&lt;div id=\"box1\"&gt;\n\t&amp;lt;h3&amp;gt;&amp;lt;/h3&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n&lt;/div&gt;\n&lt;div id=\"box2\"&gt;\n\t&amp;lt;h3&amp;gt;&amp;lt;/h3&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n&lt;/div&gt;\n&lt;div id=\"box3\"&gt;\n\t&amp;lt;h3&amp;gt;&amp;lt;/h3&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n\t&amp;lt;p class=\"bar\"&amp;gt;&amp;lt;/p&amp;gt;\n&lt;/div&gt;\n",
    },
    {
      'name': "div>div#page>p.title+p|c",
      'query': "div>div#page>p.title+p|c",
      'type': "html",
      'result': "<div>\n\t<!-- #page -->\n\t<div id=\"page\">\n\t\t<!-- .title -->\n\t\t<p class=\"title\"></p>\n\t\t<!-- /.title -->\n\t\t<p></p>\n\t</div>\n\t<!-- /#page -->\n</div>\n",
    },
    {
      'name': "link:css",
      'query': "link:css",
      'type': "html",
      'result': "<link media=\"all\" rel=\"stylesheet\" href=\"style.css\" type=\"text/css\" />\n",
    },
    {
      'name': "a[title=\"Hello', world\" rel]",
      'query': "a[title=\"Hello', world\" rel]",
      'type': "html",
      'result': "<a rel=\"\" href=\"\" title=\"Hello', world\"></a>\n",
    },
    {
      'name': "div>a#foo{bar}",
      'query': "div>a#foo{bar}",
      'type': "html",
      'result': "<div>\n\t<a id=\"foo\" href=\"\">bar</a>\n</div>\n",
    },
    {
      'name': ".content{Hello!}",
      'query': ".content{Hello!}",
      'type': "html",
      'result': "<div class=\"content\">Hello!</div>\n",
    },
    {
      'name': "div.logo+(div#navigation)+(div#links)",
      'query': "div.logo+(div#navigation)+(div#links)",
      'type': "html",
      'result': "<div class=\"logo\"></div>\n<div id=\"navigation\"></div>\n<div id=\"links\"></div>\n",
    },
    {
      'name': "h1{header}+{Text}+a[href=http://link.org]{linktext}+{again some text}+a[href=http://anoterlink.org]{click me!}+{some final text}",
      'query': "h1{header}+{Text}+a[href=http://link.org]{linktext}+{again some text}+a[href=http://anoterlink.org]{click me!}+{some final text}",
      'type': "html",
      'result': "<h1>header</h1>\nText<a href=\"http://link.org\">linktext</a>\nagain some text<a href=\"http://anoterlink.org\">click me!</a>\nsome final text",
    },
  ],
},
{
  'category': 'css',
  'tests': [
    {
      'name': "@i",
      'query': "@i",
      'type': "css",
      'result': "@import url();",
    },
    {
      'name': "fs:n",
      'query': "fs:n",
      'type': "css",
      'result': "font-style: normal;",
    },
    {
      'name': "fl:l|fc",
      'query': "fl:l|fc",
      'type': "css",
      'result': "float: left;",
    },
    {
      'name': "bg+",
      'query': "bg+",
      'type': "css",
      'result': "background: #FFF url() 0 0 no-repeat;",
    },
  ],
},
{
  'category': 'haml',
  'tests': [
    {
      'name': "div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}",
      'query': "div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}",
      'type': "haml",
      'result': "<div>\n\t<p></p>\n\t<ul id=\"foo\">\n\t\t<li foo=\"bar\" bar=\"baz\" class=\"bar1\">baz</li>\n\t\t<li foo=\"bar\" bar=\"baz\" class=\"bar2\">baz</li>\n\t\t<li foo=\"bar\" bar=\"baz\" class=\"bar3\">baz</li>\n\t</ul>\n</div>\n",
    },
    {
      'name': "div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}|haml",
      'query': "div>p+ul#foo>li.bar$[foo=bar][bar=baz]*3>{baz}|haml",
      'type': "haml",
      'result': "%div\n  %p\n  %ul#foo\n    %li.bar1{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar2{ :foo => \"bar\", :bar => \"baz\" } baz\n    %li.bar3{ :foo => \"bar\", :bar => \"baz\" } baz\n",
    },
    {
      'name': "a*3|haml",
      'query': "a*3|haml",
      'type': "haml",
      'result': "%a{ :href => \"\" }\n%a{ :href => \"\" }\n%a{ :href => \"\" }\n",
    },
    {
      'name': ".content{Hello!}|haml",
      'query': ".content{Hello!}|haml",
      'type': "haml",
      'result': "%div.content Hello!\n",
    },
  ],
},
{
  'category': 'xsl',
  'tests': [
    {
      'name': "vari",
      'query': "vari",
      'type': "xsl",
      'result': "<xsl:variable name=\"\"></xsl:variable>\n",
    },
    {
      'name': "ap>wp",
      'query': "ap>wp",
      'type': "xsl",
      'result': "<xsl:apply-templates select=\"\" mode=\"\">\n\t<xsl:with-param select=\"\" name=\"\"></xsl:with-param>\n</xsl:apply-templates>\n",
    },
  ],
},
{
  'category': 'xsd',
  'tests': [
    {
      'name': "w3c",
      'query': "xsd:w3c",
      'type': "xsd",
      'result': "<?xml version=\"1.0\"?>\n<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n\t<xsd:element name=\"\" type=\"\"/>\n</xsd:schema>",
    },
  ],
},
{
    'category': 'mustache',
    'tests': [
      {
        'name': "div#{{foo}}",
        'query': "div#{{foo}}",
        'type': "mustache",
        'result': "<div id=\"{{foo}}\"></div>\n",
      },
      {
        'name': "div.{{foo}}",
        'query': "div.{{foo}}",
        'type': "mustache",
        'result': "<div class=\"{{foo}}\"></div>\n",
      },
    ],
},
]
" vim:set et:

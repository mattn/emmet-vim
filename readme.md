ZenCoding-vim
====
[zencoding-vim](http://mattn.github.com/zencoding-vim) is vim script support for expanding abbreviation like zen-coding.

Installation
---

[Download zip
file](http://www.vim.org/scripts/script.php?script_id=2981):

    cd ~/.vim
    unzip zencoding-vim.zip

If you install pathogen.vim:

    cd ~/.vim/bundle # or make directory
    unzip /path/to/zencoding-vim.zip

If you get source from repository:

    cd ~/.vim/bundle # or make directory
    git clone http://github.com/mattn/zencoding-vim.git

or:

    git clone http://github.com/mattn/zencoding-vim.git
    cd zencoding-vim
    cp plugin/zencoding.vim ~/.vim/plugin/
    cp autoload/zencoding.vim ~/.vim/autoload/


Quick Tutorial
---

Open or create New File:
    
    vim index.html

Type ("_" is the cursor position):

    html:5_

Then type "<c-y>," (Ctrl + y + ','), you should see:

    <!DOCTYPE HTML>
    <html lang="en">
    <head>
    	<meta charset="UTF-8">
    	<title></title>
    </head>
    <body>
    	_
    </body>
    </html>

[More
Tutorials](https://raw.github.com/mattn/zencoding-vim/master/TUTORIAL)


Project Authors
---
[Yasuhiro Matsumoto](http://mattn.kaoriya.net/)

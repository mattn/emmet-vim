all : zencoding-vim.zip

zencoding-vim.zip :
	zip -r zencoding-vim.zip autoload plugin

release: zencoding-vim.zip
	./vimup update-script zencoding.vim

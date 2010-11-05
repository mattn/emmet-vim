all : zencoding-vim.zip

zencoding-vim.zip :
	-rm -f zencoding-vim.zip
	zip -r zencoding-vim.zip autoload plugin

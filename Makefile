all : zencoding-vim.zip

remove-zip:
	rm zencoding-vim.zip

zencoding-vim.zip: remove-zip
	zip -r zencoding-vim.zip autoload plugin doc

release: zencoding-vim.zip
	vimup update-script zencoding.vim

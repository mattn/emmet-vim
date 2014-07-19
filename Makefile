all: emmet-vim.zip

clean:
	-rm doc/tags
	-rm emmet-vim.zip

emmet-vim.zip: autoload plugin doc
	zip -r $@ $^

release: clean all
	vimup update-script emmet.vim

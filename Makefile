# .PHONY: d.txt
.PHONY: install
install:
	# @sudo ./install_python.sh
	@./install_python.sh
	@./install_vim.sh
	@./install_tools.sh
	@zsh
	@./gitclone_list.sh

.PHONY: deploy
deploy:
	@make install
	# @source $HOME/.zshrc
	# @./gitclone_list.sh

.PHONY: build
build:
	docker-compose build

.PHONY: run
run:
	docker-compose run dotfiles

.PHONY: test
test:
	@make run



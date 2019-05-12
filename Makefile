# .PHONY: d.txt
.PHONY: deploy
deploy:
	@./symlink.sh

.PHONY: install
install:
	@./install_packages.sh
	@./install_tools.sh
	@./install_python.sh
	@./install_vim.sh
	@./install_nvim.sh
	@zsh
	@./gitclone_list.sh

.PHONY: build
build:
	docker-compose build

.PHONY: run
run:
	docker-compose run publish

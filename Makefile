# .PHONY: d.txt
.PHONY: deploy
deploy:
	@./symlink.sh

.PHONY: install
install:
	@./install/install_packages.sh
	@./install/install_tools.sh
	@./install/install_vim.sh
	@./install/install_nvim.sh
	@zsh
	@./etc/gitclone_list.sh

.PHONY: build
build:
	docker-compose build

.PHONY: run
run:
	docker-compose run publish

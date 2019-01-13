# .PHONY: d.txt
.PHONY: install
install:
	# @sudo ./install_python.sh
	@./install_python.sh
	@./install_vim.sh
	@./install_tools.sh
	@/usr/bin/zsh
	@./gitclone_list.sh

.PHONY: deploy
deploy:
	@./symlink.sh
	@make install

.PHONY: testbuild
testbuild:
	docker-compose build

.PHONY: testrun
testrun:
	docker-compose run test

# .PHONY: d.txt
.PHONY: deploy
deploy:
	@./symlink.sh

.PHONY: install
install:
	@./install_tools.sh
	@./install_python.sh
	@./install_vim.sh
	@/bin/zsh
	@./gitclone_list.sh

.PHONY: testbuild
testbuild:
	docker-compose build

.PHONY: testrun
testrun:
	docker-compose run test

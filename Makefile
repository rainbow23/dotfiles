# .PHONY: d.txt
.PHONY: install
install:
	@./install_tools.sh
	@./install_python.sh
	@./install_vim.sh
	@./gitclone_list.sh

.PHONY: deploy
deploy:
	@./symlink.sh

.PHONY: testbuild
testbuild:
	docker-compose build

.PHONY: testrun
testrun:
	docker-compose run test

# .PHONY: d.txt
.PHONY: deploy
deploy:
	@./symlink.sh

.PHONY: install
install:
	@./install_tools.sh
	@./install_python.sh
	@./install_vim.sh
	@exec /bin/zsh -l
	@./gitclone_list.sh

.PHONY: publish
publish:
	docker-compose build

.PHONY: testrun
testrun:
	docker-compose run test

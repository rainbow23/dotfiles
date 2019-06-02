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

.PHONY: compbuild
build:
	docker-compose build

.PHONY: comprun
run:
	docker-compose run publish


.PHONY: base
base:
	docker  build --tag rainbow23/vim .

.PHONY: plugins
plugins:
	sh -c 'docker build -f Dockerfile.plugins --tag  rainbow23/vim:rainbow23 \
	--squash \
	--build-arg USERNAME=$(shell id -un) \
	--build-arg GROUPNAME=$(shell id -gn) \
	--build-arg UID=$(shell id -u) \
	--build-arg GID=$(shell id -g) \
	--build-arg WORKSPACE=$$HOME \
	--build-arg SHELL=/usr/zsh .'

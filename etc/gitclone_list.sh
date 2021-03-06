#!/bin/sh
gitname=("rainbow23/easy-oneliner.git" \
"rainbow23/dev-env-ansible-play-book.git"
"rainbow23/enhancd.git"
"rainbow23/study_golang.git" \
"rainbow23/vim-anzu.git" \
"rainbow23/vim-snippets" \
"peco/peco.git" \
"junegunn/fzf.git" \
"monochromegane/the_platinum_searcher.git" \
"rainbow23/vim-bookmarks.git" \"
"junegunn/fzf.vim.git" \
"ucan-lab/docker-laravel5.git" \
\  )

# unity project
# ghq get git@github.com:rainbow23/ChickDozerUnityProj.git

for i in ${gitname[@]} ; do
  $HOME/go/bin/ghq get "https://github.com/${i}"
  # echo "https://github.com/${i}"
done

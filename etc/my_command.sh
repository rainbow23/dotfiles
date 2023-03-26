#!/bin/sh

go-to-git-root-dir() {
  local rootDir currDir
  rootDir=$(git rev-parse --show-toplevel)
  currDir=$(pwd)

  cd "$rootDir"
  # cyan
  printf "\e[36m%s\n\e[m" "$currDir >> $rootDir"
}

git-commit-with-tmp-message() {
  commit_message=$(cat /tmp/git_commit_message)
  print -z "git commit -m \"$commit_message\""
  truncate -s 0 /tmp/git_commit_message
}

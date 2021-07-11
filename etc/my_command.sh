#!/bin/sh

go-to-git-root-dir() {
  local rootDir currDir
  rootDir=$(git rev-parse --show-toplevel)
  currDir=$(pwd)

  cd "$rootDir"
  # cyan
  printf "\e[36m%s\n\e[m" "$currDir >> $rootDir"
}

#!/bin/sh

go-to-git-root-dir() {
  local rootDir currDir
  rootDir=$(git rev-parse --show-toplevel)
  currDir=$(pwd)

  cd "$rootDir" && echo "$currDir >> $rootDir"
}

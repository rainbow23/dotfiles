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

adb-log-output() {
  TIMESTAMP=$(date "+%Y%m%d%H%M")
  adb logcat -c && adb logcat DOTNET:D *:S | tee "logcat_$(TIMESTAMP).log"
}

adb-log-output-all() {
  TIMESTAMP=$(date "+%Y%m%d%H%M")
  adb logcat -c && adb logcat | tee "logcat_$(TIMESTAMP).log"
}

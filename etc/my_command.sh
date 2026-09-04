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
  adb logcat -c && adb logcat DOTNET:D *:S | tee "logcat_${TIMESTAMP}.log"
}

adb-log-output-all() {
  TIMESTAMP=$(date "+%Y%m%d%H%M")
  adb logcat -c && adb logcat | tee "logcat_${TIMESTAMP}.log"
}

# adb 実行時に Git Bash のパス変換を無効化するラッパー
# Git Bash は /sdcard/... のようなパスを Windows パスに誤変換するため無効化する
# Mac/Linux ではそのまま adb を実行する
adb-run() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*)
      MSYS_NO_PATHCONV=1 adb "$@"
      ;;
    *)
      adb "$@"
      ;;
  esac
}

adb-screenshot() {
  local prefix="$1"
  TIMESTAMP=$(date "+%Y%m%d%H%M")
  if [ -n "$prefix" ]; then
    FILE_NAME="${prefix}_screenshot_${TIMESTAMP}.png"
  else
    FILE_NAME="screenshot_${TIMESTAMP}.png"
  fi
  REMOTE_PATH="/sdcard/${FILE_NAME}"
  LOCAL_PATH="./${FILE_NAME}"

  adb-run shell screencap -p "$REMOTE_PATH" \
    && adb-run pull "$REMOTE_PATH" "$LOCAL_PATH" \
    && adb-run shell rm "$REMOTE_PATH" \
    && echo "INFO: スクリーンショットを取得しました: '$LOCAL_PATH'"
}

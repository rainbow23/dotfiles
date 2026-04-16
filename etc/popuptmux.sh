#!/bin/sh

# 第1引数を変数に格納
currentDir="$1"
# echo "Received current directory: $currentDir"

if [ "$(tmux display-message -p -F "#{session_name}")" = "popup"  ];then
    tmux detach-client
  else
    # color list
    # https://qiita.com/nojima/items/9bc576c922da3604a72b
    if ! tmux has-session -t popup 2>/dev/null; then
      tmux new-session -d -s popup
      tmux set-option -t popup status-bg 'colour50'
    fi

    rootDir=$(git -C "$currentDir" rev-parse --show-toplevel 2>/dev/null)
    if [ ! -z "$rootDir" ]; then
      # セッションを切り替える前にコマンドを送信する
      # TTYのフォアグラウンドプロセスグループを確認し、シェル以外が実行中の場合は送信しない
      # fzf等のインタラクティブプログラムはフォアグラウンドグループに入るため確実に検出できる
      # zsh非同期プロンプトワーカーはバックグラウンドのため除外される
      pane_tty=$(tmux display-message -t popup -p '#{pane_tty}' 2>/dev/null)
      if [ -n "$pane_tty" ]; then
        fg_non_shell=$(ps -t "$pane_tty" -o stat=,comm= 2>/dev/null | awk '$1 ~ /\+/ && $2 !~ /^-?(zsh|bash|sh)$/ {print $2}')
        if [ -z "$fg_non_shell" ]; then
          tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'
        fi
      fi
    fi

    tmux popup -E -w95% -h95% 'tmux attach -t popup'
fi
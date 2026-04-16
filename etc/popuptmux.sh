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
      # シェルの子プロセスが存在する場合（vim・fzf等が実行中）は送信しない
      pane_pid=$(tmux display-message -t popup -p '#{pane_pid}' 2>/dev/null)
      if [ -n "$pane_pid" ] && [ -z "$(pgrep -P "$pane_pid")" ]; then
        tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'
      fi
    fi

    tmux popup -E -w95% -h95% 'tmux attach -t popup'
fi
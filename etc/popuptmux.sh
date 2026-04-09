#!/bin/sh

# 第1引数を変数に格納
currentDir="$1"
# echo "Received current directory: $currentDir"

if [ "$(tmux display-message -p -F "#{session_name}")" = "popup"  ];then
    tmux detach-client
  else
    cd $currentDir  #tmuxのインタラクティブシェルのディレクトリに移動
    rootDir=$(git rev-parse --show-toplevel)
    if [ ! -z "$rootDir" ]; then
      # セッション切り替え後にコマンドを送信すると実行できない場合があるので、セッションを切り替える前に送信する
      # vimが起動中の場合はパスの/がvim検索として解釈されるため、シェルの場合のみ送信する
      pane_cmd=$(tmux display-message -t popup -p '#{pane_current_command}' 2>/dev/null)
      if [ "$pane_cmd" = "zsh" ] || [ "$pane_cmd" = "bash" ] || [ "$pane_cmd" = "sh" ]; then
        tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'
      fi
    fi

    # color list
    # https://qiita.com/nojima/items/9bc576c922da3604a72b
    tmux new-session -d -s popup 2>/dev/null
    tmux set-option -t popup status-bg 'colour50'
    tmux popup -E -w95% -h95% 'tmux attach -t popup'
fi
#!/bin/sh

# 第1引数を変数に格納
currentDir="$1"
# echo "Received current directory: $currentDir"

if [ "$(tmux display-message -p -F "#{session_name}")" = "popup"  ];then
    tmux set-option -g status-bg 'colour218'
    tmux detach-client
  else
    cd $currentDir  #tmuxのインタラクティブシェルのディレクトリに移動
    rootDir=$(git rev-parse --show-toplevel)
    if [ ! -z "$rootDir" ]; then
      # セッション切り替え後にコマンドを送信すると実行できない場合があるので、セッションを切り替える前に送信する
      tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'
    fi

    # color list
    # https://qiita.com/nojima/items/9bc576c922da3604a72b
    tmux set-option -g status-bg 'colour50'
    # tmux new -s -> Start New Session With Name
    tmux popup -E -w100% -h99% 'tmux attach -t popup || tmux new -s popup'
fi
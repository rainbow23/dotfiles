if [ "$(tmux display-message -p -F "#{session_name}")" = "popup"  ];then
    tmux set-option -g status-bg 'colour218'
    tmux detach-client
  else
    rootDir=$(git rev-parse --show-toplevel)
    tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'

    # color list
    # https://qiita.com/nojima/items/9bc576c922da3604a72b
    tmux set-option -g status-bg 'colour50'
    # tmux new -s -> Start New Session With Name
    tmux popup -E -w100% -h99% 'tmux attach -t popup || tmux new -s popup'
fi
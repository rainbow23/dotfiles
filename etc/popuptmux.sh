if [ "$(tmux display-message -p -F "#{session_name}")" = "popup"  ];then
    tmux detach-client
  else
    tmux popup -E -w100% -h98% 'tmux attach -t popup || tmux new -s popup'
fi
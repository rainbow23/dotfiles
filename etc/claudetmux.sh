#!/bin/sh

currentDir="$1"
SESSION="z-claude-$(echo "$currentDir" | md5sum | cut -c1-8)"

if [ "$(tmux display-message -p -F '#{session_name}')" = "$SESSION" ]; then
    tmux detach-client
else
    tmux has-session -t "$SESSION" 2>/dev/null || \
    tmux new-session -d -s "$SESSION" -c "$currentDir" "claude"
    tmux display-popup -w80% -h80% -E "tmux attach-session -t $SESSION"
    tmux set-option -t "$SESSION" status-bg "colour210"
fi

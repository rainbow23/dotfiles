#!/bin/sh

currentDir="$1"
rootDir=$(git -C "$currentDir" rev-parse --show-toplevel 2>/dev/null)

if [ -z "$rootDir" ]; then
  rootDir="$currentDir"
fi

SESSION="z-claude-$(echo "$rootDir" | md5sum | cut -c1-8)"

if [ "$(tmux display-message -p -F '#{session_name}')" = "$SESSION" ]; then
    tmux detach-client
else
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
      tmux new-session -d -s "$SESSION" -c "$rootDir" "claude"
      tmux set-option -t "$SESSION" status-bg "colour210"
    fi
    tmux display-popup -w80% -h80% -E "tmux attach-session -t $SESSION"
fi

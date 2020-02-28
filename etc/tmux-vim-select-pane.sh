#!/bin/bash
# Like `tmux select-pane`, but sends a `<C-h/j/k/l>` keystroke if Vim is
# running in the current pane, or only one pane exists.
set -e

cmd="$(tmux display -p '#{pane_current_command}')"
cmd="$(basename "$cmd" | tr A-Z a-z)"
pane_count="$(printf %d $(tmux list-panes | wc -l))"
zoomed_pane_flag="$(tmux display -p '#{window_zoomed_flag}')"

if [[ "${cmd%m}" = "vi" || "${cmd%m}" = "nvi" || ($pane_count = 1) || ($zoomed_pane_flag = 1) ]]; then
  direction="$(echo "${1#-}" | tr 'lLDUR' '\\hjkl')"
  # forward the keystroke to Vim
  tmux send-keys "C-$direction"
else
  tmux select-pane "$@"
fi

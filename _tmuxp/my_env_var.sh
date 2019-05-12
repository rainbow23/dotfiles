#!/bin/sh
export TMUX_WINDOW_WIDTH=$(tmux display -p '#{window_width}')
export TMUX_WINDOW_WIDTH_HALF=$(expr $(tmux display -p '#{window_width}') / 2)
export TMUX_WINDOW_WIDTH_ONE_THIRD=$(expr $(echo $TMUX_WINDOW_WIDTH | bc) / 3)
# export THIRD=$(expr $(echo $COLUMNS | bc) / 3)


#!/bin/sh
## -------------------------------------
# zplugin
## -------------------------------------
ZPLUGIN=$HOME/.zplugin
if [ -d $ZPLUGIN ] ; then
  source $ZPLUGIN/zplugin.zsh
  autoload -Uz _zplugin
  (( ${+_comps} )) && _comps[zplugin]=_zplugin

  # zplugin ice from"gh-r" as"command"
  # zplugin load junegunn/fzf-bin
  zplugin light "b4b4r07/cli-finder"
  zplugin light hlissner/zsh-autopair
  zplugin ice as"command" pick"bin/grep-view"
  zplugin light m5d215/grep-view
  zplugin light momo-lab/zsh-abbrev-alias
  zplugin ice wait'0'
  zplugin light zsh-users/zsh-autosuggestions
  zplugin load zsh-users/zsh-completions
  zplugin light zsh-users/zsh-syntax-highlighting

  # Plugin history-search-multi-word loaded with tracking.
  # zplugin ice wait'!0'
  # zplugin load zdharma/history-search-multi-word

  zplugin light "nnao45/zsh-kubectl-completion"
  zplugin ice wait'0'
  zplugin light "b4b4r07/enhancd"
  export ENHANCD_FILTER=fzf-tmux

  zplugin light "b4b4r07/zsh-gomi"
  zplugin ice make'install'
  zplugin light "motemen/ghq"

  # zplugin light "supercrabtree/k"

  # snippet
  zplugin ice mv"b.rb -> chrome_bookmarks_with_fzf.rb" \
    pick"chrome_bookmarks_with_fzf.rb" as"program"
  zplugin snippet https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb
  alias b="chrome_bookmarks_with_fzf.rb"

  zplugin ice mv"httpstat.sh -> httpstat" \
    pick"httpstat" as"program"
  zplugin snippet \
    https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
fi

# zplugin light "mollifier/anyframe"

# ghq
if [ ! -f /usr/local/bin/ghq ]; then
  mkdir -p $HOME/.ghq
  export GHQ_ROOT=$HOME/.ghq
fi


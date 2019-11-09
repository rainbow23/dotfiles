#!/bin/sh
## -------------------------------------
# zplugin
## -------------------------------------
ZPLUGIN=$HOME/.zplugin
if [ -d $ZPLUGIN ] ; then
  source $ZPLUGIN/zplugin.zsh
  autoload -Uz _zplugin
  (( ${+_comps} )) && _comps[zplugin]=_zplugin
  # Binary release in archive, from GitHub-releases page.
  # After automatic unpacking it provides program "fzf".
  # zplugin ice from"gh-r" as"program"
  # zplugin load junegunn/fzf-bin
  zplugin light "b4b4r07/cli-finder"

  # zplugin ice from"gh-r" as"command"
  # zplugin load junegunn/fzf-bin
  zplugin load hlissner/zsh-autopair
  zplugin ice as"command" pick"bin/grep-view"
  zplugin load m5d215/grep-view
  zplugin load momo-lab/zsh-abbrev-alias
  zplugin ice wait'0'
  zplugin load zsh-users/zsh-autosuggestions
  zplugin load zsh-users/zsh-completions
  zplugin load zsh-users/zsh-syntax-highlighting
  # Plugin history-search-multi-word loaded with tracking.
  zplugin ice wait'!0'
  # zplugin load zdharma/history-search-multi-word

  zplugin ice mv"b.rb -> chrome_bookmarks_with_fzf.rb" \
          pick"chrome_bookmarks_with_fzf.rb" as"program"
  zplugin snippet https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb

  zplugin ice mv"httpstat.sh -> httpstat" \
          pick"httpstat" as"program"
  zplugin snippet \
      https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
fi

alias b="chrome_bookmarks_with_fzf.rb"



### Added by Zplugin's installer
# source "$HOME/.zplugin/bin/zplugin.zsh"
# autoload -Uz _zplugin
# (( ${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin's installer chunk
# zplugin load momo-lab/zsh-abbrev-alias # 略語を展開する
# zplugin load zsh-users/zsh-syntax-highlighting # 実行可能なコマンドに色付け
# zplugin load zsh-users/zsh-completions # 補完








# zplugin light "mollifier/anyframe"

# Binary release in archive, from GitHub-releases page. 
# After automatic unpacking it provides program "fzf".
zplugin ice from"gh-r" as"program"
zplugin load junegunn/fzf-bin

# zplugin light "b4b4r07/zsh-gomi", \
#     as:command, \
#     use:bin/gomi, \
#     on:junegunn/fzf
# zplugin light "nnao45/zsh-kubectl-completion"
# zplugin light "b4b4r07/enhancd", use:init.sh
# zplugin light "b4b4r07/cli-finder"
# zplugin light "zsh-users/zsh-syntax-highlighting"
# zplugin snippet  --command \
#   'https://gist.github.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0'

# zplugin light "b4b4r07/79ee61f7c140c63d2786", \
#     from:gist, \
#     as:command, \
#     use:get_last_pane_path.sh
# zplugin light "motemen/ghq", at:980d2b45 \
#     as:command, \
#     hook-build:"make install"



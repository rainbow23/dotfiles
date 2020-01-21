#!/bin/zsh
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
  # zplugin ice as"command" pick"bin/grep-view"
  # zplugin light m5d215/grep-view
  zplugin light momo-lab/zsh-abbrev-alias
  zplugin ice wait'0'
  zplugin light zsh-users/zsh-autosuggestions
  zplugin load zsh-users/zsh-completions
  zplugin light zsh-users/zsh-syntax-highlighting
  # zplugin light "mollifier/anyframe"

  # Plugin history-search-multi-word loaded with tracking.
  # zplugin ice wait'!0'
  # zplugin load zdharma/history-search-multi-word

  zplugin light "nnao45/zsh-kubectl-completion"
  zplugin ice wait'0'
  zplugin light "rainbow23/enhancd"
  export ENHANCD_FILTER=fzf-tmux

  zplugin light "b4b4r07/zsh-gomi"
  zplugin ice make'install'
  zplugin light "motemen/ghq"
  zplugin light "supercrabtree/k"

  # snippet
  zplugin ice mv"b.rb -> chrome_bookmarks_with_fzf.rb" \
    pick"chrome_bookmarks_with_fzf.rb" as"program"
  zplugin snippet https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb
  alias b="chrome_bookmarks_with_fzf.rb"

  zplugin ice mv"httpstat.sh -> httpstat" \
    pick"httpstat" as"program"
  zplugin snippet \
    https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
  zplugin ice as"program" pick"layout_manager.sh"
  zplugin light klaxalk/i3-layout-manager
  # zplugin ice as"program" pick"bin/git-dsf"
  # zplugin light zdharma/zsh-diff-so-fancy
  zplugin load "Aloxaf/fzf-tab"
fi

# ghq
if [ ! -f /usr/local/bin/ghq ]; then
  mkdir -p $HOME/.ghq
  export GHQ_ROOT=$HOME/.ghq
fi

: "略語展開(iab)" && {
  abbrev-alias gco="git commit -av"
  abbrev-alias ga="git add -A"
  abbrev-alias d="docker"
  abbrev-alias dc="docker-compose"
  abbrev-alias dp="docker ps"
  abbrev-alias di="docker images"
  abbrev-alias -g a1="awk '{print \$1}'"
  abbrev-alias -g a2="awk '{print \$2}'"
  abbrev-alias -g a3="awk '{print \$3}'"
  abbrev-alias -g a4="awk '{print \$4}'"
  abbrev-alias -g a5="awk '{print \$5}'"
  abbrev-alias -g a6="awk '{print \$6}'"
  abbrev-alias -g a7="awk '{print \$7}'"
  abbrev-alias -g a8="awk '{print \$8}'"
  abbrev-alias -g a9="awk '{print \$9}'"
  abbrev-alias -g a10="awk '{print \$10}'"
  abbrev-alias -g a11="awk '{print \$11}'"
  abbrev-alias -g a12="awk '{print \$12}'"
  abbrev-alias -g a13="awk '{print \$13}'"
  abbrev-alias -g a14="awk '{print \$14}'"
  abbrev-alias -g a15="awk '{print \$15}'"
  abbrev-alias -g a16="awk '{print \$16}'"
  abbrev-alias -g and="|" # パイプが遠いのでandを割り当てる。例えば`tail -f ./log | grep error`を`tail -f ./log and grep error`と書くことができる
}

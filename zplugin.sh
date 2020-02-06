#!/bin/zsh
## -------------------------------------
# zinit
## -------------------------------------
ZINIT=$HOME/.zinit
if [ -d $ZINIT ] ; then
  source $ZINIT/bin/zinit.zsh

  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # zinit ice from"gh-r" as"command"
  # zinit load junegunn/fzf-bin
  zinit light "b4b4r07/cli-finder"
  zinit light hlissner/zsh-autopair

  # zinit ice as"command" pick"bin/grep-view"
  # zinit light m5d215/grep-view

  zinit load momo-lab/zsh-abbrev-alias
  # zinit ice wait'0'
  zinit light zsh-users/zsh-autosuggestions
  zinit load zsh-users/zsh-completions
  zinit light zsh-users/zsh-syntax-highlighting
  # zinit light "mollifier/anyframe"

  # Plugin history-search-multi-word loaded with tracking.
  # zinit ice wait'!0'
  # zinit load zdharma/history-search-multi-word

  zinit light "nnao45/zsh-kubectl-completion"
  zinit ice wait'0'
  zinit light "rainbow23/enhancd"
  export ENHANCD_FILTER=fzf-tmux

  zinit light "b4b4r07/zsh-gomi"
  zinit ice make'install'
  zinit light "motemen/ghq"
  zinit light "supercrabtree/k"

  # snippet
  zinit ice mv"b.rb -> chrome_bookmarks_with_fzf.rb" \
    pick"chrome_bookmarks_with_fzf.rb" as"program"
  zinit snippet https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb
  alias b="chrome_bookmarks_with_fzf.rb"

  zinit ice mv"httpstat.sh -> httpstat" \
    pick"httpstat" as"program"
  zinit snippet \
    https://github.com/b4b4r07/httpstat/blob/master/httpstat.sh
  # zinit ice as"program" pick"bin/git-dsf"
  # zinit light zdharma/zsh-diff-so-fancy
  zinit load "Aloxaf/fzf-tab"
fi

# ghq
if [ ! -f /usr/local/bin/ghq ]; then
  mkdir -p $HOME/.ghq
  export GHQ_ROOT=$HOME/.ghq
fi

: "略語展開(iab)" && {
  abbrev-alias g="git"
  abbrev-alias gco="git commit "
  abbrev-alias ga="git add -u"
  abbrev-alias gl='git log'
  abbrev-alias glo='git log --oneline'
  abbrev-alias gls='git log --stat'
  abbrev-alias glg='git log --graph'
  abbrev-alias gs='git status'
  abbrev-alias gss='git stash save'
  abbrev-alias gc='git checkout'
  abbrev-alias gb='git branch'

  abbrev-alias d="docker"
  abbrev-alias db="docker build"
  abbrev-alias dc="docker container"
  abbrev-alias dcr="docker container run"
  abbrev-alias dcl="docker container ls"
  abbrev-alias dcp="docker container prune"
  abbrev-alias dcm="docker container rm"
  abbrev-alias dcs='docker container stats'
  abbrev-alias dp="docker ps"
  abbrev-alias dr="docker rm"
  abbrev-alias di="docker image"
  abbrev-alias dil='docker image ls'
  abbrev-alias dip='docker image prune'
  abbrev-alias dcom="docker-compose"

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

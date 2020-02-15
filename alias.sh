#!/bin/sh

alias hsn='hostname'
alias ez='exec zsh -l'

if [ -f /usr/local/bin/nvim ] ; then
  alias vim='/usr/local/bin/nvim'
fi

alias et='exit'
alias cl='clear'
## -------------------------------------
# docker operation
# -------------------------------------
alias dk='docker'
alias dkcls='docker container ls'
alias dkils='docker image ls'
alias dkr='docker container run'
alias dkcpr='docker container prune'
alias dkipr='docker image prune'
alias dkcs='docker container stats'
## -------------------------------------
# git operation
# -------------------------------------
alias gl='git log'
alias glo='git log --oneline'
alias gls='git log --stat'
alias glg='git log --graph'
alias gs='git status'
alias gss='git stash save'
alias gc='git checkout'
alias gd='clear && git diff'
alias gds='clear && git diff --staged'
alias gr='git reset'
alias gph='git push'
alias gpl='git pull'
alias gb='git branch'
alias gba='git branch --all'
alias gbr='git branch --remotes'
alias gv='git branch -vv'
alias fdr='finder'

## -------------------------------------
# abbrev-alias
## -------------------------------------
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
  abbrev-alias dil='docker image ls -a'
  abbrev-alias dib='docker image build'
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


## -------------------------------------
# tmux operation
# -------------------------------------
alias tx='tmux'
alias txl='tmux ls'
alias t="tmuximum"
alias b="chrome_bookmarks_with_fzf.rb"

# tree
alias tree="tree -NC" # N: 文字化け対策, C:色をつける
alias szsh='source ~/.zshrc'

#ansible
alias asbp='ansible-playbook'

# -n 行数表示, -I バイナリファイル無視, svn関係のファイルを無視
alias grep="grep --color -n -I --exclude='*.svn-*' --exclude='entries' --exclude='*/cache/*'"

# ls
alias ls="ls -G" # color for darwin

# lsがカラー表示になるようエイリアスを設定
case "${OSTYPE}" in
darwin*)
  # Mac
  alias ls="ls -GF"
  alias l="ls -la -GF"
  alias la="ls -la -GF"
  alias l1="ls -1 -GF"
  ;;
linux*)
  # Linux
  alias ls='ls -F --color'
  alias l="ls -l -color"
  alias la="ls -la -color"
  alias l1="ls -1 -color"
  ;;
esac

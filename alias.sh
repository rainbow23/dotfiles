#!/bin/sh

alias hsn='hostname'
alias ez='exec zsh -l'
alias vim='nvim'
alias et='exit'
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
alias gc='git checkout'
alias gd='git diff'
alias gds='git diff --staged'
alias gr='git reset'
alias gph='git push'
alias gpl='git pull'
alias gb='git branch'
alias gba='git branch --all'
alias gbr='git branch --remotes'
alias gv='git branch -vv'
alias fdr='finder'

## -------------------------------------
# tmux operation
# -------------------------------------
alias tx='tmux'
alias txl='tmux ls'
alias t="tmuximum"
alias b="chrome_bookmarks_with_fzf.rb"
## -------------------------------------
# ZSH_HISTORY
# -------------------------------------
# コマンド履歴
HISTFILE=~/.zsh_history
HISTSIZE=6000000
SAVEHIST=6000000
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data

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

#!/bin/sh

## -------------------------------------
# git operation
# -------------------------------------
alias gl='git log --reverse'
alias glo='git log --oneline --reverse'
alias gls='git log --stat --reverse'
alias glg='git log --graph'
alias gs='git status'
alias gc='git checkout'
alias gd='git diff'
alias gr='git reset'
alias gp='git push'
alias gb='git branch'

alias fdr='finder'

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
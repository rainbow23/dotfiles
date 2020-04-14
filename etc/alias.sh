#!/bin/sh

alias hsn='hostname'
alias ez='exec zsh -l'

if [ -f /usr/local/bin/nvim ] ; then
  alias vim='/usr/local/bin/nvim'
elif [ -f /usr/bin/vim ] ; then
  alias vim='/usr/bin/vim'
fi

alias et='exit'
alias cl='clear'

## -------------------------------------
# abbrev-alias
## -------------------------------------
: "略語展開(iab)" && {
  ## ------------------------------------
  # git operation
  # -------------------------------------
  abbrev-alias g="git"
  abbrev-alias gd='clear && git diff'
  abbrev-alias gds='clear && git diff --staged'
  abbrev-alias gph='git push'
  abbrev-alias gpl='git pull'
  abbrev-alias gb='git branch'
  abbrev-alias gba='git branch --all'
  abbrev-alias gbr='git branch --remotes'
  abbrev-alias gv='git branch -vv'
  abbrev-alias gcm="git commit -m"
  abbrev-alias gau="git add -u"
  abbrev-alias ga='git-add-files'
  abbrev-alias gl='git log'
  abbrev-alias glo='git log --oneline'
  abbrev-alias gls='git log --stat'
  abbrev-alias glg='git log --graph'
  abbrev-alias gs='git status'
  abbrev-alias gss='git stash save'
  abbrev-alias gsl='git-stash-list'
  abbrev-alias gsp='git-commit-show-preview'
  abbrev-alias gsh='git-commit-show'
  abbrev-alias gc='git checkout'
  abbrev-alias gr='git rebase '
  abbrev-alias gri='git rebase -i'

  ## ------------------------------------
  # docker operation
  # -------------------------------------
  abbrev-alias d="docker"
  abbrev-alias db="docker build"
  abbrev-alias dc="docker container"
  abbrev-alias dce="docker container exec -it"
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

  ## -------------------------------------
  # tmux operation
  # -------------------------------------
  abbrev-alias -g t='tmux'
  abbrev-alias -g tm='tmux-session'
  abbrev-alias -g ts='tmux-select-session'
  abbrev-alias -g tks='tmux-kill-session'
  abbrev-alias -g tl='tmux-list-panes'

  ## -------------------------------------
  # fzf fd
  # -------------------------------------
  abbrev-alias -g fdg='cd-to-ghq-selected-directory'
  abbrev-alias -g fd='fd-selected-directory'
  abbrev-alias -g fdo='fd-selected-sub-directory'
  abbrev-alias -g fdp='fd-selected-parent-directory'

  ## -------------------------------------
  # ls
  # -------------------------------------
  abbrev-alias -g ll="ls -latr"

  abbrev-alias -g c='browse-chrome-history'
}

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

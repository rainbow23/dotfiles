#!/bin/sh

# autojump
[[ -s $HOME/.autojump/etc/profile.d/autojump.sh ]] && source $HOME/.autojump/etc/profile.d/autojump.sh

## -------------------------------------
# fzf
# -------------------------------------
if [ -d $HOME/.fzf ] ; then
  if [  -n "$ZSH_NAME" ] ; then
      # echo 'running zsh';
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh;
  else
      # echo 'running bash';
      [ -f ~/.fzf.bash ] && source ~/.fzf.bash;
  fi
fi

# anyenv
if [ -d $HOME/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    eval "$(anyenv init - zsh)"
fi

# goenv
if [ -d $HOME/.anyenv/envs/goenv ] ; then
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin
    eval "$(goenv init - zsh)"
fi

# pyenv
if [ -d $HOME/.anyenv/envs/pyenv ] ; then
    export PATH="$HOME/.anyenv/envs/pyenv/bin:$PATH"
    eval "$(pyenv init - zsh)"
fi

# pyenv-virtualenv
if [ -d $HOME/.anyenv/envs/pyenv/plugins/pyenv-virtualenv ] ; then
    eval "$(pyenv virtualenv-init -)"
fi

# easy-oneliner
if [ -d $HOME/.easy-oneliner ] ; then
  source $HOME/.easy-oneliner/easy-oneliner.zsh
fi

# enhancd
if [ -d $HOME/enhancd ] ; then
   source $HOME/enhancd/init.sh
fi

# zsh-syntax-highlighting
if [ -d $HOME/zsh-syntax-highlighting ] ; then
  source $HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -z $TMUX ]; then
    tmuximum
fi

if [ ! -f $HOME/.chrome_bookmarks_with_fzf.rb ] ; then
    source $HOME/.chrome_bookmarks_with_fzf.rb
fi

if [ ! -f $HOME/diff-so-fancy ] ; then
    source $HOME/diff-so-fancy
fi

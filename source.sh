#!/bin/sh

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOBIN

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

GOMI=$HOME/.zsh-gomi
if [ -d $GOMI ] ; then
    source $GOMI/gomi.zsh
fi

if [ ! -f ghq ]; then
  go get github.com/motemen/ghq
fi

# zsh-completions
COMPLETIONS=$HOME/.zsh/completions
if [ -e $COMPLETIONS ]; then
  fpath=($COMPLETIONS $fpath)
fi

source $COMPLETIONS/docker-fzf-completion/docker-fzf.zsh
export FZF_COMPLETION_TRIGGER="," # default: '**'
autoload -U compinit
compinit

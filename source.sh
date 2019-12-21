#!/bin/sh
if [ -f /usr/local/bin/diff-so-fancy ] ; then
  git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
  git config --global color.diff-highlight.oldNormal    "red bold"
  git config --global color.diff-highlight.oldHighlight "red bold 52"
  git config --global color.diff-highlight.newNormal    "green bold"
  git config --global color.diff-highlight.newHighlight "green bold 22"
  git config --global color.diff.meta       "yellow"
  git config --global color.diff.frag       "magenta bold"
  git config --global color.diff.commit     "yellow bold"
  git config --global color.diff.old        "red bold"
  git config --global color.diff.new        "green bold"
  git config --global color.diff.whitespace "red reverse"
fi

#ctags settings
git config --global init.templatedir '~/.git_template'
git config --global alias.ctags '!~/dotfiles/copy_ctags_files && .git/hooks/ctags'

## -------------------------------------
# go
# -------------------------------------
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOBIN

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
export FZF_COMPLETION_TRIGGER=''
bindkey '^T' fzf-completion
bindkey '^I' $fzf_default_completion

## -------------------------------------
# nnn
## -------------------------------------
export NNN_BMS='d:~/Documents;u:/home/user/Cam Uploads;D:~/Downloads/'
export NNN_USE_EDITOR=1
export NNN_FALLBACK_OPENER=xdg-open
export NNN_DE_FILE_MANAGER=vim

## -------------------------------------
# enhancd
# -------------------------------------
ENHANCD=$HOME/.enhancd
if [ -e $ENHANCD ]; then
  source $ENHANCD/init.sh
fi


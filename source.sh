#!/bin/sh
source ~/.zplug/init.zsh

zplug "mollifier/anyframe", at:4c23cb60

# Install zsh-gomi with fzf
# zplug "junegunn/fzf-bin", \
#     as:command, \
#     from:gh-r, \
#     rename-to:"fzf", \
#     frozen:1

# diff-so-fancy/third_party/build_fatpack/diff-so-fancy
zplug "so-fancy/diff-so-fancy/master/third_party/build_fatpack", \
    from:gist, \
    use:diff-so-fancy, \
    as:command

# zplug "b4b4r07/zsh-gomi", if:"which fzf"
zplug "b4b4r07/zsh-gomi", \
    as:command, \
    use:bin/gomi, \
    on:junegunn/fzf-bin

  # curl -L https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -o $HOME/diff-so-fancy \
  # && chmod 755 $HOME/diff-so-fancy



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

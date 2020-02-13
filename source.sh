#!/bin/sh

## -------------------------------------
# git
# -------------------------------------
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
# enhancd
# -------------------------------------
ENHANCD=$HOME/.enhancd
if [ ! -d $ENHANCD ] ; then
  mkdir -p $ENHANCD
  git clone --depth 1 https://github.com/rainbow23/enhancd.git $ENHANCD
fi
source $ENHANCD/init.sh
export ENHANCD_FILTER=fzf-tmux

## -------------------------------------
# fzf
# -------------------------------------
if [ ! -f $HOME/.fzf/bin/fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  yes | $HOME/.fzf/install
fi

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
# easy-oneliner
## -------------------------------------
if [ ! -d $HOME/.easy-oneliner ] ; then
  git clone --depth 1 https://github.com/rainbow23/easy-oneliner.git ~/.easy-oneliner
fi
source $HOME/.easy-oneliner/easy-oneliner.zsh

## -------------------------------------
# ZSH-AUTOPAIR
## -------------------------------------
ZSH_AUTOPAIR=$HOME/.zsh-autopair
if [[ ! -d $ZSH_AUTOPAIR ]]; then
  mkdir -p $ZSH_AUTOPAIR
  git clone --depth 1 https://github.com/hlissner/zsh-autopair $ZSH_AUTOPAIR
fi
source $ZSH_AUTOPAIR/autopair.zsh
autopair-init

## -------------------------------------
# ZSH_AUTOSUGGESTIONS
# -------------------------------------
ZSH_AUTOSUGGESTIONS=$HOME/.zsh/zsh_autosuggestions
if [ ! -d $ZSH_AUTOSUGGESTIONS ] ; then
  mkdir -p $ZSH_AUTOSUGGESTIONS
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_AUTOSUGGESTIONS
fi
source $ZSH_AUTOSUGGESTIONS/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=45,bold"
bindkey '^ ' autosuggest-accept
bindkey '^f' autosuggest-fetch
bindkey '^d' autosuggest-disable

## -------------------------------------
# ZSH_COMPLETIONS
# -------------------------------------
ZSH_COMPLETIONS=$HOME/.zsh/zsh_completions
if [ ! -d $ZSH_COMPLETIONS ] ; then
  mkdir -p $ZSH_COMPLETIONS
  git clone --depth 1 git://github.com/zsh-users/zsh-completions.git $ZSH_COMPLETIONS
fi
fpath=($ZSH_COMPLETIONS/src $fpath)

## -------------------------------------
# ZSH_SYNTAX_HIGHLIGHTING
## -------------------------------------
ZSH_SYNTAX_HIGHLIGHTING=$HOME/.zsh/zsh-syntax-highlighting
if [ ! -d $ZSH_SYNTAX_HIGHLIGHTING ] ; then
  mkdir -p $ZSH_SYNTAX_HIGHLIGHTING
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_SYNTAX_HIGHLIGHTING
fi
source $ZSH_SYNTAX_HIGHLIGHTING/zsh-syntax-highlighting.zsh

# -------------------------------------
# docker補完設定
# -------------------------------------
ZSHCOMPLETION=$HOME/.zsh/completion
if [ ! -d $ZSHCOMPLETION ]; then
  mkdir -p $ZSHCOMPLETION
fi
# https://docs.docker.com/compose/completion/
if [ ! -f $ZSHCOMPLETION/_docker ] ; then
  curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > $ZSHCOMPLETION/_docker
fi
# https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
if [ ! -f $ZSHCOMPLETION/_docker-compose ] ; then
  curl -L https://raw.githubusercontent.com/docker/compose/1.25.0/contrib/completion/zsh/_docker-compose > $ZSHCOMPLETION/_docker-compose
fi
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

## -------------------------------------
# FZF-TAB
## -------------------------------------
FZF_TAB=$HOME/.fzf-tab
if [ ! -d $FZF_TAB ] ; then
  mkdir $FZF_TAB
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git $FZF_TAB
fi

if [ -f $FZF_TAB/fzf-tab.plugin.zsh ] ; then
  echo "check fzf-tab"
  source $FZF_TAB/fzf-tab.plugin.zsh
fi

# autoload -U compinit && compinit

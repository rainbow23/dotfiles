#!/bin/zsh

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
git config --global alias.ctags '!~/dotfiles/etc/copy_ctags_files && .git/hooks/ctags'

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
ZSH_AUTOSUGGESTIONS=$HOME/.zsh_autosuggestions
if [ ! -d $ZSH_AUTOSUGGESTIONS ] ; then
  mkdir -p $ZSH_AUTOSUGGESTIONS
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_AUTOSUGGESTIONS
fi
source $ZSH_AUTOSUGGESTIONS/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=45,bold"
bindkey '^j' autosuggest-accept
bindkey '^f' autosuggest-fetch
bindkey '^d' autosuggest-disable

ZSH_ABBREV_ALIAS=$HOME/.abbrev_alias
if [ ! -d $ZSH_ABBREV_ALIAS ] ; then
  mkdir -p $ZSH_ABBREV_ALIAS
  git clone --depth 1 https://github.com/momo-lab/zsh-abbrev-alias.git $ZSH_ABBREV_ALIAS
fi
source $ZSH_ABBREV_ALIAS/abbrev-alias.plugin.zsh

# -------------------------------------
# supercrabtree/k
# -------------------------------------
SUPERCRABTREE_K=$HOME/.k
if [ ! -d $SUPERCRABTREE_K ] ; then
  mkdir -p $SUPERCRABTREE_K
  git clone --depth 1 https://github.com/supercrabtree/k.git $SUPERCRABTREE_K
fi
source $SUPERCRABTREE_K/k.sh

## -------------------------------------
# ZSH_SYNTAX_HIGHLIGHTING
## -------------------------------------
ZSH_SYNTAX_HIGHLIGHTING=$HOME/.zsh/zsh-syntax-highlighting
if [ ! -d $ZSH_SYNTAX_HIGHLIGHTING ] ; then
  mkdir -p $ZSH_SYNTAX_HIGHLIGHTING
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_SYNTAX_HIGHLIGHTING
fi
source $ZSH_SYNTAX_HIGHLIGHTING/zsh-syntax-highlighting.zsh

## -------------------------------------
# ZSH_COMPLETIONS
# -------------------------------------
ZSHCOMPLETION=$HOME/.zsh/completion

if [ ! -d $ZSHCOMPLETION ] ; then
  mkdir -p $ZSHCOMPLETION
  git clone --depth 1 git://github.com/zsh-users/zsh-completions.git $ZSHCOMPLETION/zsh_completions
fi

# docker補完設定
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
fpath=($ZSHCOMPLETION(N-/) $fpath)

## -------------------------------------
# FZF-TAB
## -------------------------------------
FZF_TAB=$HOME/.fzf-tab
if [ ! -d $FZF_TAB ] ; then
  mkdir $FZF_TAB
  git clone https://github.com/Aloxaf/fzf-tab.git $FZF_TAB
fi

if [ -f $FZF_TAB/fzf-tab.plugin.zsh ] ; then
  ostype=$($HOME/dotfiles/etc/ostype.sh)

  # macで動作するコミットに移動
  if [ $ostype = 'darwin' ]; then
    CURRPATH=$(pwd)
    cd $FZF_TAB
    git checkout 1738f67018c48b7a1a3f8ce378264e88404d4e79
    cd $CURRPATH
    unset CURRPATH
  fi

  source $FZF_TAB/fzf-tab.plugin.zsh
fi

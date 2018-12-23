#!/bin/sh

mkdir -p -m 744 $HOME/.config/nvim
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc $HOME/.vimrc
ln -sfn $HOME/dotfiles/_bashrc $HOME/.bashrc
ln -sfn $HOME/dotfiles/_zshrc $HOME/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf $HOME/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

git config --global color.ui true

#go
if [ ! -d /usr/local/go/bin ]; then
  cd /usr/local/src
  sudo wget https://storage.googleapis.com/golang/go1.11.4.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.11.4.linux-amd64.tar.gz
  # cat 'export PATH=$PATH:/usr/local/go/bin' > $HOME/.profile
fi

if [ ! -d $HOME/go ]; then
  mkdir -p $HOME/go/bin
fi

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin

GHQ=$HOME/ghq
if [ ! -d $GHQ ]; then
  git clone https://github.com/motemen/ghq $GHQ
  cd $GHQ && make install
fi

# tmux
if [ ! -d $HOME/tmux ]; then
  git clone --depth 1 https://github.com/tmux/tmux.git $HOME/tmux
  cd $HOME/tmux
  # checkout latest tag
  git checkout $(git tag | sort -V | tail -n 1)
  sh autogen.sh
  ./configure
  make -j4
  sudo make install
fi

# fzf
if [ ! -d $HOME/.fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  $HOME/.fzf/install
fi

# easy-oneliner
if [ ! -d $HOME/.easy-oneliner ] ; then
  git clone --depth 1 https://github.com/rainbow23/easy-oneliner.git $HOME/.easy-oneliner
  source $HOME/.easy-oneliner/easy-oneliner.zsh
else
  currwd=$PWD
  cd $HOME/.easy-oneliner
  echo "git pull in $(echo $HOME/.easy-oneliner)"
  git pull
  cd "$currwd"
fi

# enhancd
if [ ! -d $HOME/enhancd ] ; then
  git clone --depth 1 https://github.com/rainbow23/enhancd.git $HOME/enhancd
fi

# cli-finder
if [ ! -f /usr/local/bin/finder ] ; then
  sudo sh -c "curl https://raw.githubusercontent.com/b4b4r07/cli-finder/master/bin/finder -o /usr/local/bin/finder && chmod +x /usr/local/bin/finder"
fi

# autojump
if [ ! -d $HOME/autojump ] ; then
  git clone --depth 1 git://github.com/wting/autojump.git  $HOME/autojump
  cd $HOME/autojump
  ./install.py
fi

# zsh-syntax-highlighting
if [ ! -d $HOME/zsh-syntax-highlighting ] ; then
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/zsh-syntax-highlighting
fi

SILVER_SEARCHER=$HOME/the_silver_searcher
if [ ! -f /usr/local/bin/ag ] ; then
  if [ ! -d $SILVER_SEARCHER ]; then
    git clone --depth 1 https://github.com/ggreer/the_silver_searcher.git $HOME/the_silver_searcher
  fi

  cd $SILVER_SEARCHER && ./build.sh
  sudo make install
fi

# b - browse Chrome bookmarks with fzf
# https://gist.github.com/junegunn/15859538658e449b886f
if [ ! -f /usr/local/bin/.chrome_bookmarks_with_fzf.rb ] ; then
  sudo sh -c "curl -L https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb -o /usr/local/bin/.chrome_bookmarks_with_fzf.rb \
  && chmod 755 /usr/local/bin/.chrome_bookmarks_with_fzf.rb"
fi

if [ ! -f /usr/local/bin/diff-so-fancy ] ; then
  sudo sh -c "curl -L https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -o /usr/local/bin/diff-so-fancy \
  && chmod +x /usr/local/bin/diff-so-fancy"
fi

GOMI=$HOME/.zsh-gomi
if [ ! -d $GOMI ] ; then
  git clone --depth 1 https://github.com/b4b4r07/zsh-gomi.git $GOMI
fi

ZSH_COMPLETIONS=$HOME/.zsh-completions
if [ ! -d $ZSH_COMPLETIONS ] ; then
  mkdir -p $ZSH_COMPLETIONS
  git clone --depth 1 git://github.com/zsh-users/zsh-completions.git $ZSH_COMPLETIONS
fi

COMPLETIONS=$HOME/.zsh/completions
if [ ! -d $COMPLETIONS ] ; then
  mkdir -p $COMPLETIONS
fi

if [ ! -d $COMPLETIONS/docker-fzf-completion ]; then
  git clone --depth 1 https://github.com/kwhrtsk/docker-fzf-completion.git $COMPLETIONS/docker-fzf-completion
fi

# vimPlug install
vim +PlugInstall +qall

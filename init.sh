#!/bin/sh

mkdir -p -m 744 $HOME/.config/nvim
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc ~/.vimrc
ln -sfn $HOME/dotfiles/_bashrc ~/.bashrc
ln -sfn $HOME/dotfiles/_zshrc ~/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf ~/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

# git
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

# GHQ=$HOME/ghq
# if [ ! -d $GHQ ]; then
#   git clone https://github.com/motemen/ghq $GHQ
#   cd $GHQ && make install
# fi

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

if [ ! -d $HOME/.zplug ] ; then
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

if [ ! -f /usr/local/bin/ag ] ; then
  git clone https://github.com/ggreer/the_silver_searcher.git ~/the_silver_searcher
  cd ~/the_silver_searcher && ./build.sh
  sudo make install
fi

# vimPlug install
vim +PlugInstall +qall

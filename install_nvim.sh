#!/bin/sh

# neovim
if [ ! -f /usr/local/bin/nvim ] ; then
  NEOVIM_PATH=$HOME/neovim
  if [ ! -d $NEOVIM_PATH ]; then
    mkdir -p $NEOVIM_PATH
    git clone --depth 1 https://github.com/tmux/tmux.git $HOME/tmux $NEOVIM_PATH
  fi
  cd $NEOVIM_PATH
  make CMAKE_BUILD_TYPE=Release
  sudo make install

  # vim-plug
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

vim +silent +GoInstallBinaries +qall

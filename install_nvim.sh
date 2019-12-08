#!/bin/bash
ostype=$($HOME/dotfiles/ostype.sh)

# ubuntu
if [ $ostype = 'ubuntu' ] ; then
  sudo add-apt-repository ppa:neovim-ppa/stable
  sudo apt-get update
  sudo apt-get install neovim
  exit
fi

# neovim
if [ ! -f /usr/local/bin/nvim ] ; then
  NEOVIM_PATH=$HOME/neovim
  if [ ! -d $NEOVIM_PATH ]; then
    mkdir -p $NEOVIM_PATH
    git clone --depth 1 https://github.com/neovim/neovim.git $NEOVIM_PATH
  fi
  cd $NEOVIM_PATH
  make CMAKE_BUILD_TYPE=Release
  sudo make install

  # vim-plug
  NEOVIM_VIM_PLUG_PATH=$HOME/.local/share/nvim/site/autoload
  if [ ! -d $NEOVIM_VIM_PLUG_PATH ]; then
    mkdir -p $NEOVIM_VIM_PLUG_PATH
  fi

  ln -sfn $HOME/.vim/autoload/plug.vim "${NEOVIM_VIM_PLUG_PATH}/plug.vim"
  nvim +silent +UpdateRemotePlugin +qall
fi

if [ -d $NEOVIM_PATH ]; then
  sudo rm -rf $NEOVIM_PATH
fi

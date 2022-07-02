#!/bin/sh
ostype=$($HOME/dotfiles/etc/ostype.sh)
if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""

  if [ ! -f /usr/local/bin/nvim ] ; then
    NEOVIM_PATH=$HOME/neovim
    if [ ! -d $NEOVIM_PATH ]; then
      mkdir -p $NEOVIM_PATH
      git clone --depth 1 https://github.com/neovim/neovim.git $NEOVIM_PATH
    fi
    cd $NEOVIM_PATH
    make CMAKE_BUILD_TYPE=Release
    sudo make install
  fi
  if [ -d $NEOVIM_PATH ]; then
    sudo rm -rf $NEOVIM_PATH
  fi
elif [ $ostype = 'darwin' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""
  brew install nvim
fi

# vim-plug
NEOVIM_VIM_PLUG_PATH=$HOME/.local/share/nvim/site/autoload
if [ ! -d $NEOVIM_VIM_PLUG_PATH ]; then
  mkdir -p $NEOVIM_VIM_PLUG_PATH
fi

ln -sfn $HOME/.vim/autoload/plug.vim "${NEOVIM_VIM_PLUG_PATH}/plug.vim"
nvim +silent +UpdateRemotePlugin +qall


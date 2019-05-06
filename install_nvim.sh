#!/bin/sh

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
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

/usr/local/bin/nvim +slient +PlugInstall +qall
/usr/local/bin/nvim +silent +GoInstallBinaries +qall
/usr/local/bin/nvim +silent +UpdateRemotePlugin +qall

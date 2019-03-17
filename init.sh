#!/bin/sh
sudo chsh $USER -s /bin/zsh 2>/dev/null
INSTALL_DIR=$HOME/dotfiles

if [[ ! -d $INSTALL_DIR ]]; then
  git clone https://github.com/rainbow23/dotfiles.git $INSTALL_DIR
fi

cd $INSTALL_DIR
make deploy
make install

#!/bin/sh
sudo chsh $USER -s /bin/zsh 2>/dev/null
INSTALL_DIR=$HOME/dotfiles

if [[ ! -d $INSTALL_DIR ]]; then
  mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
  git clone https://github.com/rainbow23/dotfiles.git
# git checkout develop
fi

make deploy

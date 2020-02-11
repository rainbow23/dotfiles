#!/bin/sh

ZSH_INSTALL_DIR=$HOME/zsh_install
mkdir $ZSH_INSTALL_DIR && cd $ZSH_INSTALL_DIR
wget https://sourceforge.net/projects/zsh/files/zsh/5.7.1//zsh-5.7.1.tar.xz/download -O zsh-5.7.1.tar.xz
tar xvf  zsh-5.7.1.tar.xz
cd zsh-5.7.1
./configure --enable-multibyte
sudo make && sudo make install

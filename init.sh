#!/bin/sh
sudo chsh $USER -s /bin/zsh 2>/dev/null
INSTALL_DIR=$HOME/dotfiles

if [[ ! -d $INSTALL_DIR ]]; then
  mkdir -p $INSTALL_DIR && cd $INSTALL_DIR
  git clone https://github.com/rainbow23/dotfiles.git
# git checkout develop
fi

mkdir -p -m 744 $HOME/.config/nvim

#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc $HOME/.vimrc
ln -sfn $HOME/dotfiles/_bashrc $HOME/.bashrc
ln -sfn $HOME/dotfiles/_zshrc $HOME/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf $HOME/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

make deploy

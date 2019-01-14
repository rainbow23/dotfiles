#!/bin/sh
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc $HOME/.vimrc
ln -sfn $HOME/dotfiles/_bashrc $HOME/.bashrc
ln -sfn $HOME/dotfiles/_zshrc $HOME/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf $HOME/.tmux.conf
mkdir -p -m 744 $HOME/.config/nvim
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

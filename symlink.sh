#!/bin/sh
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc $HOME/.vimrc
ln -sfn $HOME/dotfiles/_bashrc $HOME/.bashrc
ln -sfn $HOME/dotfiles/zsh/_zshrc $HOME/.zshrc
ln -sfn $HOME/dotfiles/zsh/_zshenv $HOME/.zshenv
ln -sfn $HOME/dotfiles/_ideavimrc $HOME/.ideavimrc
ln -sfn $HOME/dotfiles/_tmux.conf $HOME/.tmux.conf
ln -sfn $HOME/dotfiles/_tmuxp  $HOME/.tmuxp
# nvim は lua/ モジュールを含むためディレクトリごとリンクする
# 既存の実ディレクトリが残っていると nvim/nvim という入れ子リンクができるため退避する
if [ -d $HOME/.config/nvim ] && [ ! -L $HOME/.config/nvim ]; then
    mv $HOME/.config/nvim $HOME/.config/nvim.bak
fi
ln -sfn $HOME/dotfiles/nvim $HOME/.config/nvim

#karabiner設定を追加
ln -sfn ~/dotfiles/etc/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

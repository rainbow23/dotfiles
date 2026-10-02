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

ln -sfn $HOME/dotfiles/_tigrc $HOME/.tigrc

# zellij 設定
mkdir -p $HOME/.config/zellij
ln -sfn $HOME/dotfiles/zellij/config.kdl $HOME/.config/zellij/config.kdl

# karabiner 設定
# karabiner.json はアトミックに書き換えられファイル単位のリンクが外れるため、ディレクトリごとリンクする
if [ -d $HOME/.config/karabiner ] && [ ! -L $HOME/.config/karabiner ]; then
    mv $HOME/.config/karabiner $HOME/.config/karabiner.bak
fi
ln -sfn $HOME/dotfiles/etc/karabiner $HOME/.config/karabiner

# iTerm2 メニューショートカット
sh $HOME/dotfiles/etc/iterm2/keybindings.sh

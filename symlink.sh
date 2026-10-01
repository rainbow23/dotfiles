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

# zellij プラグイン（vim-zellij-navigator PR#34 のローカルビルド）
# GitBash/Windows でのみ配置する
#   - Windows ではシンボリックリンクを zellij が辿れないため cp で実体を置く
#   - mac/Linux は Ctrl+hjkl を smart-splits.nvim 側で処理できるため不要
case "$(uname -s)" in
    MINGW* | MSYS*)
        mkdir -p $HOME/.config/zellij/plugins
        cp -f $HOME/dotfiles/zellij/plugins/vim-zellij-navigator-pr34.wasm \
              $HOME/.config/zellij/plugins/vim-zellij-navigator-pr34.wasm
        ;;
esac

#karabiner設定を追加
ln -sfn ~/dotfiles/etc/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

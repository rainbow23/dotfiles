#!/bin/sh

mkdir -p -m 744 $HOME/.config/nvim
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc ~/.vimrc
ln -sfn $HOME/dotfiles/_bashrc ~/.bashrc
ln -sfn $HOME/dotfiles/_zshrc ~/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf ~/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

# if [ ! -d ~/.anyenv ] ; then
#   git clone https://github.com/riywo/anyenv ~/.anyenv
#   export PATH="$HOME/.anyenv/bin:$PATH"
#   eval "$(anyenv init -)"
#   source $HOME/dotfiles/source.sh
# fi

# export goenv_ver=1.8.3
# if [ ! -d $HOME/.anyenv/envs/goenv ] ; then
#   anyenv install goenv
#   source $HOME/dotfiles/source.sh

#   goenv install "$goenv_ver"
#   goenv global "$goenv_ver"
#   goenv rehash
# fi

# export pyenv_ver=3.6.0
# if [ ! -d $HOME/.anyenv/envs/pyenv ] ; then
#   anyenv install pyenv
#   if [ ! -d $HOME/.anyenv/envs/pyenv/plugins/pyenv-virtualenv ] ; then
#     git clone https://github.com/yyuu/pyenv-virtualenv.git $HOME/.anyenv/envs/pyenv/plugins/pyenv-virtualenv
#   fi
# source $HOME/dotfiles/source.sh
# fi


# if [ ! -d $HOME/.anyenv/envs/pyenv/versions/2.7.6 ] ; then
#   # CONFIGURE_OPTS="--enable-shared" pyenv install 2.7.6
#   pyenv install 2.7.6
# fi

# if [ ! -d $HOME/.anyenv/envs/pyenv/versions/"$pyenv_ver" ] ; then
#   # CONFIGURE_OPTS="--enable-shared" pyenv install "$pyenv_ver"
#   pyenv install "$pyenv_ver"
# fi
# # pyenv install "$pyenv_ver"

# pyenv local --unset
# pyenv shell --unset
# pyenv global 2.7.6 "$pyenv_ver"
# pyenv versions
# # python --version
# # python3 --version
# pyenv global "$pyenv_ver"
# pyenv rehash

# pip3 install --upgrade neovim

# source $HOME/dotfiles/source.sh

# tmux
if [ ! -d $HOME/tmux ]; then
  git clone https://github.com/tmux/tmux.git ~/tmux
  cd $HOME/tmux
  # checkout latest tag
  git checkout $(git tag | sort -V | tail -n 1)
  sh autogen.sh
  ./configure
  make -j4
  sudo make install
fi

# fzf
if [ ! -d $HOME/.fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  $HOME/.fzf/install
fi

# easy-oneliner
if [ ! -d $HOME/.easy-oneliner ] ; then
  git clone https://github.com/rainbow23/easy-oneliner.git ~/.easy-oneliner
  source $HOME/.easy-oneliner/easy-oneliner.zsh
else
  currwd=$PWD
  cd $HOME/.easy-oneliner
  echo "git pull in $(echo $HOME/.easy-oneliner)"
  git pull
  cd "$currwd"
fi

# enhancd
if [ ! -d $HOME/enhancd ] ; then
  git clone https://github.com/rainbow23/enhancd.git ~/enhancd
fi

# cli-finder
if [ ! -f /usr/local/bin/finder ] ; then
  sudo sh -c "curl https://raw.githubusercontent.com/b4b4r07/cli-finder/master/bin/finder -o /usr/local/bin/finder && chmod +x /usr/local/bin/finder"
fi

# autojump
if [ ! -d $HOME/autojump ] ; then
  git clone git://github.com/wting/autojump.git  ~/autojump
  cd $HOME/autojump
  ./install.py
fi

# zsh-syntax-highlighting
if [ ! -d $HOME/zsh-syntax-highlighting ] ; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/zsh-syntax-highlighting
fi

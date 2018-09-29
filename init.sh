#!/bin/sh

mkdir -p -m 744 $HOME/.config/nvim
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc ~/.vimrc
ln -sfn $HOME/dotfiles/_bashrc ~/.bashrc
ln -sfn $HOME/dotfiles/_zshrc ~/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf ~/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

if [ ! -d ~/.anyenv ] ; then
  git clone https://github.com/riywo/anyenv ~/.anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  source $HOME/dotfiles/source.sh
fi

export goenv_ver=1.8.3
if [ ! -d $HOME/.anyenv/envs/goenv ] ; then
  anyenv install goenv
  source $HOME/dotfiles/source.sh

  goenv install "$goenv_ver"
  goenv global "$goenv_ver"
  goenv rehash
fi

export pyenv_ver=3.6.0
if [ ! -d $HOME/.anyenv/envs/pyenv ] ; then
  anyenv install pyenv
  source $HOME/dotfiles/source.sh

  pyenv install "$pyenv_ver"
  pyenv global "$pyenv_ver"
  pyenv rehash
fi

case "${OSTYPE}" in
darwin*)
  # Mac
  pyenv_gnu="~/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-darwin"
  ;;
linux*)
  # Linux
  pyenv_gnu="~/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-x86_64-linux-gnu"
  ;;
esac

pyenv_path="~/.anyenv/envs/pyenv/versions/3.6.1/bin/python3.6"

# /Users/goodscientist1023/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-darwin
# /home/rainbow/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-x86_64-linux-gnu
echo "$pyenv_path"
echo "$pyenv_gnu"

if [ ! -f /usr/local/bin/vim ] ; then
  if [ ! -d $HOME/vim8src ] ; then
    ¦git clone https://github.com/vim/vim.git ~/vim8src
  fi

  cd $HOME/vim8src && ./configure
    --enable-fail-if-missing
    --with-features=huge
    --disable-selinux
    --enable-luainterp
    --enable-perlinterp
    --enable-python3interp vi_cv_path_python3="$pyenv_path"
    --with-python3-config-dir="$pyenv_gnu"
    --enable-cscope
    --enable-fontset
    --enable-multibyte
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
  source $HOME/enhancd/init.sh
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

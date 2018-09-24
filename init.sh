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

#!/bin/sh

mkdir -p -m 744 $HOME/.config/nvim
#update symbolic link
ln -sfn $HOME/dotfiles/_vimrc ~/.vimrc
ln -sfn $HOME/dotfiles/_bashrc ~/.bashrc
ln -sfn $HOME/dotfiles/_zshrc ~/.zshrc
ln -sfn $HOME/dotfiles/_tmux.conf ~/.tmux.conf
ln -sfn $HOME/dotfiles/_vimrc $HOME/.config/nvim/init.vim

git config --global color.ui true

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

if [ ! -d $HOME/.zplug ] ; then
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
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

if [ ! -f /usr/local/bin/ag ] ; then
  git clone https://github.com/ggreer/the_silver_searcher.git ~/the_silver_searcher
  cd ~/the_silver_searcher && ./build.sh
  sudo make install
fi

if [ ! -d $HOME/tmuximum ] ; then
  curl -L raw.github.com/arks22/tmuximum/master/install.bash | bash
fi

# b - browse Chrome bookmarks with fzf
# https://gist.github.com/junegunn/15859538658e449b886f
if [ ! -f /usr/local/bin/.chrome_bookmarks_with_fzf.rb ] ; then
  curl -L https://gist.githubusercontent.com/rainbow23/73236d896399ca7ee68b8b3900ae39e0/raw/e25f1b1512d813b9475cd2470b1440f3efaa19e5/b.rb -o /usr/local/bin/.chrome_bookmarks_with_fzf.rb \
  && chmod 755 /usr/local/bin/.chrome_bookmarks_with_fzf.rb
fi

if [ ! -f /usr/local/bin/diff-so-fancy ] ; then
  curl -L https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -o /usr/local/bin/diff-so-fancy \
  && chmod +x /usr/local/bin/diff-so-fancy
fi

# vimPlug install
vim +PlugInstall +qall

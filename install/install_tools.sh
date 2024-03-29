#!/bin/sh

#go
if [ ! -d /usr/local/go/bin ]; then
  echo "install go "
  echo ""

  if [ ! -d /usr/local/src ]; then
    sudo mkdir /usr/local/src
  fi

  cd /usr/local/src
  sudo wget https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.12.4.linux-amd64.tar.gz
  # cat 'export PATH=$PATH:/usr/local/go/bin' > $HOME/.profile
fi

if [ ! -d $HOME/go ]; then
  mkdir -p $HOME/go/bin
fi

# tmux
if [ ! -f /usr/local/bin/tmux ]; then
  echo "install tmux "
  echo ""
  git clone --depth 1 https://github.com/tmux/tmux.git $HOME/tmux
  cd $HOME/tmux
  # checkout latest tag
  git checkout $(git tag | sort -V | tail -n 1)
  sh autogen.sh
  ./configure
  make -j4
  sudo make install
fi

TMUX_PLUGIN=$HOME/.tmux/plugins/tpm
if [[ ! -d $TMUX_PLUGIN ]]; then
  echo "install TMUX_PLUGIN "
  echo ""
  git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGIN
fi

# diff-so-fancy
if [ ! -f /usr/local/bin/diff-so-fancy ] ; then
  echo "install diff-so-fancy "
  echo ""

  sudo curl -L https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -o /usr/local/bin/diff-so-fancy \
  && sudo chmod +x /usr/local/bin/diff-so-fancy
fi

# bookmark-of-chrome
if [ ! -f $HOME/bookmark_of_chrome.rb ] ; then
  echo "install bookmark-of-chrome"
  echo ""
  mkdir $HOME/bookmark_of_chrome
  git clone https://gist.github.com/73236d896399ca7ee68b8b3900ae39e0.git $HOME/bookmark_of_chrome\
  && sudo chmod +x $HOME/bookmark_of_chrome/b.rb
fi

# the_silver_searcher
SILVER_SEARCHER=$HOME/the_silver_searcher
if [ ! -f /usr/local/bin/ag ] ; then
  echo "install SILVER_SEARCHER"
  echo ""
  if [ ! -d $SILVER_SEARCHER ]; then
    git clone --depth 1 https://github.com/ggreer/the_silver_searcher.git $HOME/the_silver_searcher
  fi

  cd $SILVER_SEARCHER && ./build.sh
  sudo make install
fi

# if [ ! -d $COMPLETIONS/docker-fzf-completion ]; then
#   git clone --depth 1 https://github.com/kwhrtsk/docker-fzf-completion.git $COMPLETIONS/docker-fzf-completion
# fi

# ctags
if [[ ! -e /usr/local/bin/ctags ]]; then
  echo "install ctags"
  echo ""
  mkdir $HOME/ctags
  git clone --depth 1 https://github.com/universal-ctags/ctags.git $HOME/ctags
  cd $HOME/ctags
  ./autogen.sh
  ./configure --enable-iconv  --prefix=/usr/local # defaults to /usr/local
  make
  sudo make install # may require extra privileges depending on where to install$ ./autogen.sh
  cd $HOME/dotfiles
  rm -rf $HOME/ctags
fi

# ctags
mkdir -p ~/.git_template/hooks

for file in `\find $HOME/dotfiles/ctags_gitfiles -maxdepth 1 -type f`; do
    cp $file ~/.git_template/hooks/
done

# tig
TIG=$HOME/tig
if [[ ! -e /usr/local/bin/tig ]]; then
  echo "install tig"
  echo ""
  CURRPATH=$(pwd)
  git clone --depth 1 git clone git://github.com/jonas/tig.git $TIG
  make prefix=/usr/local
  sudo make install prefix=/usr/local
  cd $CURRPATH
  unset CURRPATH
  rm -rf $TIG
fi

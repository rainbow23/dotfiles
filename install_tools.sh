#!/bin/sh

#go
if [ ! -d /usr/local/go/bin ]; then
  cd /usr/local/src
  sudo wget https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.12.4.linux-amd64.tar.gz
  # cat 'export PATH=$PATH:/usr/local/go/bin' > $HOME/.profile
fi

if [ ! -d $HOME/go ]; then
  mkdir -p $HOME/go/bin
fi

/usr/local/go/bin/go get -u github.com/mdempsky/gocode

# ghq
if [ ! -f /usr/local/bin/ghq ]; then
  mkdir -p $HOME/.ghq
  export GHQ_ROOT=$HOME/.ghq
fi

# tmux
if [ ! -f /usr/local/bin/tmux ]; then
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
  git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGIN
fi


if [ ! -f /usr/local/bin/diff-so-fancy ] ; then
  sudo curl -L https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -o /usr/local/bin/diff-so-fancy \
  && sudo chmod +x /usr/local/bin/diff-so-fancy
fi

# fzf
if [ ! -f $HOME/.fzf/bin/fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  yes | $HOME/.fzf/install
fi

# zplug
if [ ! -d $HOME/.zplug ] ; then
  mkdir $HOME/.zplug
  export ZPLUG_HOME=$HOME/.zplug
  git clone https://github.com/zplug/zplug.git $HOME/.zplug
  printf " Install zplug processes are successfully completed \U1F389\n"
fi

# the_silver_searcher
SILVER_SEARCHER=$HOME/the_silver_searcher
if [ ! -f /usr/local/bin/ag ] ; then
  if [ ! -d $SILVER_SEARCHER ]; then
    git clone --depth 1 https://github.com/ggreer/the_silver_searcher.git $HOME/the_silver_searcher
  fi

  cd $SILVER_SEARCHER && ./build.sh
  sudo make install
fi

# zsh
ZSH_COMPLETIONS=$HOME/.zsh-completions
if [ ! -d $ZSH_COMPLETIONS ] ; then
  mkdir -p $ZSH_COMPLETIONS
  git clone --depth 1 https://github.com/zsh-users/zsh-completions.git $ZSH_COMPLETIONS
fi

COMPLETIONS=$HOME/.zsh/completions
if [ ! -d $COMPLETIONS ] ; then
  mkdir -p $COMPLETIONS
fi

if [ ! -d $COMPLETIONS/docker-fzf-completion ]; then
  git clone --depth 1 https://github.com/kwhrtsk/docker-fzf-completion.git $COMPLETIONS/docker-fzf-completion
fi

# ctags
if [[ ! -e /usr/local/bin/ctags ]]; then
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

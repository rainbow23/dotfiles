#!/bin/sh

#go
if [ ! -d /usr/local/go/bin ]; then
  cd /usr/local/src
  sudo wget https://storage.googleapis.com/golang/go1.11.4.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.11.4.linux-amd64.tar.gz
  # cat 'export PATH=$PATH:/usr/local/go/bin' > $HOME/.profile
fi

if [ ! -d $HOME/go ]; then
  mkdir -p $HOME/go/bin
fi

/usr/local/go/bin/go get -u github.com/mdempsky/gocode

# tmux
if [ ! -d $HOME/tmux ]; then
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

# fzf
if [ ! -d $HOME/.fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  $HOME/.fzf/install
fi

if [ ! -d $HOME/.zplug ] ; then
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

SILVER_SEARCHER=$HOME/the_silver_searcher
if [ ! -f /usr/local/bin/ag ] ; then
  if [ ! -d $SILVER_SEARCHER ]; then
    git clone --depth 1 https://github.com/ggreer/the_silver_searcher.git $HOME/the_silver_searcher
  fi

  cd $SILVER_SEARCHER && ./build.sh
  sudo make install
fi

ZSH_COMPLETIONS=$HOME/.zsh-completions
if [ ! -d $ZSH_COMPLETIONS ] ; then
  mkdir -p $ZSH_COMPLETIONS
  git clone --depth 1 git://github.com/zsh-users/zsh-completions.git $ZSH_COMPLETIONS
fi

COMPLETIONS=$HOME/.zsh/completions
if [ ! -d $COMPLETIONS ] ; then
  mkdir -p $COMPLETIONS
fi

if [ ! -d $COMPLETIONS/docker-fzf-completion ]; then
  git clone --depth 1 https://github.com/kwhrtsk/docker-fzf-completion.git $COMPLETIONS/docker-fzf-completion
fi

# vimPlug install
# vim +PlugInstall +qall

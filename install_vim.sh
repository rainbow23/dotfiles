#!/bin/sh

printenv "$pyenv_ver"

case "${OSTYPE}" in
darwin*)
  # Mac
  pyenv_gnu="$HOME/.anyenv/envs/pyenv/versions/3.6.0/lib/python3.6/config-3.6m-darwin"
  ;;
linux*)
  # Linux
  pyenv_gnu="$HOME/.anyenv/envs/pyenv/versions/3.6.0/lib/python3.6/config-3.6m-x86_64-linux-gnu"
  ;;
esac

pyenv_path="$HOME/.anyenv/envs/pyenv/versions/3.6.0/bin/python3.6"

# /Users/goodscientist1023/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-darwin
# /home/rainbow/.anyenv/envs/pyenv/versions/3.6.1/lib/python3.6/config-3.6m-x86_64-linux-gnu

# echo "$pyenv_path"
# echo "$pyenv_gnu"

# if [ ! -f /usr/local/bin/vim ] ; then
if [ ! -d $HOME/vim8src ] ; then
  git clone --depth 1 https://github.com/vim/vim.git $HOME/vim8src

  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte

  sudo make && sudo make install
fi

# install neovim CentOS7 / RHEL7
# https://github.com/neovim/neovim/wiki/Installing-Neovim

sudo yum -y install epel-release
sudo curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo 
sudo yum -y install neovim

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
    git clone --depth 1 https://github.com/vim/vim.git ~/vim8src

    cd $HOME/vim8src && ./configure\
      --enable-fail-if-missing\
      --with-features=huge\
      --disable-selinux\
      --enable-luainterp\
      --enable-perlinterp\
      --enable-python3interp vi_cv_path_python3="$pyenv_path"\
      --with-python3-config-dir="$pyenv_gnu"\
      --enable-cscope\
      --enable-fontset\
      --enable-multibyte

    # LDFLAGS="-Wl,-rpath=${HOME}/.pyenv/versions/2.7.6/lib:${HOME}/.pyenv/versions/3.6.0/lib"
    # LDFLAGS="-Wl,-rpath=$HOME/.anyenv/envs/pyenv/versions/2.7.6/lib:$HOME/.anyenv/envs/pyenv/versions/3.6.0/lib"
    # cd $HOME/vim8src && ./configure \
    #   --enable-fail-if-missing \
    #   --with-features=huge \
    #   --disable-selinux \
    #   --enable-luainterp \
    #   --enable-perlinterp \
    #   --enable-pythoninterp=dynamic \
    #   --enable-python3interp=dynamic \
    #   vi_cv_path_python3="$pyenv_path" \
    #   --with-python3-config-dir="$pyenv_gnu" \
    #   --enable-cscope \
    #   --enable-fontset \
    #   --enable-multibyte

    sudo make && sudo make install
  fi


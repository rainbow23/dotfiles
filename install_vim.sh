#!/bin/sh
if [[ ! -e /usr/local/bin/python3.5 ]]; then
  echo "python3.5がインストールされていません"
  exit 1
fi

if [ ! -d $HOME/vim8src ]; then
  git clone --depth 1 https://github.com/vim/vim.git $HOME/vim8src
fi

ostype=$($HOME/dotfiles/ostype.sh)

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""

  # error対応
  # undefined symbol: PyByteArray_Type
  # https://github.com/vim/vim/issues/3629
  export LDFLAGS="-rdynamic"

  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.5\
    # --with-python3-config-dir=/usr/local/Python35/lib/python3.5/config-3.5m-x86_64-linux-gnu\
    --with-python3-config-dir=/usr/local/Python35/lib/python3.5/config-3.5m\
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte

elif [ $ostype = 'darwin' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""
  # `brew --prefix` >> /usr/local
  cd $HOME/vim8src && ./configure\
    --prefix=`brew --prefix`\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp=yes\
    # --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.7\
    --with-python3-command=python3\
    # --with-python3-config-dir=/usr/local/Cellar/python3/3.7.2/Frameworks/Python.framework/Versions/3.7/lib/python3.7/config-3.7m-darwin\ #deprecated
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
fi

sudo make && sudo make install
cd $HOME/dotfiles && sudo rm -rf $HOME/vim8src
alias vim='/usr/local/bin/vim'
vim +slient +PlugInstall +qall

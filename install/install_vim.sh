#!/bin/sh
if [ ! -e /usr/local/bin/python3 ]; then
  echo "python3がインストールされていません"
  exit 1
fi

vimpath=$HOME/vim8src

# fixed fzf clash version https://github.com/vim/vim/issues/3873
version=8.2.1751

if [ ! -d $vimpath ]; then
  mkdir -p $vimpath && cd $vimpath
  curl -L "https://github.com/vim/vim/archive/v${version}.zip" -o "vim-${version}.zip"
  unzip -d "$vimpath" "vim-${version}.zip"
fi

vimpath="$HOME/vim8src/vim-${version}"

ostype=$($HOME/dotfiles/etc/ostype.sh)

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""

  # error対応
  # undefined symbol: PyByteArray_Type
  # https://github.com/vim/vim/issues/3629
  export LDFLAGS="-rdynamic"

  cd $vimpath && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3\
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
  cd $vimpath && ./configure\
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

cd $vimpath
sudo make && sudo make install
alias vim='/usr/local/bin/vim'
vim  +PlugInstall +qall
vim  +GoInstallBinaries +qall
vim  +UpdateRemotePlugin +qall

if [ -d $vimpath ]; then
  sudo rm -rf $vimpath
fi

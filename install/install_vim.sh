#!/bin/sh
if [ ! -e /usr/local/bin/python3 ]; then
  echo "python3がインストールされていません"
  exit 1
fi

ostype=$($HOME/dotfiles/etc/ostype.sh)
if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""

  # fixed fzf clash version https://github.com/vim/vim/issues/3873
  version=8.2.1751
  vimpath="$HOME/vim8src/vim-${version}"
  if [ ! -d $vimpath ]; then
	mkdir -p $vimpath && cd $vimpath
	curl -L "https://github.com/vim/vim/archive/v${version}.zip" -o "vim-${version}.zip"
	unzip -d "$vimpath" "vim-${version}.zip"
  fi
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
  cd $vimpath
  sudo make && sudo make install
elif [ $ostype = 'darwin' ]; then
  echo ""
  echo "configure ostype $ostype ****************************************"
  echo ""
  brew remove vim
  brew cleanup
  brew install vim
fi

# alias vim='/usr/local/Cellar/vim/8.2.1900/bin/vim'
vim  +PlugInstall +qall
vim  +GoInstallBinaries +qall
vim  +UpdateRemotePlugin +qall

if [ -d $vimpath ]; then
  sudo rm -rf $vimpath
fi

pip3 --no-cache-dir install --user --upgrade pip
pip3 --no-cache-dir install --user pynvim

# エラー対応 > ModuleNotFoundError: No module named 'neovim'
# reference https://github.com/roxma/vim-hug-neovim-rpc/issues/47
# ↓ To check what Python your Vim is using you can run:
# :pythonx import sys; print(sys.path)
# python3.9と紐づけてると分かったのでpython3.9でpynvimをインストールする
# /usr/local/opt/python@3.9/bin/pip3 install pynvim

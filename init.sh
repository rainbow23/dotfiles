#!/bin/sh
ostype=$(bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/develop/ostype.sh)")

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

yum -y install sudo

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  array=( "git" \
          "automake" \
          "ncurses-devel" \
          "make" \
          "gcc" \
          "curl" \
          "lua-devel" \
          "perl-ExtUtils-Embed" \
          "zlib-devel" \
          "bzip2" \
          "bzip2-devel" \
          "readline-devel"
          "sqlite" \
          "sqlite-devel"
          "openssl-devel" \
          "libevent-devel"
          "git" \
          "zsh" \
          "pcre-devel" \
          "xz" \
          "xz-devel" \
          "wget" \
          "unzip" \
          "docker" \
          "docker-compose" \
          "tree" \
          "strace" \
          )
elif [ $ostype = 'darwin' ]; then
  array=( "tmux" \
          "git" \
          "zsh" \
          "neovim" \
          "python" \
          "python3" \
          )
fi

for i in "${array[@]}"
do
  echo $i
  if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
    sudo yum -y install $i
  elif [ $ostype = 'darwin' ]; then
    brew install $i
  fi
done

sudo chsh $USER -s /bin/zsh 2>/dev/null
INSTALL_DIR=$HOME/dotfiles

if [[ ! -d $INSTALL_DIR ]]; then
  git clone https://github.com/rainbow23/dotfiles.git $INSTALL_DIR
fi

cd $INSTALL_DIR
make deploy
make install

exec $SHELL

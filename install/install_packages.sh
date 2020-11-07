#!/bin/sh
ostype=$(bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/develop/etc/ostype.sh)")

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  yum -y install sudo
  array=( "git" \
          "automake" \
          "cmake" \
          "gcc-c++" \
          "libtool" \
          "patch" \
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
          "libevent-devel" \
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
          "gettext" \
          )
elif [ $ostype = 'darwin' ]; then
  array=( "tmux" \
          "cmake" \
          "git" \
          "zsh" \
          "python" \
          "python3" \
          "autoconf" \
          "automake" \
          "wget" \
          "pkg-config" \
          "rg" \
          "bat" \
          "go" \
          "git-delta" \
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

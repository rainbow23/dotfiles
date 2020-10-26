#!/bin/sh

ostype=$($HOME/dotfiles/etc/ostype.sh)
echo "" && echo "install python  ostype $ostype ****************************************" && echo ""

if [ $ostype = 'darwin' ]; then
  brew install openssl
  brew link --force openssl
  source $HOME/dotfiles/python3/source.sh
  brew install python3
elif [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  sudo yum -y install zlib-devel openssl-devel tk-devel

  PYTHON_INSTALL_DIR=$HOME/python

  if [ ! -d $PYTHON_INSTALL_DIR ]; then
    mkdir $PYTHON_INSTALL_DIR
    cd $PYTHON_INSTALL_DIR
    wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tgz
    tar zxvf Python-3.6.1.tgz
    cd Python-3.6.1
    sudo ./configure --prefix=/usr/local/Python36
    sudo make
    sudo make install
    sudo chown -R ${USERNAME}:${USERNAME} /usr/local/Python36
  fi

  if [ -L /usr/local/bin/python3 ]; then
      sudo rm -rf /usr/local/bin/python3
  fi
  if [ -L /usr/local/bin/pip3 ]; then
      sudo rm -rf /usr/local/bin/pip3
  fi

  sudo ln -s /usr/local/Python36/bin/python3.6 /usr/local/bin/python3
  sudo ln -s /usr/local/Python36/bin/pip3.6 /usr/local/bin/pip3
fi

# vim error support
# pip install -U msgpack

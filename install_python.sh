#!/bin/sh

ostype=$($HOME/dotfiles/ostype.sh)
echo "" && echo "install python  ostype $ostype ****************************************" && echo ""

if [ $ostype = 'darwin' ]; then
  brew install openssl
  brew link --force openssl
  source $HOME/dotfiles/python3/source.sh
  brew install python3
fi

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then

PYTHON_INSTALL_DIR=$HOME/python
  if [ ! -d $PYTHON_INSTALL_DIR ]; then
    mkdir $PYTHON_INSTALL_DIR
    cd $PYTHON_INSTALL_DIR
    wget https://www.python.org/ftp/python/3.6.0/Python-3.6.0.tgz
    tar zxvf Python-3.6.0.tgz
    cd Python-3.6.0
    sudo yum -y install zlib-devel openssl-devel tk-devel
    sudo ./configure --prefix=/usr/local/Python36
    sudo make
    sudo make install
    sudo chown -R ${USERNAME}:${USERNAME} /usr/local/Python36
  fi

  if [ -L /usr/local/bin/python3.6 ]; then
      sudo rm -rf /usr/local/bin/python3.6
  fi
  if [ -L /usr/local/bin/pip3 ]; then
      sudo rm -rf /usr/local/bin/pip3
  fi

  sudo ln -s /usr/local/Python36/bin/python3.6 /usr/local/bin/python3.6
  sudo ln -s /usr/local/Python36/bin/pip3.6 /usr/local/bin/pip3
fi

pip3 --no-cache-dir install --upgrade pip
pip3 --no-cache-dir install neovim
pip3 --no-cache-dir install --user neovim
pip3 --no-cache-dir install pynvim

#!/bin/sh

ostype=$(./ostype.sh)

if [ $ostype = 'redhat' ] || [ $ostype = 'amazonlinux' ]; then
  echo "" && "install python  ostype $ostype ****************************************" && echo ""

PYTHON_INSTALL_DIR=$HOME/python
  if [ ! -d $PYTHON_INSTALL_DIR ]; then
    mkdir $PYTHON_INSTALL_DIR
    cd $PYTHON_INSTALL_DIR
    wget https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz
    tar zxvf Python-3.5.0.tgz
    cd Python-3.5.0
    sudo yum -y install zlib-devel openssl-devel tk-devel
    sudo ./configure --prefix=/usr/local/Python35
    sudo make
    sudo make install
    sudo chown -R ${USERNAME}:${USERNAME} /usr/local/Python35
  fi

  if [ -L /usr/local/bin/python3.5 ]; then
      sudo rm -rf /usr/local/bin/python3.5
  fi
  if [ -L /usr/local/bin/pip3 ]; then
      sudo rm -rf /usr/local/bin/pip3
  fi

  sudo ln -s /usr/local/Python35/bin/python3.5 /usr/local/bin/python3.5
  sudo ln -s /usr/local/Python35/bin/pip3.5 /usr/local/bin/pip3
elif [ $ostype = 'darwin' ]; then
  echo "" && "install python  ostype $ostype ****************************************" && echo ""
  brew install python3
fi

pip3 install --upgrade pip
pip3 install neovim
pip3 install --user neovim
pip3 install pynvim

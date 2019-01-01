#!/bin/sh
mkdir ~/src
cd ~/src
wget https://www.python.org/ftp/python/3.5.0/Python-3.5.0.tgz
tar zxvf Python-3.5.0.tgz
cd Python-3.5.0
sudo yum -y install zlib-devel openssl-devel tk-devel
sudo ./configure --prefix=/usr/local/Python35
sudo make
# sudo make test
sudo make install
sudo ln -s /usr/local/Python35/bin/python3.5 /usr/local/bin/python3.5
sudo ln -s /usr/local/Python35/bin/pip3.5 /usr/local/bin/pip3

# /usr/local/Python36/lib/python3.6/config-3.6m-x86_64-linux-gnu

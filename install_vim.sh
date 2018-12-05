#!/bin/sh
if [ ! -d $HOME/vim8src ] ; then
  git clone --depth 1 https://github.com/vim/vim.git $HOME/vim8src
fi

if [ -f /usr/bin/python3.6 ] ; then
echo 'has python 3.6 *************************************************'
  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp vi_cv_path_python3=/usr/bin/python3.6 \
    --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu\
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
else
  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    # --enable-python3interp\
    # --with-python3-config-dir=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gn\u
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
fi

sudo make && sudo make install

# install neovim CentOS7 / RHEL7
# https://github.com/neovim/neovim/wiki/Installing-Neovim

sudo yum -y install epel-release
sudo curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo 
sudo yum -y install neovim

#!/bin/sh
if [ ! -d $HOME/vim8src ]; then
  git clone --depth 1 https://github.com/vim/vim.git $HOME/vim8src
fi

# Get Linux distribution name
get_os_distribution() {
    if   [ -e /etc/debian_version ] ||
         [ -e /etc/debian_release ]; then
        # Check Ubuntu or Debian
        if [ -e /etc/lsb-release ]; then
            # Ubuntu
            distri_name="ubuntu"
        else
            # Debian
            distri_name="debian"
        fi
    elif [ -e /etc/redhat-release ]; then
        # Red Hat Enterprise Linux
        distri_name="redhat"
    elif [ -e /etc/system-release-cpe ]; then
        distri_name="amazonlinux"
    elif [ -e /etc/arch-release ]; then
        # Arch Linux
        distri_name="arch"
    elif echo ${OSTYPE} | grep -q "darwin"; then
        # Mac
        distri_name="darwin"
    else
        # Other
        echo "unkown distribution"
        distri_name="unkown"
    fi

    echo ${distri_name}
}

ostype=$(get_os_distribution)

if [ ! -f /usr/local/bin/python3.5 ]; then
  if [ $ostype = 'redhat' ] ||
     [ $ostype = 'amazonlinux' ]; then
    echo ""
    echo "install ostype $ostype *************************************************"
    echo ""

    sudo ./install_python.sh

    # error対応
    # undefined symbol: PyByteArray_Type
    # https://github.com/vim/vim/issues/3629
    export LDFLAGS="-rdynamic"

    sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    # sudo yum -y install python36u  python36u-devel python36u-pip
  fi
  # if [ $ostype = 'darwin' ]; then
    # brew install python3.7
  # fi
    # sudo pip install --upgrade pip
    # sudo python3.5 -m pip install --upgrade pip
    # sudo python3.5 -m pip install neovim
    # sudo python3.5 -m pip install --user pynvim
    # sudo python3.5 -m pip install --upgrade pynvim
    # pip install --user neovim
fi

pip3 install --upgrade pip
pip3 install neovim
pip3 install --user neovim
pip3 install pynvim

if [ $ostype = 'redhat' ] ||
   [ $ostype = 'amazonlinux' ]; then
  echo ""
  echo "configure ostype $ostype *************************************************"
  echo ""
  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.5 \
    # --with-python3-config-dir=/usr/local/Python35/lib/python3.5/config-3.5m-x86_64-linux-gnu \
    --with-python3-config-dir=/usr/local/Python35/lib/python3.5/config-3.5m \
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
elif [ $ostype = 'darwin' ]; then
  echo ""
  echo "configure ostype $ostype *************************************************"
  echo ""
# ./configure --prefix=`brew --prefix` --enable-multibyte --with-features=huge --enable-fontset --enable-cscope --disable-selinux --disable-gui

# ./configure --prefix=/usr/local --enable-rubyinterp --enable-python3interp --disable-gpm --enable-gui=no --enable-multibyte --with-python3-config-dir=/usr/local/Cellar/python3/3.2/Frameworks/Python.framework/Versions/3.2/lib/python3.2/config-3.2m

# /usr/local/Cellar/python3/3.7.2/Frameworks/Python.framework/Versions/3.7/lib/python3.7/config-3.7m-darwin

# `brew --prefix` >> /usr/local
  cd $HOME/vim8src && ./configure\
    --prefix=`brew --prefix` \
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp=yes \
    # --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.7 \
    --with-python3-command=python3 \
    # --with-python3-config-dir=/usr/local/Cellar/python3/3.7.2/Frameworks/Python.framework/Versions/3.7/lib/python3.7/config-3.7m-darwin \ #deprecated
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
fi

sudo make && sudo make install
sudo rm -rf $HOME/vim8src
alias vim='/usr/local/bin/vim'

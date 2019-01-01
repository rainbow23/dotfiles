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
echo "ostype $ostype *************************************************"

# error対応
# undefined symbol: PyByteArray_Type
# https://github.com/vim/vim/issues/3629
export LDFLAGS="-rdynamic"

if [ ! -f /usr/local/bin/python3.5 ]; then
    sudo ./install_python.sh
  if [ $ostype = 'redhat' ] ||
     [ $ostype = 'amazonlinux' ]; then
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

# if [ $ostype = 'redhat' ] ||
#    [ $ostype = 'amazonlinux' ]; then
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
# elif [ $ostype = 'darwin' ]; then
#   cd $HOME/vim8src && ./configure\
#     --enable-fail-if-missing\
#     --with-features=huge\
#     --disable-selinux\
#     --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.7 \
#     --enable-luainterp\
#     --enable-perlinterp\
#     --enable-cscope\
#     --enable-fontset\
#     --enable-multibyte
# fi

sudo make && sudo make install

sudo rm -rf $HOME/vim8src

#!/bin/sh
if [ ! -d $HOME/vim8src ] ; then
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
    elif [ echo ${OSTYPE} | grep darwin ]; then
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

if [ $ostype = 'redhat' ] ||
   [ $ostype = 'amazonlinux' ] ; then

  sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
  sudo yum -y install python36u  python36u-devel python36u-pip
  sudo python3.6 -m pip install --upgrade pip
  python3.6 -m pip install neovim
  python3.6 -m pip install --user pynvim
  python3.6 -m pip install --upgrade pynvim
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

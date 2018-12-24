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

if [ ! -f /usr/bin/python3.6 ]; then
  if [ $ostype = 'redhat' ] ||
     [ $ostype = 'amazonlinux' ]; then
    sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    sudo yum -y install python36u  python36u-devel python36u-pip
    sudo python3.6 -m pip install --upgrade pip
    python3.6 -m pip install neovim
    python3.6 -m pip install --user pynvim
    python3.6 -m pip install --upgrade pynvim
  fi
elif [ ! -f /usr/local/bin/python3.7 ]; then
  if [ $ostype = 'darwin' ]; then
    brew install python3.7
    sudo python3.7 -m pip install --upgrade pip
    python3.7 -m pip install neovim
    python3.7 -m pip install --user pynvim
    python3.7 -m pip install --upgrade pynvim
  fi
fi

if [ $ostype = 'redhat' ] ||
   [ $ostype = 'amazonlinux' ]; then
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
elif [ $ostype = 'darwin' ]; then
  cd $HOME/vim8src && ./configure\
    --enable-fail-if-missing\
    --with-features=huge\
    --disable-selinux\
    --enable-python3interp vi_cv_path_python3=/usr/local/bin/python3.7 \
    --enable-luainterp\
    --enable-perlinterp\
    --enable-cscope\
    --enable-fontset\
    --enable-multibyte
fi

sudo make && sudo make install

# /usr/local/Cellar/python/3.7.1/Frameworks/Python.framework/Versions/3.7/lib/python3.7/config-3.7m-darwin
# % ls -la /usr/local/bin/ | grep python | grep config                [14:50:15]
# 24:437:lrwxr-xr-x    1 goodscientist1023  admin       45 Nov 15 00:34 python-config@ -> ../Cellar/python@2/2.7.15_1/bin/python-config
# 26:439:lrwxr-xr-x    1 goodscientist1023  admin       46 Nov 15 00:34 python2-config@ -> ../Cellar/python@2/2.7.15_1/bin/python2-config
# 28:441:lrwxr-xr-x    1 goodscientist1023  admin       48 Nov 15 00:34 python2.7-config@ -> ../Cellar/python@2/2.7.15_1/bin/python2.7-config
# 30:443:lrwxr-xr-x    1 goodscientist1023  admin       41 Dec 23 15:37 python3-config@ -> ../Cellar/python/3.7.1/bin/python3-config
# 32:445:lrwxr-xr-x    1 goodscientist1023  admin       43 Dec 23 15:37 python3.7-config@ -> ../Cellar/python/3.7.1/bin/python3.7-config
# 34:447:lrwxr-xr-x    1 goodscientist1023  admin       44 Dec 23 15:37 python3.7m-config@ -> ../Cellar/python/3.7.1/bin/python3.7m-config

# if [ -f /usr/local/bin/python3.7 ]; then
# echo 'has python 3.7 *************************************************'
#   cd $HOME/vim8src && ./configure\
#     --enable-fail-if-missing\
#     --with-features=huge\
#     --disable-selinux\
#     --enable-python3interp vi_cv_path_python3=/usr/bin/python3.7 \
#     --with-python3-config-dir=/usr/lib64/python3.7/config-3.7m-x86_64-linux-gnu\
#     --enable-luainterp\
#     --enable-perlinterp\
#     --enable-cscope\
#     --enable-fontset\
#     --enable-multibyte
# else
#   cd $HOME/vim8src && ./configure\
#     --enable-fail-if-missing\
#     --with-features=huge\
#     --disable-selinux\
#     # --enable-python3interp\
#     # --with-python3-config-dir=/usr/lib64/python3.7/config-3.7m-x86_64-linux-gn\u
#     --enable-luainterp\
#     --enable-perlinterp\
#     --enable-cscope\
#     --enable-fontset\
#     --enable-multibyte
# fi

# sudo make && sudo make install

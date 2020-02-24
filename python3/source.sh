
#!/bin/sh

ostype=$($HOME/dotfiles/etc/ostype.sh)
# echo "" && echo "install python  ostype $ostype ****************************************" && echo ""

if [ $ostype = 'darwin' ]; then
  # If you need to have openssl@1.1 first in your PATH run:
  export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"

  # For compilers to find openssl@1.1 you may need to set:
  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"

  # For pkg-config to find openssl@1.1 you may need to set:
  export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
fi

FROM alpine:3.8 as builder

# ARG USERNAME=rainbow23
# ARG USERPASSWORD=rainbow23

# # ROOTにパスワードをセット
# RUN echo "root: ${USERPASSWORD}" |chpasswd

# # ユーザを作成
# RUN useradd ${USERNAME}
# RUN usermod -aG wheel ${USERNAME}
# RUN echo "${USERNAME}:${USERPASSWORD}" |chpasswd
# RUN echo "${USERNAME}    ALL=(ALL)       ALL" >> /etc/sudoers
# RUN echo "root    ALL=(ALL)       ALL" >> /etc/sudoers

# # nopassword with user
# RUN echo "# %wheel   ALL=(ALL)    ALL/" >> /etc/sudoers
# RUN echo "%wheel   ALL=(ALL)    NOPASSWD: ALL" >> /etc/sudoers

# # system update
# RUN yum -y update && yum clean all

# # sudoをインストール
# RUN yum install -y sudo

# # set locale
# RUN yum reinstall -y glibc-common && yum clean all
# RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
# ENV LANG="ja_JP.UTF-8" \
#     LANGUAGE="ja_JP:ja" \
#     LC_ALL="ja_JP.UTF-8"



WORKDIR /tmp

# RUN apk add --no-cache \
#   build-base \
#   ctags \
#   git \
#   libx11-dev \
#   libxpm-dev \
#   libxt-dev \
#   make \
#   ncurses-dev \
#   python3 \
#   python3-dev \
#   perl-dev \
#   ruby-dev

RUN apk add  \
# RUN apk add --no-cache \
ncurses-dev \
automake \
make \
gcc \
lua-dev \
# perl-ExtUtils-Embed \
zlib-dev \
bzip2 \
bzip2-dev \
readline-dev \
sqlite-dev \
openssl-dev \
libevent-dev \
xz xz-dev \
sqlite \

sudo \
tar \

curl \
python3 \
python3-dev \
bash \
git \
zsh \
wget \
unzip \
docker \
# docker-compose \
tree

RUN git clone https://github.com/vim/vim && cd vim \
  && ./configure \
  --disable-gui \
  --disable-netbeans \
  --enable-multibyte \
  --enable-perlinterp \
  --enable-rubyinterp \
  --enable-python3interp \
  --with-features=huge \
  --with-python3-config-dir=/usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/ \
  --with-compiledby=asyazwan@gmail.com \
  && make install






RUN git clone https://github.com/rainbow23/dotfiles.git && cd dotfiles \
# && ./install_python.sh
# && ./install_vim.sh
# RUN bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/add_package/init.sh)"

# ADD . /home/${USERNAME}/dotfiles
# ADD . ~/dotfiles

# USER ${USERNAME}
# WORKDIR /home/${USERNAME}/

# CMD ["zsh"]

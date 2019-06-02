FROM alpine:3.8 as builder
# FROM alpine:edge as builder
WORKDIR /tmp
RUN apk add --no-cache \
  build-base \
  ctags \
  git \
  libx11-dev \
  libxpm-dev \
  libxt-dev \
  automake \
  make \
  cmake \
  libtool \
  ncurses-dev \

# libtermkey-dev \
# libtermkey \
# unibilium \

zlib-dev \
bzip2 \
bzip2-dev \
readline-dev \
libevent-dev \
xz xz-dev \
libintl \
alpine-sdk build-base \
m4 \
autoconf \
linux-headers \
unzip \
ncurses ncurses-dev ncurses-libs ncurses-terminfo \
tar \
patch \
clang \
# autoconf \
  python3 \
  python3-dev \
  perl-dev \
  ruby-dev \
  curl \
  unzip \
musl-dev \
py-pip \
py3-pip

# fixed fzf clash version https://github.com/vim/vim/issues/3873
# version=8.1.0847 \

RUN curl -L "https://github.com/vim/vim/archive/v8.1.0847.zip" -o "vim-8.1.0847.zip" \
 && unzip "vim-8.1.0847.zip" \
 && cd "vim-8.1.0847" \
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
RUN pip3 install --upgrade pip \
 && pip3 install neovim \
 && pip3 install --user neovim \
 && pip3 install pynvim


# RUN git clone https://github.com/neovim/libtermkey.git && \
#   cd libtermkey && \
#   make && \
#   make install && \
#   cd ../ && rm -rf libtermkey
# RUN git clone https://github.com/neovim/libvterm.git && \
#   cd libvterm && \
#   make && \
#   make install && \
#   cd ../ && rm -rf libvterm
# RUN git clone https://github.com/neovim/unibilium.git && \
#   cd unibilium && \
#   make && \
#   make install && \
#   cd ../ && rm -rf unibilium
# RUN  git clone https://github.com/neovim/neovim.git && \
#   cd neovim && \
#   make && \
#   make install && \
#   cd ../ && rm -rf nvim








FROM alpine:3.8
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share/vim  /usr/local/share/vim
# COPY --from=builder /usr/bin/nvim /usr/local/bin/nvim
# RUN apk add --update --no-cache \
RUN apk add --no-cache \
  libice \
  libsm \
  libx11 \
  libxt \
  ncurses \
  python3 \
  ruby \
  perl \
  git \
  bash \
  fish \
  ctags \
  fzf \
  the_silver_searcher \
  neovim \
  tmux \
  zsh

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

ENTRYPOINT ["/bin/zsh"]

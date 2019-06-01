FROM alpine:3.8 as builder

WORKDIR /tmp

RUN apk add --no-cache \
  build-base \
  ctags \
  git \
  libx11-dev \
  libxpm-dev \
  libxt-dev \
  make \
  ncurses-dev \
  python3 \
  python3-dev \
  perl-dev \
  ruby-dev

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


FROM alpine:3.8

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share/vim  /usr/local/share/vim
RUN apk add --update --no-cache \
  libice \
  libsm \
  libx11 \
  libxt \
  ncurses \
  python3 \
  ruby \
  perl \

RUN apk add --update --no-cache \
  git \
  bash \
  fish \
  ctags \
  fzf \
  the_silver_searcher \
  zsh

RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
CMD ["zsh"]

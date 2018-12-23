FROM centos:7

ARG USERNAME=rainbow23
ARG USERPASSWORD=rainbow23

# ROOTにパスワードをセット
RUN echo "root: ${USERPASSWORD}" |chpasswd

# ユーザを作成
RUN useradd ${USERNAME}
RUN echo "${USERNAME}:${USERPASSWORD}" |chpasswd
RUN echo "${USERNAME}    ALL=(ALL)       ALL" >> /etc/sudoers
RUN echo "root    ALL=(ALL)       ALL" >> /etc/sudoers

# system update
RUN yum -y update && yum clean all

# sudoをインストール
RUN yum install -y sudo

# set locale
RUN yum reinstall -y glibc-common && yum clean all
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

RUN yum -y install epel-release \
automake \
ncurses-devel \
make \
gcc \
curl \
lua-devel \
perl-ExtUtils-Embed \
zlib-devel \
bzip2 \
bzip2-devel \
readline-devel \
sqlite \
sqlite-devel \
openssl-devel \
libevent-devel \
git \
zsh \
xz xz-devel \
wget \
tree; yum clean all

# sudo なしが駄目なら下で実行
RUN yum -y install https://centos7.iuscommunity.org/ius-release.rpm
RUN yum -y install python36u  python36u-devel python36u-pip
RUN python3.6 -m pip install neovim
RUN python3.6 -m pip install --upgrade pip
RUN python3.6 -m pip install --user pynvim
RUN python3.6 -m pip install --upgrade pynvim

USER ${USERNAME}
WORKDIR /home/${USERNAME}/

RUN git clone https://github.com/tmux-plugins/tpm /home/${USERNAME}/.tmux/plugins/tpm \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux/plugins/tpm \
    && chmod 755 /home/${USERNAME}/.tmux/plugins/tpm

ADD . /home/${USERNAME}/dotfiles
ADD ./id_rsa /home/${USERNAME}/.ssh/id_rsa

# COPY $HOME/.ssh /home/${USERNAME}/.ssh

RUN echo ${USERPASSWORD} | sudo -S chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles
RUN echo ${USERPASSWORD} | sudo -S /home/rainbow23/dotfiles/install_vim.sh
RUN echo ${USERPASSWORD} | /home/${USERNAME}/dotfiles/init.sh

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

RUN vim +slient +PlugInstall +qall

CMD ["zsh"]

FROM centos:7

ARG USERNAME=rainbow23
ARG USERPASSWORD=rainbow23

# ROOTにパスワードをセット
RUN echo "root: ${USERPASSWORD}" |chpasswd

# ユーザを作成
RUN useradd ${USERNAME}
RUN usermod -aG wheel ${USERNAME}
RUN echo "${USERNAME}:${USERPASSWORD}" |chpasswd
RUN echo "${USERNAME}    ALL=(ALL)       ALL" >> /etc/sudoers
RUN echo "root    ALL=(ALL)       ALL" >> /etc/sudoers

# nopassword with user
RUN echo "# %wheel   ALL=(ALL)    ALL/" >> /etc/sudoers
RUN echo "%wheel   ALL=(ALL)    NOPASSWD: ALL" >> /etc/sudoers

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
docker \
docker-compose \
tree; yum clean all

USER ${USERNAME}
WORKDIR /home/${USERNAME}/

ADD ./id_rsa /home/${USERNAME}/.ssh/id_rsa
ADD . /home/${USERNAME}/dotfiles
RUN sudo chown -R rainbow23:wheel dotfiles

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
RUN echo ${USERPASSWORD} | sudo -S chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles
RUN /home/rainbow23/dotfiles/install_vim.sh
RUN /home/rainbow23/dotfiles/init.sh

RUN vim +slient +PlugInstall +qall

CMD ["zsh"]

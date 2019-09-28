FROM centos:7 AS base_dotfiles

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

RUN yum -y install epel-release git
RUN bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/develop/install_packages.sh)"

USER ${USERNAME}

RUN cd /home/rainbow23/ && mkdir dotfiles
RUN git clone --depth 1 https://github.com/rainbow23/dotfiles.git /home/rainbow23/dotfiles/
RUN /home/rainbow23/dotfiles/install_python.sh
RUN /home/rainbow23/dotfiles/install_vim.sh
RUN /home/rainbow23/dotfiles/install_nvim.sh

WORKDIR /home/${USERNAME}/

CMD ["zsh"]

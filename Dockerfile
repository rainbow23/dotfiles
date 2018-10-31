FROM centos:7

ARG USERNAME=rainbow23

# ROOTにパスワードをセット
RUN echo 'root:rainbow' |chpasswd

# ユーザを作成
RUN useradd ${USERNAME}
RUN echo "${USERNAME}:rainbow" |chpasswd
RUN echo "${USERNAME}    ALL=(ALL)       ALL" >> /etc/sudoers

# ENV TZ Asia/Tokyo
# ENV LANG ja_JP.UTF-8
# ENV LANGUAGE ja_JP:en
# ENV LC_ALL ja_JP.UTF-8

# RUN yum -y update; yum clean all;
# RUN yum -y install epel-release; yum clean all

# system update
RUN yum -y update && yum clean all

# sudoをインストール
RUN yum install -y sudo

# set locale
RUN yum reinstall -y glibc-common && yum clean all
# ENV LANG ja_JP.UTF-8
# ENV LANGUAGE ja_JP:ja
# ENV LC_ALL ja_JP.UTF-8

# RUN unlink /etc/localtime
# RUN ln -s /usr/share/zoneinfo/Japan /etc/localtime

RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

RUN yum -y install epel-release gcc lua-devel perl-ExtUtils-Embed zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tmux git zsh tree; yum clean all

RUN git clone https://github.com/tmux-plugins/tpm /home/${USERNAME}/.tmux/plugins/tpm \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux/plugins/tpm \
    && chmod 755 /home/${USERNAME}/.tmux/plugins/tpm

ADD . /home/${USERNAME}/dotfiles
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles \
    # && sudo -u ${USERNAME} -i /home/${USERNAME}/dotfiles/init.sh \
    && /home/${USERNAME}/dotfiles/init.sh \
    && source /home/${USERNAME}/.zshrc

# RUN /home/${USERNAME}/dotfiles/init.sh \
#     && source /home/${USERNAME}/.zshrc

USER ${USERNAME}
WORKDIR /home/${USERNAME}/
CMD ["zsh"]

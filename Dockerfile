FROM centos:7

ARG USERNAME=rainbow23

# ENV TZ Asia/Tokyo
# ENV LANG ja_JP.UTF-8
# ENV LANGUAGE ja_JP:en
# ENV LC_ALL ja_JP.UTF-8

# RUN yum -y update; yum clean all;
# RUN yum -y install epel-release; yum clean all

# system update
RUN yum -y update && yum clean all

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

RUN useradd -ms /bin/bash rainbow23
USER ${USERNAME}
WORKDIR /home/${USERNAME}/

# RUN useradd -ms /bin/bash rainbow23 && su - rainbow23

# RUN git clone https://github.com/wting/autojump.git /home/${USERNAME}/autojump \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/autojump \
#     && chmod 755 /home/${USERNAME}/autojump \
#     && git clone https://github.com/tmux-plugins/tpm /home/${USERNAME}/.tmux/plugins/tpm \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux/plugins/tpm \
#     && chmod 755 /home/${USERNAME}/.tmux/plugins/tpm \
#     && git clone https://github.com/vim/vim /home/${USERNAME}/vim8src \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux/plugins/tpm \
#     && chmod 755 /home/${USERNAME}/.tmux/plugins/tpm \
#     && git clone https://github.com/riywo/anyenv /home/${USERNAME}/.anyenv \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.anyenv \
#     && chmod 755 /home/${USERNAME}/.anyenv \
#     && git clone https://github.com/junegunn/fzf /home/${USERNAME}/.fzf \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.fzf \
#     && chmod 755 /home/${USERNAME}/.fzf \
#     && git clone https://github.com/b4b4r07/enhancd.git /home/${USERNAME}/.enhancd \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.enhancd \
#     && chmod 755 /home/${USERNAME}/.enhancd \
#     && git clone https://github.com/rainbow23/dotfiles.git /home/${USERNAME}/dotfiles \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles \
#     && chmod 755 /home/${USERNAME}/dotfiles && cd /home/${USERNAME}/dotfiles && git checkout master && /home/${USERNAME}/dotfiles/init.sh && source ~/.zshrc

RUN git clone https://github.com/tmux-plugins/tpm /home/${USERNAME}/.tmux/plugins/tpm \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.tmux/plugins/tpm \
    && chmod 755 /home/${USERNAME}/.tmux/plugins/tpm
    # && git clone https://github.com/rainbow23/dotfiles.git /home/${USERNAME}/dotfiles \
    # && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles \
    # && chmod 755 /home/${USERNAME}/dotfiles \
    # && cd /home/${USERNAME}/dotfiles \
    # && git checkout master \
    # && /home/${USERNAME}/dotfiles/init.sh \
    # && source /home/${USERNAME}/.zshrc

ADD . /home/${USERNAME}/dotfiles
# RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles \
#     && sudo -u ${USERNAME} -i /home/${USERNAME}/dotfiles/init.sh \
#     && source /home/${USERNAME}/.zshrc

RUN /home/${USERNAME}/dotfiles/init.sh \
    && source /home/${USERNAME}/.zshrc


CMD ["zsh"]

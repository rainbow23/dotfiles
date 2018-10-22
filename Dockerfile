FROM centos7:centos7
# FROM centos7

ARG USERNAME=rainbow23

ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:en
ENV LC_ALL ja_JP.UTF-8

RUN yum install gcc lua-devel perl-ExtUtils-Embed zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tmux git zsh tree

RUN useradd -ms /bin/bash rainbow23

# RUN git clone https://github.com/wting/autojump.git /home/${USERNAME}/autojump \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/autojump \
#     && chmod 755 /home/${USERNAME}/autojump \

#     && git clone https://github.com/rainbow23/dotfiles.git /home/${USERNAME}/dotfiles \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles \
#     && chmod 755 /home/${USERNAME}/dotfiles \

#     && git clone https://github.com/tmux/tmux.git /home/${USERNAME}/tmuxsrc \
#     && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/tmuxsrc \
#     && chmod 755 /home/${USERNAME}/tmuxsrc \

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

USER ${USERNAME}
WORKDIR /home/${USERNAME}/
CMD ["zsh"]

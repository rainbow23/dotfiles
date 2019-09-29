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

RUN yum -y install epel-release make git
USER ${USERNAME}
RUN bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/develop/init.sh)"
# RUN bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/develop/install_packages.sh)"

# USER ${USERNAME}

# RUN cd /home/rainbow23/ && mkdir dotfiles
# RUN git clone --depth 1 https://github.com/rainbow23/dotfiles.git /home/rainbow23/dotfiles/
# RUN /home/rainbow23/dotfiles/install_python.sh
# RUN /home/rainbow23/dotfiles/install_vim.sh
# RUN /home/rainbow23/dotfiles/install_nvim.sh

WORKDIR /home/${USERNAME}/

CMD ["zsh"]

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

# set locale
RUN yum reinstall -y glibc-common && yum clean all
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

USER ${USERNAME}
COPY --from=base_dotfiles /home/rainbow23/dotfiles            /home/rainbow23/dotfiles
RUN $HOME/dotfiles/symlink.sh


COPY --from=base_dotfiles /usr/local/bin/      /usr/local/bin/
COPY --from=base_dotfiles /usr/local/Python35  /usr/local/Python35
# COPY --from=base_dotfiles /usr/local/Python35/bin/pip3.5 /usr/local/Python35/bin/pip3.5

# RUN sudo ln -s /usr/local/Python35/bin/python3.5 /usr/local/bin/python3.5
# RUN sudo ln -s /usr/local/Python35/bin/pip3.5 /usr/local/bin/pip3

COPY --from=base_dotfiles /home/rainbow23/.git_template/hooks /home/rainbow23/.git_template/hooks
COPY --from=base_dotfiles /home/rainbow23/.zplug              /home/rainbow23/.zplug
COPY --from=base_dotfiles /home/rainbow23/.fzf/bin/fzf        /home/rainbow23/.fzf/bin/fzf
COPY --from=base_dotfiles /home/rainbow23/.fzf.bash           /home/rainbow23/.fzf.bash
COPY --from=base_dotfiles /home/rainbow23/.fzf.zsh            /home/rainbow23/.fzf.zsh

WORKDIR /home/${USERNAME}/
# CMD ["zsh"]
################################################################################################

# /usr/local/bin/vim
# /usr/local/bin/nvim
# /usr/local/go/
# $HOME/.zsh-completions
# ~/.git_template/hooks
# $HOME/.zplug
# $HOME/.fzf/bin/fzf
# $HOME/.fzf.bash
# $HOME/.fzf.zsh
# $HOME/dotfiles

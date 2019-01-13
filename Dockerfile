FROM rainbow23/base_dotfiles:latest
ARG USERNAME=rainbow23
ARG USERPASSWORD=rainbow23

# ADD ./id_rsa /home/${USERNAME}/.ssh/id_rsa
ADD . /home/${USERNAME}/dotfiles

RUN echo ${USERPASSWORD} | sudo -S chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles
RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# RUN cd $HOME/dotfiles && ./init.sh

CMD ["zsh"]

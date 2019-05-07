FROM rainbow23/base_dotfiles:latest
ARG USERNAME=rainbow23
ARG USERPASSWORD=rainbow23

# ADD ./id_rsa /home/${USERNAME}/.ssh/id_rsa
ADD . /home/${USERNAME}/dotfiles

RUN echo ${USERPASSWORD} | sudo -S chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles && \

bash -c "$(curl -L https://raw.githubusercontent.com/rainbow23/dotfiles/add_package/init.sh)"
CMD ["zsh"]

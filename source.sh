#!/bin/sh
source ~/.zplug/init.zsh

git config --global color.ui true
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
git config --global color.diff.meta       "yellow"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

[[ -s $HOME/.autojump/etc/profile.d/autojump.sh ]] && source $HOME/.autojump/etc/profile.d/autojump.sh
autoload -U compinit && compinit -u

## -------------------------------------
# fzf
# -------------------------------------
if [ -d $HOME/.fzf ] ; then
  if [  -n "$ZSH_NAME" ] ; then
      # echo 'running zsh';
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh;
  else
      # echo 'running bash';
      [ -f ~/.fzf.bash ] && source ~/.fzf.bash;
  fi
fi

zplug "mollifier/anyframe", at:4c23cb60
# Grab binaries from GitHub Releases
# and rename with the "rename-to:" tag
zplug "junegunn/fzf-bin", \
    from:gh-r, \
    as:command, \
    rename-to:fzf, \
    use:"*darwin*amd64*"
zplug "junegunn/fzf", as:command, use:bin/fzf-tmux
zplug "so-fancy/diff-so-fancy", \
    use:diff-so-fancy, \
    as:command
zplug "b4b4r07/zsh-gomi", \
    as:command, \
    use:bin/gomi, \
    on:junegunn/fzf
zplug "nnao45/zsh-kubectl-completion"
zplug "b4b4r07/enhancd", use:init.sh
zplug "wting/autojump", \
    as:command, \
    hook-build:"./install.py"
zplug "rainbow23/easy-oneliner", use:easy-oneliner.zsh, if:"which fzf"
zplug "b4b4r07/cli-finder", use:cli-finder.zsh, if:"which fzf"
# Set the priority when loading
# e.g., zsh-syntax-highlighting must be loaded
# after executing compinit command and sourcing other plugins
# (If the defer tag is given 2 or above, run after compinit command)
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "rainbow23/73236d896399ca7ee68b8b3900ae39e0", \
    from:gist, \
    as:command, \
    use:b.rb, \
    rename-to:chrome_bookmarks_with_fzf.rb
zplug "b4b4r07/79ee61f7c140c63d2786", \
    from:gist, \
    as:command, \
    use:get_last_pane_path.sh
zplug "motemen/ghq", \
    as:command, \
    hook-build:"make install"

# zplug check returns true if all packages are installed
# Therefore, when it returns false, run zplug install
if ! zplug check --verbose; then
    zplug install
fi

# source plugins and add commands to the PATH
zplug load --verbose

# zplug check returns true if the given repository exists
if zplug check b4b4r07/enhancd; then
    # setting if enhancd is available
    export ENHANCD_FILTER=fzf-tmux
fi

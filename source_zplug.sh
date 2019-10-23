#!/bin/sh
## -------------------------------------
# zplug
## -------------------------------------
source ~/.zplug/init.zsh

zplug "mollifier/anyframe", at:4c23cb60
zplug "junegunn/fzf", as:command, use:bin/fzf-tmux
# zplug "so-fancy/diff-so-fancy", \
#     use:diff-so-fancy, \
#     as:command
zplug "b4b4r07/zsh-gomi", \
    as:command, \
    use:bin/gomi, \
    on:junegunn/fzf
zplug "nnao45/zsh-kubectl-completion"
zplug "b4b4r07/enhancd", use:init.sh
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
zplug "motemen/ghq", at:980d2b45 \
    as:command, \
    hook-build:"make install"
zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# zplug check returns true if the given repository exists
if zplug check b4b4r07/enhancd; then
    # setting if enhancd is available
    export ENHANCD_FILTER=fzy:fzf-tmux
fi

# zplug check returns true if all packages are installed
# Therefore, when it returns false, run zplug install
if ! zplug check --verbose; then
    zplug install
fi

# source plugins and add commands to the PATH
zplug load

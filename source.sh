#!/bin/zsh

## -------------------------------------
# git
# -------------------------------------
if [ -f /usr/local/bin/delta ] ; then
  git config --global core.pager "delta --diff-so-fancy"
  git config --global interactive.diffFilter                    "delta --color-only"
  git config --global delta.whitespace-error-style              "22 reverse"
  git config --global delta.navigate                            "true"
  git config --global delta.line-numbers                        "true"
  git config --global delta.decorations.commit-decoration-style "bold yellow box ul"
  git config --global delta.decorations.file-style              "bold yellow ul"
  git config --global delta.decorations.file-decoration-style   "none"
fi

git config --global color.diff.whitespace             "red reverse"
git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
git config --global color.diff.meta                   "yellow"
git config --global color.diff.frag                   "magenta bold"
git config --global color.diff.commit                 "yellow bold"
git config --global color.diff.old                    "red bold"
git config --global color.diff.new                    "green bold"
git config --global color.diff.whitespace             "red reverse"

# git status の表示で、日本語のファイル名が文字化け対応
git config --global core.quotepath false
#ctags settings
git config --global init.templatedir '~/.git_template'
git config --global alias.ctags '!~/dotfiles/etc/copy_ctags_files && .git/hooks/ctags'

## -------------------------------------
# go
# -------------------------------------
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$GOBIN

## -------------------------------------
# enhancd
# -------------------------------------
ENHANCD=$HOME/.enhancd
if [ ! -d $ENHANCD ] ; then
  mkdir -p $ENHANCD
  git clone --depth 1 https://github.com/rainbow23/enhancd.git $ENHANCD
fi
source $ENHANCD/init.sh
export ENHANCD_FILTER=fzf-tmux

## -------------------------------------
# fzf
# -------------------------------------
if [ ! -f $HOME/.fzf/bin/fzf ] ; then
  git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
  yes | $HOME/.fzf/install
fi

if [ -d $HOME/.fzf ] ; then
  if [  -n "$ZSH_NAME" ] ; then
      # echo 'running zsh';
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh;
  else
      # echo 'running bash';
      [ -f ~/.fzf.bash ] && source ~/.fzf.bash;
  fi
fi
export FZF_COMPLETION_TRIGGER=''
bindkey '^T' fzf-completion
bindkey '^I' $fzf_default_completion

## -------------------------------------
# easy-oneliner
## -------------------------------------
if [ ! -d $HOME/.easy-oneliner ] ; then
  git clone --depth 1 https://github.com/rainbow23/easy-oneliner.git ~/.easy-oneliner
fi
source $HOME/.easy-oneliner/easy-oneliner.zsh

## -------------------------------------
# ZSH-AUTOPAIR
## -------------------------------------
ZSH_AUTOPAIR=$HOME/.zsh-autopair
if [[ ! -d $ZSH_AUTOPAIR ]]; then
  mkdir -p $ZSH_AUTOPAIR
  git clone --depth 1 https://github.com/hlissner/zsh-autopair $ZSH_AUTOPAIR
fi
source $ZSH_AUTOPAIR/autopair.zsh
autopair-init

## -------------------------------------
# ZSH_AUTOSUGGESTIONS
# -------------------------------------
ZSH_AUTOSUGGESTIONS=$HOME/.zsh_autosuggestions
if [ ! -d $ZSH_AUTOSUGGESTIONS ] ; then
  mkdir -p $ZSH_AUTOSUGGESTIONS
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_AUTOSUGGESTIONS
fi
source $ZSH_AUTOSUGGESTIONS/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=45,bold"
bindkey '^j' autosuggest-accept
bindkey '^f' autosuggest-fetch
bindkey '^d' autosuggest-disable

ZSH_ABBREV_ALIAS=$HOME/.abbrev_alias
if [ ! -d $ZSH_ABBREV_ALIAS ] ; then
  mkdir -p $ZSH_ABBREV_ALIAS
  git clone --depth 1 https://github.com/momo-lab/zsh-abbrev-alias.git $ZSH_ABBREV_ALIAS
fi
source $ZSH_ABBREV_ALIAS/abbrev-alias.plugin.zsh

# -------------------------------------
# supercrabtree/k
# -------------------------------------
SUPERCRABTREE_K=$HOME/.k
if [ ! -d $SUPERCRABTREE_K ] ; then
  mkdir -p $SUPERCRABTREE_K
  git clone --depth 1 https://github.com/supercrabtree/k.git $SUPERCRABTREE_K
fi
source $SUPERCRABTREE_K/k.sh

## -------------------------------------
# ZSH_COMPLETIONS
# -------------------------------------
ZSHCOMPLETION=$HOME/.zsh/completion

if [ ! -d $ZSHCOMPLETION ] ; then
  mkdir -p $ZSHCOMPLETION
  git clone --depth 1 git://github.com/zsh-users/zsh-completions.git $ZSHCOMPLETION/zsh_completions
fi

# docker補完設定
ZSHCOMPLETION=$HOME/.zsh/completion
if [ ! -d $ZSHCOMPLETION ]; then
  mkdir -p $ZSHCOMPLETION
fi
# https://docs.docker.com/compose/completion/
if [ ! -f $ZSHCOMPLETION/_docker ] ; then
  curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > $ZSHCOMPLETION/_docker
fi
# https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
if [ ! -f $ZSHCOMPLETION/_docker-compose ] ; then
  curl -L https://raw.githubusercontent.com/docker/compose/1.25.0/contrib/completion/zsh/_docker-compose > $ZSHCOMPLETION/_docker-compose
fi
fpath=($ZSHCOMPLETION(N-/) $fpath)

## -------------------------------------
# ZSH-YOU-SHOULD-USE
# -------------------------------------
ZSH_YOU_SHOULD_USE=$HOME/.zsh-you-should-use
if [ ! -d $ZSH_YOU_SHOULD_USE ] ; then
  mkdir -p $ZSH_YOU_SHOULD_USE
  git clone https://github.com/MichaelAquilina/zsh-you-should-use.git $ZSH_YOU_SHOULD_USE
fi
source $ZSH_YOU_SHOULD_USE/you-should-use.plugin.zsh

## -------------------------------------
# ZSH-GOMI
# -------------------------------------
ZSH_GOMI=$HOME/.zsh-gomi
if [ ! -d $ZSH_GOMI ] ; then
  mkdir -p $ZSH_GOMI
  git clone https://github.com/b4b4r07/zsh-gomi $ZSH_GOMI
fi
source $ZSH_GOMI/gomi.zsh

## -------------------------------------
# FZF-TAB
## -------------------------------------
FZF_TAB=$HOME/.fzf-tab
if [ ! -d $FZF_TAB ] ; then
  mkdir $FZF_TAB
  git clone https://github.com/Aloxaf/fzf-tab.git $FZF_TAB
fi

if [ -f $FZF_TAB/fzf-tab.plugin.zsh ] ; then
  source $FZF_TAB/fzf-tab.plugin.zsh

  # (experimental, may change in the future)
  # some boilerplate code to define the variable `extract` which will be used later
  # please remember to copy them
  local extract="
  # trim input(what you select)
  local in=\${\${\"\$(<{f})\"%\$'\0'*}#*\$'\0'}
  # get ctxt for current completion(some thing before or after the current word)
  local -A ctxt=(\"\${(@ps:\2:)CTXT}\")
  # real path
  local realpath=\${ctxt[IPREFIX]}\${ctxt[hpre]}\$in
  realpath=\${(Qe)~realpath}
  "

  FZF_TAB_GROUP_COLORS=(
      $'\033[94m' $'\033[32m' $'\033[33m' $'\033[35m' $'\033[31m' $'\033[38;5;27m' $'\033[36m' \
      $'\033[38;5;100m' $'\033[38;5;98m' $'\033[91m' $'\033[38;5;80m' $'\033[92m' \
      $'\033[38;5;214m' $'\033[38;5;165m' $'\033[38;5;124m' $'\033[38;5;120m'
  )
  zstyle ':fzf-tab:*' group-colors $FZF_TAB_GROUP_COLORS

  # Component: fzf-tab
  # Purpose: disable default command keybinding (I use tab for `accept` action)
  # Reference: https://github.com/Aloxaf/fzf-tab#command
  FZF_TAB_COMMAND=(
    fzf
    --ansi
    --expect='$continuous_trigger' # For continuous completion
    '--color=hl:$(( $#headers == 0 ? 108 : 255 ))'
    --nth=2,3 --delimiter='\x00'  # Don't search prefix
    --layout=reverse --height='${FZF_TMUX_HEIGHT:=75%}'
    --tiebreak=begin -m --cycle
    '--query=$query'
    '--header-lines=$#headers'
  )
  zstyle ":fzf-tab:*" command $FZF_TAB_COMMAND
  zstyle ':fzf-tab:*' continuous-trigger '/'
  local sanitized_in='${~ctxt[hpre]}"${${in//\\ / }/#\~/$HOME}"'
  zstyle ':fzf-tab:complete:vim:*' extra-opts --preview=$extract'[ -d $realpath ] && exa -1 --color=always $realpath || bat -p --theme=base16 --color=always $realpath'
  zstyle ':fzf-tab:complete:nvim:*' extra-opts --preview=$extract'[ -d $realpath ] && exa -1 --color=always $realpath || bat -p --theme=base16 --color=always $realpath'
  zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
  zstyle ':fzf-tab:complete:ls:*' extra-opts --preview=$extract'exa  --color=always $realpath || bat -p --theme=base16 --color=always $realpath'
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  # disable sort when completing options of any command
  zstyle ':completion:complete:*:options' sort false
  # give a preview of commandline arguments when completing `kill`
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
fi

## -------------------------------------
# ZSH_SYNTAX_HIGHLIGHTING
## -------------------------------------
ZSH_SYNTAX_HIGHLIGHTING=$HOME/.zsh/zsh-syntax-highlighting
if [ ! -d $ZSH_SYNTAX_HIGHLIGHTING ] ; then
  mkdir -p $ZSH_SYNTAX_HIGHLIGHTING
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_SYNTAX_HIGHLIGHTING
fi
source $ZSH_SYNTAX_HIGHLIGHTING/zsh-syntax-highlighting.zsh

#!/bin/zsh
# ftags - search ctags
ftags() {
  local line
  [ -e tags ] &&
  line=$(
    awk 'BEGIN { FS="\t" } !/^!/ {print toupper($4)"\t"$1"\t"$2"\t"$3}' tags |
    cut -c1-80 | fzf --nth=1,2
  ) && ${EDITOR:-vim} $(cut -f3 <<< "$line") -c "set nocst" \
                                      -c "silent tag $(cut -f2 <<< "$line")"
}

## -------------------------------------
# fzf git
# -------------------------------------
export NESTEDPREVIEW="echo {} | grep -o '[a-f0-9]\{7\}' | xargs -I %  sh -c 'git show --color=always % | delta --diff-so-fancy'"
export NESTED_GIT_DIFF_PREVIEW="echo {} | xargs -I %  sh -c 'git diff --color=always % | delta --diff-so-fancy'"

# https://qiita.com/reviry/items/e798da034955c2af84c5

git-add-files() {
  local out q n addfiles
  while out=$(
      git status --short --untracked-files=no |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf --multi --exit-0 --border -d 100 --preview $NESTED_GIT_DIFF_PREVIEW \
      --expect=ctrl-d --expect=enter --expect=ctrl-e --expect=ctrl-a --expect=ctrl-r --expect=ctrl-t \
      --header "ctrl-r=git checkout, ctrl-t=tmux popup, enter=git diff, ctrl-e=edit, ctrl-a=git add"); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ] || [ "$q" = enter ] ; then
      git diff --color=always -u $addfiles | delta --diff-so-fancy | less -R
    elif [ "$q" = ctrl-e ] ; then
      vim $addfiles
    elif [ "$q" = ctrl-a ] ; then
      git add $addfiles
    elif [ "$q" = ctrl-r ] ; then
      git checkout $addfiles
    elif [ "$q" = ctrl-t ] ; then
      tmux popup  -w90% -h90% -E "zsh"
    fi
  done
}

gcb() {
  local brh cbrh
  IFS=$'\n'
  brh=$(git branch --all --sort=-authordate\
      | fzf +m \
      | sed -e 's/ //g' \
            -e 's/*//g' \
            -e 's/remotes\/origin\///g')
  git checkout "$brh"
}

glf() {
  local out file key
  IFS=$'\n'
  out=($(git ls-files | fzf --preview 'head -100 {}' --query="$1" --select-1 --exit-0 --expect=ctrl-v))
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
      if [ "$key" = ctrl-v ] ; then
        ${EDITOR:-vim} "$file"
      fi
  fi
}

git-log-selected-files() {
  git ls-files $(git rev-parse --show-toplevel) |
  fzf --height=100 \
    --bind "enter:execute[echo {} \
     | xargs git log --oneline \
     | fzf --height=100 --preview \"\$NESTEDPREVIEW\"]" \
    --bind "ctrl-e:execute[echo {} \
     | grep -o '[a-f0-9]\{7\}' | head -1 | xargs less -R"
}

targetBranch=""

git-commit-show-multi-branch(){
  local out q n targetBranch
  while out=$(
    git branch --all --sort=-authordate  | fzf --exit-0 --border --header "select branch and show git log" \
        --expect=enter --expect=ctrl-c --expect=ctrl-q | sed -e 's/*//g'
  ); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    targetBranch=(`echo $(tail "-$n" <<< "$out")`)
    if [ "$q" = enter ] ; then
      git-commit-show
      # git-commit-show-preview
    elif [ "$q" = ctrl-c ] ; then
      break
    elif [ "$q" = ctrl-q ] ; then
      break
    fi
  done
}

alias glNoGraph='git log --graph --color=always $targetBranch --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
_gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
_viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | delta --diff-so-fancy'"

# show_commit - git commit browser 
git-commit-show() {
clear
  glNoGraph |
    fzf --height=100 --no-sort --reverse --tiebreak=index --no-multi --ansi \
      --header "ctrl-g to copy git message,  ctrl-h to copy hash" \
      --bind "enter:execute:($_viewGitLogLine | less -R)" \
      --bind "ctrl-h:abort+execute:($_gitLogLineToHash | pbcopy)" \
      --bind "ctrl-g:abort+execute:($_gitLogLineToHash | xargs git show -s --format=%s | pbcopy)" \
      --bind "q:execute()+abort"
}

# show_preview - git commit browser with previews
git-commit-show-preview() {
clear
  glNoGraph |
    fzf --height=100 --no-sort --reverse --tiebreak=index --no-multi --ansi \
      --preview="$_viewGitLogLine" \
      --header "ctrl-f, ctrl-p to toggle preview, ctrl-g to copy git message, ctrl-h to copy hash" \
      --bind "enter:execute:$_viewGitLogLine   | less -R" \
      --bind "ctrl-h:abort+execute:($_gitLogLineToHash | pbcopy)" \
      --bind "ctrl-g:abort+execute:($_gitLogLineToHash | xargs git show -s --format=%s | pbcopy)" \
      --bind "q:execute()+abort" \
      --bind '?:toggle-preview' \
      --bind='ctrl-f:toggle-preview' \
      --bind='ctrl-p:toggle-preview'
}

gsd() {
  local out
  IFS=$'\n'
  out=($(git status --short | fzf-tmux --multi | awk '{print $2}')) 
  git diff $out
}

alias _gitStashGraph='git stash list --color=always --pretty="%C(auto)%h %gs %C(black)%C(bold)%cr"'

git-stash-list() {
  clear
  _gitStashGraph |
    fzf --ansi +m --exit-0 --header "enter with show diff, ctrl-d with show files namea ctr-a with stash apply" \
      --bind "enter:execute:$_gitLogLineToHash | xargs git stash show -p" \
      --bind "ctrl-a:abort+execute:($_gitLogLineToHash | xargs git stash apply )" \
      --bind "q:execute()+abort" \
}

do_enter() {
    if [[ -n $BUFFER ]]; then
        zle accept-line
        return $status
    fi

    echo
    if [[ -d .git ]]; then
        if [[ -n "$(git status --short)" ]]; then
            git status
        fi
    else
        # do nothing
        :
    fi

    zle reset-prompt
}
zle -N do_enter
bindkey '^m' do_enter

cd-to-ghq-selected-directory() {
  local selected
  selected=$(ghq list | fzf)

  if [ "x$selected" != "x" ]; then
    cd $(ghq root)/$selected
  fi
}

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

## -------------------------------------
# fzf tmux
# -------------------------------------

# ts [FUZZY PATTERN] - Select selected tmux session
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
tmux-select-session() {
  local session
  session=$(tmux list-sessions -F "#{session_name}" | \
    fzf --query="$1" --select-1 --exit-0) &&
  tmux switch-client -t "$session"
}

_fzf_complete_tmux-select-session() {
  tmux-select-session
}

# tm - create new tmux session, or switch to existing one. Works from within tmux too. (@bag-man)
# `tm` will allow you to select your tmux session via fzf.
# `tm irc` will attach to the irc session (if it exists), else it will create it.
tmux-session() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

_fzf_complete_tmux-session() {
  tmux-session
}

# tmux-kill-session
tmux-kill-session() {
  tmux ls | fzf-tmux --query="$1" | awk '{print $1}' | sed "s/:$//g" | xargs tmux kill-session -t
}
_fzf_complete_tmux-kill-session() {
  tmux-kill-session
}

# tmux-list-panes
tmux-list-panes() {
  tmux list-panes -s -F '#I:#W' | fzf +m | sed -e 's/:.*//g' | xargs tmux select-window -t
}
_fzf_complete_tmux-list-panes() {
  tmux-list-panes
}

## -------------------------------------
# fzf fd
# -------------------------------------

# fd - cd to selected directory
fd-selected-directory() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# Another fd - cd into the selected directory
# This one differs from the above, by only showing the sub directories and not
#  showing the directories within those.
fd-selected-sub-directory() {
  DIR=`find * -maxdepth 0 -type d -print 2> /dev/null | fzf` \
    && cd "$DIR"
}

# fdp - cd to selected parent directory
fd-selected-parent-directory() {
  local declare dirs=()
  get_parent_dirs() {
    if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
    if [[ "${1}" == '/' ]]; then
      for _dir in "${dirs[@]}"; do echo $_dir; done
    else
      get_parent_dirs $(dirname "$1")
    fi
  }
  local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf --tac)
  cd "$DIR"
}

ftpane() {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}
# In tmux.conf
# bind-key 0 run "tmux split-window -l 12 'bash -ci ftpane'"


# j() {
#     if [[ "$#" -ne 0 ]]; then
#         cd $(autojump $@)
#         return
#     fi
#     cd "$(autojump -s | sed '/_____/Q; s/^[0-9,.:]*\s*//' |  fzf --height 40% --nth 1.. --reverse --inline-info +s --tac --query "${*##-* }" )"
# }

browse-chrome-history() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}

# LastPass CLI
# Search through your LastPass vault with LastPass CLI and copy password to clipboard. 
lp() {
  lpass show -c --password $(lpass ls  | fzf | awk '{print $(NF)}' | sed 's/\]//g')
}

export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_DEFAULT_OPTS='--height 70% --reverse --color=header:#fa8787'

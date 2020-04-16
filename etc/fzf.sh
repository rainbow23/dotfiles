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

# https://qiita.com/reviry/items/e798da034955c2af84c5
git-add-files() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf-tmux --multi --exit-0 --border \
      --expect=ctrl-d --expect=enter --expect=ctrl-e --expect=ctrl-a \
      --header "ctrl-d=git diff, enter=git diff, ctrl-e=edit, ctrl-a=git add"); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ] || [ "$q" = enter ] ; then
      git diff --color=always -u $addfiles | diff-so-fancy | less -R
    elif [ "$q" = ctrl-e ] ; then
      ${EDITOR:-vim} $addfiles
    elif [ "$q" = ctrl-a ] ; then
      git add $addfiles
    fi
  done
}

gcb() {
  local brh cbrh
  IFS=$'\n'
  brh=$(git branch --all \
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

git-commit-show(){
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "q:execute()+abort" \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | diff-so-fancy' | less -R) << 'FZF-EOF'
                {}
FZF-EOF"
}

alias glNoGraph='git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
_gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
_viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

# show_preview - git commit browser with previews
git-commit-show-preview() {
    glNoGraph |
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview="$_viewGitLogLine" \
                --header "enter to view, alt-y to copy hash" \
                --bind "enter:execute:$_viewGitLogLine   | less -R" \
                --bind "ctrl-y:execute:$_gitLogLineToHash | xclip" \
                --bind "q:execute()+abort" \
                --bind='ctrl-f:toggle-preview'
}

gsd() {
  local out
  IFS=$'\n'
  out=($(git status --short | fzf-tmux --multi | awk '{print $2}')) 
  git diff $out
}

git-stash-list() {
  IFS=$'\n'
  local stash key stashfullpath
  stash=$(git stash list | fzf --ansi +m --exit-0 \
        --header "enter with show diff, ctrl-d with show files namea ctr-a with stash apply" \
        --expect=enter --expect=ctrl-d --expect=ctrl-a)

  key=$(head -1 <<< "$stash")
  stashfullpath=$(head -2 <<< $stash | tail -1)
  file=$(head -2 <<< $stash | awk '{print $1}' | sed -e 's/://g' | tail -1)
  # echo $stash
  # echo "$file"
  # echo $key

  if [ -n "$file" ]; then
      if [ "$key" = ctrl-d ] ; then
        echo "git stash show $stashfullpath"
        git stash show $file
      elif [ "$key" = enter ] ; then
        echo "git stash show $stashfullpath"
        git stash show $file
        echo "git stash show -p $stashfullpath"
        git stash show -p $file
      elif [ "$key" = ctrl-a ] ; then
        echo "git stash apply $stashfullpath"
        git stash apply $file
      fi
  fi
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
  DIR=`find * -maxdepth 0 -type d -print 2> /dev/null | fzf-tmux` \
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
  local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf-tmux --tac)
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
export FZF_DEFAULT_OPTS='--height 70% --reverse '
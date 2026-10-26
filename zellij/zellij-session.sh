#!/bin/zsh
# zellij セッション操作（_zshrc から source する）

# zs [FUZZY PATTERN] - zellij セッションを fzf で選択して接続する
#   - zellij 外: zellij attach（EXITED のセッションは復元される）
#   - zellij 内: zellij action switch-session で切り替える
#   - 候補が 1 件ならそのまま接続（--select-1）、0 件なら終了（--exit-0）
zellij-select-session() {
  local line session
  line=$(zellij list-sessions 2>/dev/null |
    fzf --ansi --query="$1" --select-1 --exit-0 \
        --header "zellij sessions  current: ${ZELLIJ_SESSION_NAME:-(none)}") || {
    [[ -z $(zellij list-sessions -s 2>/dev/null) ]] && echo "No sessions found."
    return 1
  }
  # 色コードを除いた先頭の語がセッション名（fzf --ansi でも除かれるが念のため）
  session=$(sed $'s/\e\\[[0-9;]*m//g' <<< "$line" | awk '{print $1}')
  [[ -z $session ]] && return 1

  if [[ -n $ZELLIJ ]]; then
    if [[ $session == "$ZELLIJ_SESSION_NAME" ]]; then
      echo "Already in session: $session"
      return 0
    fi
    zellij action switch-session "$session"
  else
    zellij attach "$session"
  fi
}

alias zs='zellij-select-session'

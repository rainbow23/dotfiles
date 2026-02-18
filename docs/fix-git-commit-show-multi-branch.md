# fzf.sh `git-commit-show-multi-branch` 不具合修正

## 概要
`git-commit-show-multi-branch` を複数回実行すると git log が表示されなくなる不具合を修正。

---

## 修正1: while ループの終了条件

| | 内容 |
|---|---|
| **原因** | `while out=$(... \| fzf \| sed)` でパイプの最後が `sed` のため、fzf の終了コードが無視され常に 0 が返る。Escape でループを抜けられない |
| **対策** | `sed` を fzf の前段に移動し、fzf を最後のコマンドにすることで終了コードを正しく伝搬 |

**Before:**
```zsh
while out=$(
    git branch --all --sort=-authordate \
      | fzf --exit-0 --border ... \
          --expect=enter --expect=ctrl-c --expect=ctrl-q \
      | sed -e 's/*//g'
); do
```

**After:**
```zsh
while true; do
    out=$(
      git branch --all --sort=-authordate \
        | sed -e 's/*//g' \
        | fzf --exit-0 --border ... \
            --expect=enter --expect=ctrl-c --expect=ctrl-q
    )
    [[ $? -ne 0 ]] && break
```

---

## 修正2: グローバル変数 `targetBranch` を廃止し、引数渡しに変更

| | 内容 |
|---|---|
| **原因** | エイリアス `glNoGraph` がグローバル変数 `$targetBranch` を参照。`local` 宣言との動的スコープの兼ね合いで、繰り返し呼び出し時に変数の値が不安定になる |
| **対策** | エイリアスを関数に置き換え、ブランチ名を引数で明示的に渡す |

**Before:**
```zsh
targetBranch=""

git-commit-show-multi-branch(){
  local out q n targetBranch
  ...
  targetBranch=(`echo $(tail "-$n" <<< "$out")`)
  ...
  git-commit-show    # 引数なし、グローバル変数に依存
}

alias glNoGraph='git log --graph --color=always $targetBranch --format="..." "$@"'

git-commit-show() {
  clear
  glNoGraph |
    fzf ...
}
```

**After:**
```zsh
git-commit-show-multi-branch(){
  local out q n _target_branch
  ...
  _target_branch=$(echo $(tail "-$n" <<< "$out"))
  ...
  git-commit-show "$_target_branch"    # 引数で渡す
}

_glNoGraph() {
  git log --graph --color=always ${1:+$1} --format="..."
}

git-commit-show() {
  tput reset
  _glNoGraph ${1:+"$1"} |
    fzf ...
}
```

`${1:+$1}` により引数が空の場合は何も渡さず、カレントブランチの log を表示する。

---

## 修正3: ターミナルリセットの改善

| | 内容 |
|---|---|
| **原因** | `clear` はスクリーンのクリアのみ。繰り返し呼び出しでターミナル状態が蓄積的に不安定になる |
| **対策** | `tput reset` でターミナル状態を完全リセット |

---

## 修正4: `--height=100` → `--height=100%`

| | 内容 |
|---|---|
| **原因** | `--height=100` は 100 **行**固定のインラインモード。ターミナルサイズによっては描画が不安定になる |
| **対策** | `--height=100%` でターミナル全体を使用するフルスクリーンモードに変更 |

---

## 修正5: fzf バインドの実行順序

| | 内容 |
|---|---|
| **原因** | `abort+execute:...` だと `abort` が先に実行され fzf が終了し、`execute` が実行されない可能性がある |
| **対策** | `execute:...+abort` に順序を変更し、コマンド実行後に fzf を終了する |

**Before:**
```zsh
--bind "ctrl-h:abort+execute:($_gitLogLineToHash | pbcopy)"
```

**After:**
```zsh
--bind "ctrl-h:execute:($_gitLogLineToHash | pbcopy)+abort"
```

# popuptmux: TTYフォアグラウンドプロセスグループによるアイドル判定

## 修正の背景

`popuptmux.sh` はpopupセッションのシェルがアイドル状態のときにのみ `cd $rootDir` を送信する。
以前の実装では `pgrep -P $pane_pid`（zshの子プロセス有無）で判定していたが、以下の問題があった。

- **問題1**: zshの非同期プロンプト（powerlevel10k等）がgit statusをバックグラウンドで取得する際に子プロセスを生成するため、アイドル状態でも「使用中」と誤判定され、cdが送信されなかった
- **問題2**: `pane_current_command` チェックのみでは `git-commit-show` のようなシェルスクリプト経由でfzfが動作している場合に `pane_current_command = "zsh"` となり、fzfのプロンプトにcdが送信されてしまった

## 解決策: TTYフォアグラウンドプロセスグループの確認

```sh
pane_tty=$(tmux display-message -t popup -p '#{pane_tty}' 2>/dev/null)
if [ -n "$pane_tty" ]; then
  fg_non_shell=$(ps -t "$pane_tty" -o stat=,comm= 2>/dev/null | awk '$1 ~ /\+/ && $2 !~ /^-?(zsh|bash|sh)$/ {print $2}')
  if [ -z "$fg_non_shell" ]; then
    tmux send-keys -t 'popup' "cd $rootDir ; clear" 'C-m'
  fi
fi
```

## 用語解説

### TTY（TeleTYpewriter）
端末デバイスのこと。tmuxの各paneは仮想的なTTY（`/dev/ttys001` など）を持っており、
そのpane上で動くプロセスはこのTTYを通じて入出力を行う。
`#{pane_tty}` でpaneのTTYパスを取得できる。

### フォアグラウンドプロセスグループ
TTYには「フォアグラウンドプロセスグループ」という概念があり、
**現在そのTTYのキーボード入力を受け取れるプロセス群**のことを指す。

| 状態 | フォアグラウンド |
|------|----------------|
| zshがプロンプト待ち | zsh |
| fzf起動中 | fzf |
| 非同期プロンプトワーカー | バックグラウンド（フォアグラウンドグループに入らない） |

fzf等のインタラクティブプログラムは起動時に自分をフォアグラウンドプロセスグループに設定する。
これにより `pgrep` の親子関係チェックでは検出できなかったケースも確実に判定できる。

### `ps -o stat=,comm=`

`-o` はpsの出力カラムを指定するオプション。

| カラム指定 | 内容 | 例 |
|-----------|------|----|
| `stat=` | プロセスの状態（`=` でヘッダー非表示） | `S+`、`R+` |
| `comm=` | 実行ファイル名（`=` でヘッダー非表示） | `zsh`、`fzf` |

`stat` の末尾の `+` はフォアグラウンドプロセスグループに属することを示す。

### awkの条件式

```awk
$1 ~ /\+/ && $2 !~ /^-?(zsh|bash|sh)$/ {print $2}
```

| 条件 | 意味 |
|------|------|
| `$1 ~ /\+/` | statに `+` を含む（フォアグラウンド）行のみ抽出 |
| `$2 !~ /^-?(zsh|bash|sh)$/` | コマンド名がシェルでないもの（`-zsh` 等ログインシェルも除外） |

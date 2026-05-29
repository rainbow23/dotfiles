# nvim/init.lua 内部実装メモ

`init.lua` の中で直感的にわかりにくい実装パターンをまとめたドキュメント。

---

## 1. git root の取得と安全チェック

```lua
local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
local gr_norm  = (git_root ~= '' and not git_root:find('fatal'))
  and vim.fn.fnamemodify(git_root, ':p'):gsub('[/\\]$', ''):gsub('\\', '/') or nil
```

### なぜ `find('fatal')` が必要か

`git rev-parse --show-toplevel` は git リポジトリ外で実行すると終了コード 128 で
`fatal: not a git repository` という文字列を stdout/stderr に出力する。
`2>/dev/null` で stderr は捨てているが、環境によっては stdout に出ることもある。
`git_root ~= ''` だけでは "fatal: ..." という文字列が入ったまま通過してしまうため、
`not git_root:find('fatal')` で二重に弾いている。

**結果**: `gr_norm` は git リポジトリ内なら正規化済みパス文字列、それ以外なら `nil`。

---

## 2. パス正規化パターン

```lua
vim.fn.fnamemodify(path, ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
```

3ステップで構成されている。

| ステップ | 処理 | 理由 |
|---|---|---|
| `fnamemodify(':p')` | 絶対パスに変換し末尾に `/` を付与 | `~/dotfiles` → `/Users/rainbow/dotfiles/` |
| `:gsub('[/\\]$', '')` | 末尾スラッシュを除去 | `find()` による前方一致を安定させる |
| `:gsub('\\', '/')` | バックスラッシュをスラッシュに統一 | GitBash/Windows では `\` が混在するため |

### GitBash でのパス形式の差異

GitBash 環境では同じディレクトリが以下のように異なる形式で表れる。

| 取得方法 | 形式の例 |
|---|---|
| `git rev-parse --show-toplevel` | `/c/Users/rainbow/dotfiles` |
| `vim.fn.expand('%:p:h')` | `C:/Users/rainbow/dotfiles` |

そのままでは文字列比較が失敗するため、`fnamemodify(':p')` を通すことで
両者を同じ形式（`C:/Users/rainbow/dotfiles/`）に揃えてから比較している。

---

## 3. セッションファイルの `cd` 行によるフィルタリング

```lua
for line in fh:lines() do
  local dir = line:match('^cd%s+(.+)$')
  if dir then
    local sr = vim.fn.fnamemodify(vim.fn.expand(dir), ':p'):gsub('[/\\]$', ''):gsub('\\', '/')
    if sr == gr_norm then include = true end
    break
  end
end
```

Vim の `mksession` が生成するセッションファイルには必ず以下のような行が含まれる。

```vim
cd ~/dotfiles
```

この行がセッション保存時の作業ディレクトリ（= プロジェクトルート）を示す。
先頭から順に読んで最初の `cd` 行だけを見ればよいので `break` で打ち切っている。
`vim.fn.expand(dir)` は `~` などの Vim 特殊文字を展開する。

---

## 4. GrepSearch のスコアリング関数

```lua
return (1000 - file_order[fn]) * 100000 + (100000 - (entry.lnum or 0))
```

Telescope のソーターは**スコアが高いほど上に表示**される。
この式はファイル順 → 行番号順の二段階優先度を一つの数値で表現している。

```
スコア = (ファイル優先度) × 重み + (行番号優先度)
       = (1000 - file_rank) × 100000 + (100000 - lnum)
```

| 定数 | 意味 |
|---|---|
| `1000` | ファイル数の上限想定値。`file_rank` は 1 始まりの連番なので、`1000 - rank` で「順位が小さいほど高い値」に変換する |
| `100000`（乗数） | ファイル間優先度の重み。ファイル順位差の最小値（1）× 100000 が行番号スコアの最大値（100000）を常に上回るため、ファイル順が必ず行番号より優先される |
| `100000`（行番号） | 行番号の上限想定値。`100000 - lnum` で小さい行番号ほど高スコアになる |

---

## 5. `vim.schedule` の使い所

```lua
actions.close(prompt_bufnr)
vim.schedule(function()
  vim.fn.input('Rename session: ', old_name)
  telescope_session_picker()
end)
```

`actions.close` は Telescope のピッカーを閉じるが、その処理は非同期で完了する。
`vim.schedule` を挟まずに直後で `vim.fn.input()` や新しいピッカーを開こうとすると、
前のピッカーがまだ描画中の状態と衝突してエラーや表示崩れが起きる。
`vim.schedule` は「現在のイベントループが完了した後に実行」を保証するため、
ピッカーの後処理が終わってから次の UI 操作を始めることができる。

---

## 6. `finders.new_job` vs `finders.new_table`

| 関数 | 動作 | 使用箇所 |
|---|---|---|
| `finders.new_table` | 事前に全件リストを渡す | BLines・セッション一覧（件数が少ない・静的） |
| `finders.new_job` | 入力のたびに外部コマンドを起動して結果をストリーム取得 | GrepSearch（ripgrep をリアルタイム実行） |
| `finders.new_oneshot_job` | 起動は一度だけ、結果を全件受け取ってから表示 | FileSearch（rg --files で全ファイルを一括取得） |
